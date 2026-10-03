package main

import (
	"fmt"
	"log"
	"os"
	"os/signal"
	"time"

	"encoding/json"
	"io"
	"net/http"
	"strings"

	"github.com/bwmarrin/discordgo"
	"google.golang.org/api/option"

	"cloud.google.com/go/firestore"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"

	"context"
	"regexp"

	"github.com/google/uuid"
)

var dateRegex = regexp.MustCompile(`(?i)\b(?:` +
	// Relative dates
	`today|tomorrow|yesterday` +
	`|` +
	`(?:this|next|last)\s+` +
	`(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)` +
	`|` +
	// Weekdays
	`(?:monday|tuesday|wednesday|thursday|friday|saturday|sunday)` +
	`|` +
	// Explicit dates
	`\d{4}[-/]\d{1,2}[-/]\d{1,2}` +
	`|` +
	`\d{1,2}[-/]\d{1,2}[-/]\d{4}` +
	`|` +
	`\d{1,2}(?:st|nd|rd|th)?\s+` +
	`(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*` +
	`(?:\s+\d{4})?` +
	`|` +
	`(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+` +
	`\d{1,2}(?:st|nd|rd|th)?(?:,?\s+\d{4})?` +
	`)\b`)

func extractDate(message string, now time.Time) (string, time.Time, bool) {
	match := dateRegex.FindString(message)
	if match == "" {
		return "", time.Time{}, false
	}

	match = strings.ToLower(strings.TrimSpace(match))

	fmt.Println(match)

	switch match {
	case "today":
		return match, now, true

	case "tomorrow":
		return match, now.AddDate(0, 0, 1), true

	case "yesterday":
		return match, now.AddDate(0, 0, -1), true
	}

	parts := strings.Fields(match)

	if len(parts) == 2 {
		var offset int
		switch parts[0] {
		case "next":
			offset = 1
		case "last":
			offset = -1
		case "this":
			offset = 0
		}

		if offset != 0 || parts[0] == "this" {
			weekday := parseWeekday(parts[1])
			if weekday >= 0 {
				return match, resolveWeekday(now, weekday, offset), true
			}
		}
	}

	// Plain weekday: choose the next occurrence.
	if weekday := parseWeekday(match); weekday >= 0 {
		return match, resolveWeekday(now, weekday, 0), true
	}

	// Add explicit date parsing here if required.
	return match, time.Time{}, true
}

func parseWeekday(s string) time.Weekday {
	switch strings.ToLower(s) {
	case "sunday":
		return time.Sunday
	case "monday":
		return time.Monday
	case "tuesday":
		return time.Tuesday
	case "wednesday":
		return time.Wednesday
	case "thursday":
		return time.Thursday
	case "friday":
		return time.Friday
	case "saturday":
		return time.Saturday
	default:
		return -1
	}
}

func resolveWeekday(now time.Time, target time.Weekday, modifier int) time.Time {
	current := now.Weekday()

	days := (int(target) - int(current) + 7) % 7

	switch modifier {
	case 1: // next
		if days == 0 {
			days = 7
		} else {
			days += 7
		}

	case -1: // last
		if days == 0 {
			days = 7
		}
		days -= 7

	case 0: // this / plain weekday
		// Keep the current week.
	}

	return now.AddDate(0, 0, days)
}

type JevMessage struct {
	Category string `json:"category"`
}

func jevCall(bearerToken string, message string) (JevMessage, error) {
	var jevMsg JevMessage

	msg := map[string]any{
		"message": message,
	}

	b, err := json.Marshal(msg)
	if err != nil {
		return jevMsg, err
	}

	// fmt.Println(string(b))
	req, err := http.NewRequest("POST", "https://classifydiscordmessage-jj62desesa-uc.a.run.app", strings.NewReader(string(b)))
	if err != nil {
		return jevMsg, err
	}

	req.Header.Set("Authorization", "Bearer "+bearerToken)
	req.Header.Set("Content-Type", "application/json")

	resp, err := http.DefaultClient.Do(req)

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return jevMsg, err
	}
	// fmt.Println(string(body))
	if err := json.Unmarshal(body, &jevMsg); err != nil {
		return jevMsg, err
	}

	return jevMsg, nil
}

func handleMessageSent(jevBearerToken string, db *firestore.Client, s *discordgo.Session, r *discordgo.MessageCreate) {
	// curl -X POST "https://classifydiscordmessage-jj62desesa-uc.a.run.app"   -H "Content-Type: application/json"   -d '{"message":"im down to go to the burger event!"}' -H "Authorization: Bearer bazinga"

	if r.Author.Bot {
		return
	}

	jevRes, err := jevCall(jevBearerToken, r.Content)

	if err != nil {
		log.Fatal(err.Error())
		return
	}

	fmt.Println(jevRes.Category)
	if jevRes.Category == "new_event" {
		var fields []*discordgo.MessageEmbedField
		post := map[string]any{
			"uuid":      uuid.NewString(),
			"createdAt": time.Now().Unix(),
			"author":    r.Author.ID,
			"title":     r.Content,
			"attending": []string{r.Author.ID},
		}

		_, t, found := extractDate(r.Content, time.Now())

		if found {
			fields = append(fields, &discordgo.MessageEmbedField{
				Name:  "time",
				Value: t.Format("2 Jan 2006"),
			})
			post["timestamp"] = t.Unix()
		}

		embed := &discordgo.MessageEmbed{
			Title:       "New Event",
			Description: r.Content,
			Fields:      fields,
			Color:       0xFF0000,
		}

		msg, err := s.ChannelMessageSendEmbed(r.ChannelID, embed)
		if err != nil {
			panic(err)
		}

		post["embed_message_id"] = msg.ID

		_, _, err = db.Collection("posts").Add(context.Background(), post)
		if err != nil {
			return
		}
	}
}

func init() {
	var err error
	db, err := firestore.NewClientWithDatabase(context.Background(), firestore.DetectProjectID, "studycrowd-db1")
	if err != nil {
		panic(err)
	}

	discordToken := os.Getenv("DISCORD_TOKEN")
	session, err := discordgo.New("Bot " + discordToken)

	if err != nil {
		fmt.Println(err.Error())
		return
	}

	jevToken := os.Getenv("CLIENT_AUTH_TOKEN")

	session.AddHandler(func(s *discordgo.Session, r *discordgo.Ready) {
		log.Printf("Logged in as %s", r.User.String())
	})

	session.AddHandler(func(s *discordgo.Session, r *discordgo.MessageCreate) {
		handleMessageSent(jevToken, db, s, r)
	})

	err = session.Open()
	if err != nil {
		log.Fatalf("could not open session: %s", err)
	}

	sigch := make(chan os.Signal, 1)
	signal.Notify(sigch, os.Interrupt)
	<-sigch

	err = session.Close()
	if err != nil {
		log.Printf("could not close session gracefully: %s", err)
	}

	functions.HTTP("health", health)

}

func health(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "up")
}
