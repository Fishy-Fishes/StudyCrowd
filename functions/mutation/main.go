package mutations

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"cloud.google.com/go/firestore"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/google/uuid"
)

var db *firestore.Client

func init() {
	var err error
	db, err = firestore.NewClientWithDatabase(context.Background(), firestore.DetectProjectID, "studycrowd-db1")
	if err != nil {
		panic(err)
	}
	functions.HTTP("CreatePost", createPost)
}

func createPost(w http.ResponseWriter, r *http.Request) {
	ref, _, err := db.Collection("guilds").Doc("test").Collection("posts").Add(r.Context(), map[string]any{
		"title":     uuid.NewString(),
		"createdAt": time.Now().Unix(),
	})
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	fmt.Fprintf(w, "created %s\n", ref.ID)
}
