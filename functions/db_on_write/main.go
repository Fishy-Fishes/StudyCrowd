package dbonwrite

import (
	"context"
	"log"

	"github.com/GoogleCloudPlatform/functions-framework-go/functions"
	"github.com/cloudevents/sdk-go/v2/event"
)

func init() {
	functions.CloudEvent("DbOnWrite", func(ctx context.Context, e event.Event) error {
		log.Printf("db_on_write ran: %s", e.Subject())
		return nil
	})
}
