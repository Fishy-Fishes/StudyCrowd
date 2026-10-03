package main

import (
	"strings"
	"testing"
	"time"

	"github.com/bwmarrin/discordgo"
)

func TestBuildEventEmbed(t *testing.T) {
	author := &discordgo.User{ID: "1", Username: "txt1"}
	e := buildEventEmbed(author, "anyone keen to study?\nin the library", time.Time{}, "ab12cd34")

	if e.Title != "" {
		t.Errorf("title should be empty, got %q", e.Title)
	}
	if e.Author.Name != "txt1 is hosting" {
		t.Errorf("author = %q", e.Author.Name)
	}
	if want := "> *anyone keen to study?*\n> *in the library*"; e.Description != want {
		t.Errorf("description = %q, want %q", e.Description, want)
	}
	if len(e.Fields) != 0 {
		t.Errorf("zero date should add no field, got %d", len(e.Fields))
	}
	if !strings.Contains(e.Footer.Text, "ab12cd34") || !strings.Contains(e.Footer.Text, "React "+attendEmoji+" to attend") {
		t.Errorf("footer = %q", e.Footer.Text)
	}
	if e.Image == nil || e.Image.URL != "attachment://banner.png" {
		t.Errorf("image = %+v", e.Image)
	}
}

func TestBuildEventEmbedWithDate(t *testing.T) {
	author := &discordgo.User{ID: "1", Username: "txt1"}
	when := time.Date(2026, 10, 8, 0, 0, 0, 0, time.UTC)
	e := buildEventEmbed(author, "study tomorrow", when, "x")

	if len(e.Fields) != 1 || e.Fields[0].Value != "Thu 8 Oct" {
		t.Errorf("fields = %+v", e.Fields)
	}
}
