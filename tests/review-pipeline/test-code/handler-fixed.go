package auth

import (
	"crypto/subtle"
	"database/sql"
	"encoding/json"
	"net/http"
)

type loginRequest struct {
	Username string `json:"username"`
	Password string `json:"password"`
}

// LoginHandler handles user login requests.
func LoginHandler(db *sql.DB) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "method not allowed", http.StatusMethodNotAllowed)
			return
		}

		var req loginRequest
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			http.Error(w, "invalid request body", http.StatusBadRequest)
			return
		}

		// Look up user by username using parameterized query
		var storedHash string
		err := db.QueryRowContext(r.Context(),
			"SELECT password_hash FROM users WHERE username = ?", req.Username,
		).Scan(&storedHash)
		if err != nil {
			// Generic message prevents user enumeration
			http.Error(w, "invalid credentials", http.StatusUnauthorized)
			return
		}

		// Constant-time comparison (placeholder for bcrypt.CompareHashAndPassword)
		if subtle.ConstantTimeCompare([]byte(req.Password), []byte(storedHash)) != 1 {
			http.Error(w, "invalid credentials", http.StatusUnauthorized)
			return
		}

		token := generateToken(req.Username)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"token": token})
	}
}

func generateToken(username string) string {
	// In production: use a proper JWT library with RS256 signing and expiry
	return "placeholder-jwt-for-" + username
}
