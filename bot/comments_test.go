package main

import (
	"strings"
	"testing"
)

func TestThreadName(t *testing.T) {
	if got := threadName("study at 3"); got != "study at 3" {
		t.Errorf("short title changed: %q", got)
	}
	long := strings.Repeat("é", 150)
	if got := []rune(threadName(long)); len(got) > 100 {
		t.Errorf("thread name is %d runes, want at most 100", len(got))
	}
}
