package main

import (
	"context"
	"fmt"
	"log"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/bwmarrin/discordgo"
	"google.golang.org/api/iterator"
)

// Comments live under posts/{postId}/comments and flow both ways:
//   - Discord → app: a reply to an event embed, or a message in the embed's
//     thread, is saved as a comment (saveDiscordComment).
//   - App → Discord: a comment written in the app is posted into the embed's
//     thread, which is created on first use (watchAppComments).
//
// A comment's discord_message_id marks it as already being in Discord, so
// nothing is mirrored twice.

// saveDiscordComment stores r as a comment if it replies to an event embed or
// was sent in an event's thread. It reports whether r was a comment.
func saveDiscordComment(db *firestore.Client, s *discordgo.Session, r *discordgo.MessageCreate) bool {
	ctx := context.Background()
	var post *firestore.DocumentSnapshot
	switch {
	case r.MessageReference != nil:
		post = findEvent(ctx, db, r.MessageReference.MessageID)
	case isThread(s, r.ChannelID):
		post = findEventByThread(ctx, db, r.ChannelID)
	}
	if post == nil {
		return false
	}

	_, _, err := post.Ref.Collection("comments").Add(ctx, map[string]any{
		"author":             r.Author.ID,
		"author_name":        r.Author.DisplayName(),
		"author_avatar":      r.Author.AvatarURL("128"),
		"text":               r.Content,
		"createdAt":          time.Now().Unix(),
		"discord_message_id": r.ID,
	})
	if err != nil {
		log.Printf("failed to save comment on event %s: %v", post.Ref.ID, err)
	}
	return true
}

func isThread(s *discordgo.Session, channelID string) bool {
	ch, err := s.State.Channel(channelID)
	if err != nil {
		ch, err = s.Channel(channelID)
	}
	return err == nil && ch.IsThread()
}

func findEventByThread(ctx context.Context, db *firestore.Client, threadID string) *firestore.DocumentSnapshot {
	doc, err := db.Collection("posts").Where("thread_id", "==", threadID).Limit(1).Documents(ctx).Next()
	if err != nil && err != iterator.Done {
		log.Printf("failed to find event for thread %s: %v", threadID, err)
	}
	return doc
}

// watchAppComments posts comments written in the app into their event's thread.
func watchAppComments(db *firestore.Client, s *discordgo.Session) {
	snapshots := db.CollectionGroup("comments").Snapshots(context.Background())
	for {
		snap, err := snapshots.Next()
		if err != nil {
			log.Printf("stopped watching comments: %v", err)
			return
		}
		for _, change := range snap.Changes {
			if change.Kind == firestore.DocumentAdded {
				mirrorAppComment(db, s, change.Doc)
			}
		}
	}
}

func mirrorAppComment(db *firestore.Client, s *discordgo.Session, doc *firestore.DocumentSnapshot) {
	var comment struct {
		AuthorName       string `firestore:"author_name"`
		Text             string `firestore:"text"`
		DiscordMessageID string `firestore:"discord_message_id"`
	}
	if err := doc.DataTo(&comment); err != nil || comment.DiscordMessageID != "" {
		return // Already in Discord (or unreadable).
	}

	ctx := context.Background()
	postRef := doc.Ref.Parent.Parent
	postDoc, err := postRef.Get(ctx)
	if err != nil {
		log.Printf("failed to load event for comment %s: %v", doc.Ref.ID, err)
		return
	}
	var post struct {
		Title     string `firestore:"title"`
		ChannelID string `firestore:"channel_id"`
		MessageID string `firestore:"embed_message_id"`
		ThreadID  string `firestore:"thread_id"`
	}
	if err := postDoc.DataTo(&post); err != nil || post.ChannelID == "" {
		return // App-only post: there is no embed to thread under.
	}

	if post.ThreadID == "" {
		thread, err := s.MessageThreadStart(post.ChannelID, post.MessageID, threadName(post.Title), 1440)
		if err != nil {
			log.Printf("failed to start thread for event %s: %v", postRef.ID, err)
			return
		}
		post.ThreadID = thread.ID
		if _, err := postRef.Update(ctx, []firestore.Update{{Path: "thread_id", Value: thread.ID}}); err != nil {
			log.Printf("failed to save thread for event %s: %v", postRef.ID, err)
		}
	}

	msg, err := s.ChannelMessageSendComplex(post.ThreadID, &discordgo.MessageSend{
		Content:         fmt.Sprintf("**%s** (in the app): %s", comment.AuthorName, comment.Text),
		AllowedMentions: &discordgo.MessageAllowedMentions{}, // never ping from app text
	})
	if err != nil {
		log.Printf("failed to post comment %s to Discord: %v", doc.Ref.ID, err)
		return
	}
	if _, err := doc.Ref.Update(ctx, []firestore.Update{{Path: "discord_message_id", Value: msg.ID}}); err != nil {
		log.Printf("failed to mark comment %s as posted: %v", doc.Ref.ID, err)
	}
}

// threadName fits an event's text into Discord's 100-character thread name limit.
func threadName(title string) string {
	runes := []rune(title)
	if len(runes) > 90 {
		return string(runes[:90]) + "…"
	}
	return title
}
