package main

import (
	"log"
	"net/http"
	"os/exec"
	"time"
)

// Runs 'git pull' every hour, blocking.
func update_repo() {
	for {
		_, err := exec.Command("git", "pull").Output()
		if err != nil {
			log.Printf("%s", err)
		}
		time.Sleep(1 * time.Hour)
	}
}

func main() {

	// In a separate goroutine, run 'update_repo'
	go update_repo()

	port := "8100"
	directory := "."

	http.Handle("/", http.FileServer(http.Dir(*&directory)))

	log.Printf("Serving %s on port: %s\n", *&directory, *&port)
	log.Fatal(http.ListenAndServe(":"+*&port, nil))
}
