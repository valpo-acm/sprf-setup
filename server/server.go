package main

import (
	"fmt"
	"log"
	"net/http"
	"os/exec"
	"time"
)

func update_repo() {
	for {
		_, err := exec.Command("git pull").Output()
		if err != nil {
			fmt.Printf("%s", err)
		}
		time.Sleep(1 * time.Hour)
	}
}

func main() {

	go update_repo()

	port := "8100"
	directory := "."

	http.Handle("/", http.FileServer(http.Dir(*&directory)))

	log.Printf("Serving %s on port: %s\n", *&directory, *&port)
	log.Fatal(http.ListenAndServe(":"+*&port, nil))
}
