package main

import (
	"context"
	"log"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/bwmarrin/discordgo"
	"google.golang.org/api/iterator"
)

// Comments live under posts/{postId}/comments, and every comment ends up in
// the thread on its event's embed:
//   - A message in the thread is saved as a comment (it is already there).
//   - A reply to the embed in the channel, or a comment written in the app, is
//     saved and then posted into the thread as an embed with the author and
//     text (watchComments). The thread is created on first use.
//
// A comment's discord_message_id is its message in the thread, so a comment
// that has one is never posted twice.

// saveDiscordComment stores r as a comment if it was sent in an event's thread
// or replies to an event embed. It reports whether r was a comment.
func saveDiscordComment(db *firestore.Client, s *discordgo.Session, r *discordgo.MessageCreate) bool {
	ctx := context.Background()
	comment := map[string]any{
		"author":        r.Author.ID,
		"author_name":   r.Author.DisplayName(),
		"author_avatar": r.Author.AvatarURL("128"),
		"text":          r.Content,
		"createdAt":     time.Now().Unix(),
	}
	var post *firestore.DocumentSnapshot
	if isThread(s, r.ChannelID) {
		post = findEventByThread(ctx, db, r.ChannelID)
		comment["discord_message_id"] = r.ID // already in the thread
	} else if r.MessageReference != nil {
		post = findEvent(ctx, db, r.MessageReference.MessageID) // copied to the thread by watchComments
	}
	if post == nil {
		return false
	}

	batch := db.Batch()
	batch.Create(post.Ref.Collection("comments").NewDoc(), comment)
	batch.Update(post.Ref, []firestore.Update{{Path: "comment_count", Value: firestore.Increment(1)}})
	if _, err := batch.Commit(ctx); err != nil {
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

func inGuild(s *discordgo.Session, channelID string) bool {
	ch, err := s.State.Channel(channelID)
	if err != nil {
		ch, err = s.Channel(channelID)
	}
	return err == nil && ch.GuildID != ""
}

func findEventByThread(ctx context.Context, db *firestore.Client, threadID string) *firestore.DocumentSnapshot {
	doc, err := db.Collection("posts").Where("thread_id", "==", threadID).Limit(1).Documents(ctx).Next()
	if err != nil && err != iterator.Done {
		log.Printf("failed to find event for thread %s: %v", threadID, err)
	}
	return doc
}

// watchComments posts each comment that isn't in its event's thread yet into it.
func watchComments(db *firestore.Client, s *discordgo.Session) {
	snapshots := db.CollectionGroup("comments").Snapshots(context.Background())
	for {
		snap, err := snapshots.Next()
		if err != nil {
			log.Printf("stopped watching comments: %v", err)
			return
		}
		for _, change := range snap.Changes {
			if change.Kind == firestore.DocumentAdded {
				postCommentToThread(db, s, change.Doc)
			}
		}
	}
}

func postCommentToThread(db *firestore.Client, s *discordgo.Session, doc *firestore.DocumentSnapshot) {
	var comment struct {
		AuthorName       string `firestore:"author_name"`
		AuthorAvatar     string `firestore:"author_avatar"`
		Text             string `firestore:"text"`
		DiscordMessageID string `firestore:"discord_message_id"`
	}
	if err := doc.DataTo(&comment); err != nil || comment.DiscordMessageID != "" {
		return // Already in the thread (or unreadable).
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
	if !inGuild(s, post.ChannelID) {
		return // DMs can't have threads; the comment stays in the app.
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

	msg, err := s.ChannelMessageSendEmbed(post.ThreadID, &discordgo.MessageEmbed{
		Author:      &discordgo.MessageEmbedAuthor{Name: comment.AuthorName, IconURL: comment.AuthorAvatar},
		Description: comment.Text,
		Color:       embedColor,
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
