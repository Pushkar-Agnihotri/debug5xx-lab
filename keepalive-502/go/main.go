package main

import (
	"net/http"
	"os"
	"time"
)

func main() {
	// How long an idle connection stays open. Go's default is 0, which means
	// "never close idle connections", so Go is safe unless you set this.
	idleTimeout, _ := time.ParseDuration(os.Getenv("IDLE_TIMEOUT"))

	server := &http.Server{
		Addr:        ":3000",
		IdleTimeout: idleTimeout,
		Handler: http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			w.Write([]byte("ok\n"))
		}),
	}
	server.ListenAndServe()
}
