package mutations

import (
	"context"
	"fmt"
	"net/http"
	"strconv"

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

// FIXME: Authorisation with discord to get the appropriate user.
func createPost(w http.ResponseWriter, r *http.Request) {
	form := r.MultipartForm.Value
	post := map[string]any{
		"uuid": uuid.NewString(),
	}
	if title, ok := form["title"]; ok && len(title) > 0 {
		post["title"] = title[0]
	} else {
		http.Error(w, "Missing title field", http.StatusBadRequest)
		return
	}

	if timestamp_raw, ok := form["timestamp"]; ok && len(timestamp_raw) > 0 {
		if timestamp, err := strconv.Atoi(timestamp_raw[0]); err != nil {
			post["timestamp"] = timestamp
		} else {
			http.Error(w, err.Error(), http.StatusBadRequest)
			return
		}
	}

	if location, ok := form["location"]; ok && len(location) > 0 {
		post["location"] = location[0]
	}

	ref, _, err := db.Collection("guilds").Doc("test").Collection("posts").Add(r.Context(), post)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	fmt.Fprintf(w, "created %s\n", ref.ID)
}
