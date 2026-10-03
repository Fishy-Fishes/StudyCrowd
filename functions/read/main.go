package reads

import (
	"context"
	"encoding/json"
	"net/http"

	"cloud.google.com/go/firestore"
	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
)

var db *firestore.Client

func init() {
	var err error
	db, err = firestore.NewClient(context.Background(), firestore.DetectProjectID)
	if err != nil {
		panic(err)
	}
	functions.HTTP("GetPosts", getPosts)
}

func getPosts(w http.ResponseWriter, r *http.Request) {
	docs, err := db.Collection("guilds").Doc("test").Collection("posts").
		OrderBy("createdAt", firestore.Desc).Documents(r.Context()).GetAll()
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	posts := []map[string]any{}
	for _, d := range docs {
		p := d.Data()
		p["id"] = d.Ref.ID
		posts = append(posts, p)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(posts)
}
