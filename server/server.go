package main

import (
	"log"
	"net/http"
)

func main() {
	port := "8100"
	directory := "."

	http.Handle("/", http.FileServer(http.Dir(*&directory)))

	log.Printf("Serving %s on port: %s\n", *&directory, *&port)
	log.Fatal(http.ListenAndServe(":"+*&port, nil))
}
