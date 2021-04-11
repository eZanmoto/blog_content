// Copyright 2021 Sean Kelleher. All rights reserved.
// Use of this source code is governed by an MIT
// licence that can be found in the LICENCE file.

package main

import (
    "fmt"
    "net/http"
    "os"
    "os/exec"

    "github.com/gorilla/handlers"
    "github.com/gorilla/mux"
)

func main() {
	r := mux.NewRouter()

	r.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		out, err := exec.Command("fortune").Output()
		if err != nil {
			fmt.Println("couldn't generate fortune:", err)
			w.WriteHeader(http.StatusInternalServerError)
			return
		}
		w.Write(out)
	})

	loggedRouter := handlers.LoggingHandler(os.Stdout, r)
	http.ListenAndServe(":3000", loggedRouter)
}
