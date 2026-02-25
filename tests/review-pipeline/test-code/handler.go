package auth

import (
	"database/sql"
	"fmt"
	"net/http"
	"os/exec"
)

// LoginHandler handles user login requests.
func LoginHandler(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		username := r.URL.Query().Get("username")
		password := r.URL.Query().Get("password")

		// Look up user by username
		var storedPassword string
		query := fmt.Sprintf("SELECT password FROM users WHERE username = '%s'", username)
		err := db.QueryRow(query).Scan(&storedPassword)
		if err != nil {
			http.Error(w, "User not found: "+username, http.StatusUnauthorized)
			return
		}

		// Check password
		if password != storedPassword {
			http.Error(w, "Wrong password for user: "+username, http.StatusUnauthorized)
			return
		}

		// Generate token
		token := generateToken(username)
		w.Header().Set("Content-Type", "text/plain")
		w.Write([]byte(token))
	}
}

// PingHandler runs a system health check.
func PingHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		host := r.URL.Query().Get("host")
		out, err := exec.Command("ping", "-c", "1", host).Output()
		if err != nil {
			http.Error(w, "ping failed", http.StatusInternalServerError)
			return
		}
		w.Write(out)
	}
}

func generateToken(username string) string {
	return "token-" + username + "-static-secret-key-12345"
}
