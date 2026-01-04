// REST API Server for User Management
// Demonstrates Go structs, interfaces, methods, goroutines, and HTTP handling

package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"sync"
	"time"
	"strconv"
	"strings"
	"context"
)

// User represents a user in the system
type User struct {
	ID        int       `json:"id"`
	Username  string    `json:"username"`
	Email     string    `json:"email"`
	FirstName string    `json:"first_name"`
	LastName  string    `json:"last_name"`
	CreatedAt time.Time `json:"created_at"`
	UpdatedAt time.Time `json:"updated_at"`
	IsActive  bool      `json:"is_active"`
	Roles     []string  `json:"roles"`
}

// UserService interface for user operations
type UserService interface {
	CreateUser(user *User) (*User, error)
	GetUser(id int) (*User, error)
	UpdateUser(id int, user *User) (*User, error)
	DeleteUser(id int) error
	ListUsers(page, limit int) ([]*User, error)
	SearchUsers(query string) ([]*User, error)
}

// InMemoryUserService implements UserService using in-memory storage
type InMemoryUserService struct {
	users  map[int]*User
	nextID int
	mu     sync.RWMutex
}

// NewInMemoryUserService creates a new in-memory user service
func NewInMemoryUserService() *InMemoryUserService {
	return &InMemoryUserService{
		users:  make(map[int]*User),
		nextID: 1,
	}
}

// CreateUser adds a new user to the service
func (s *InMemoryUserService) CreateUser(user *User) (*User, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Validate user data
	if err := s.validateUser(user); err != nil {
		return nil, err
	}

	// Check for duplicate email
	for _, u := range s.users {
		if strings.ToLower(u.Email) == strings.ToLower(user.Email) {
			return nil, fmt.Errorf("email already exists: %s", user.Email)
		}
		if strings.ToLower(u.Username) == strings.ToLower(user.Username) {
			return nil, fmt.Errorf("username already exists: %s", user.Username)
		}
	}

	// Set ID and timestamps
	user.ID = s.nextID
	s.nextID++
	user.CreatedAt = time.Now()
	user.UpdatedAt = time.Now()
	user.IsActive = true

	s.users[user.ID] = user
	return user, nil
}

// GetUser retrieves a user by ID
func (s *InMemoryUserService) GetUser(id int) (*User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	user, exists := s.users[id]
	if !exists {
		return nil, fmt.Errorf("user not found: %d", id)
	}

	return user, nil
}

// UpdateUser updates an existing user
func (s *InMemoryUserService) UpdateUser(id int, user *User) (*User, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	existingUser, exists := s.users[id]
	if !exists {
		return nil, fmt.Errorf("user not found: %d", id)
	}

	// Validate user data
	if err := s.validateUser(user); err != nil {
		return nil, err
	}

	// Update user data
	existingUser.Username = user.Username
	existingUser.Email = user.Email
	existingUser.FirstName = user.FirstName
	existingUser.LastName = user.LastName
	existingUser.Roles = user.Roles
	existingUser.IsActive = user.IsActive
	existingUser.UpdatedAt = time.Now()

	return existingUser, nil
}

// DeleteUser removes a user from the service
func (s *InMemoryUserService) DeleteUser(id int) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.users[id]; !exists {
		return fmt.Errorf("user not found: %d", id)
	}

	delete(s.users, id)
	return nil
}

// ListUsers retrieves users with pagination
func (s *InMemoryUserService) ListUsers(page, limit int) ([]*User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	allUsers := make([]*User, 0, len(s.users))
	for _, user := range s.users {
		allUsers = append(allUsers, user)
	}

	// Sort by ID
	for i := 0; i < len(allUsers); i++ {
		for j := i + 1; j < len(allUsers); j++ {
			if allUsers[i].ID > allUsers[j].ID {
				allUsers[i], allUsers[j] = allUsers[j], allUsers[i]
			}
		}
	}

	// Calculate pagination
	start := page * limit
	if start >= len(allUsers) {
		return []*User{}, nil
	}

	end := start + limit
	if end > len(allUsers) {
		end = len(allUsers)
	}

	return allUsers[start:end], nil
}

// SearchUsers searches for users by username or email
func (s *InMemoryUserService) SearchUsers(query string) ([]*User, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	query = strings.ToLower(query)
	var results []*User

	for _, user := range s.users {
		if strings.Contains(strings.ToLower(user.Username), query) ||
		   strings.Contains(strings.ToLower(user.Email), query) ||
		   strings.Contains(strings.ToLower(user.FirstName), query) ||
		   strings.Contains(strings.ToLower(user.LastName), query) {
			results = append(results, user)
		}
	}

	return results, nil
}

// validateUser validates user data
func (s *InMemoryUserService) validateUser(user *User) error {
	if strings.TrimSpace(user.Username) == "" {
		return fmt.Errorf("username is required")
	}

	if strings.TrimSpace(user.Email) == "" {
		return fmt.Errorf("email is required")
	}

	if strings.TrimSpace(user.FirstName) == "" {
		return fmt.Errorf("first name is required")
	}

	if strings.TrimSpace(user.LastName) == "" {
		return fmt.Errorf("last name is required")
	}

	return nil
}

// HTTPHandler handles HTTP requests
type HTTPHandler struct {
	userService UserService
}

// NewHTTPHandler creates a new HTTP handler
func NewHTTPHandler(userService UserService) *HTTPHandler {
	return &HTTPHandler{userService: userService}
}

// HTTPResponse represents a standard HTTP response
type HTTPResponse struct {
	Success bool        `json:"success"`
	Data    interface{} `json:"data,omitempty"`
	Message string      `json:"message,omitempty"`
	Error   string      `json:"error,omitempty"`
}

// CreateUserHandler handles POST /users
func (h *HTTPHandler) CreateUserHandler(w http.ResponseWriter, r *http.Request) {
	var user User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		h.sendErrorResponse(w, http.StatusBadRequest, "Invalid JSON data")
		return
	}

	createdUser, err := h.userService.CreateUser(&user)
	if err != nil {
		h.sendErrorResponse(w, http.StatusBadRequest, err.Error())
		return
	}

	h.sendSuccessResponse(w, http.StatusCreated, createdUser, "User created successfully")
}

// GetUserHandler handles GET /users/{id}
func (h *HTTPHandler) GetUserHandler(w http.ResponseWriter, r *http.Request) {
	// Extract user ID from URL path
	path := r.URL.Path
	parts := strings.Split(path, "/")
	if len(parts) < 3 {
		h.sendErrorResponse(w, http.StatusBadRequest, "Invalid URL path")
		return
	}

	userID, err := strconv.Atoi(parts[2])
	if err != nil {
		h.sendErrorResponse(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	user, err := h.userService.GetUser(userID)
	if err != nil {
		h.sendErrorResponse(w, http.StatusNotFound, err.Error())
		return
	}

	h.sendSuccessResponse(w, http.StatusOK, user, "User retrieved successfully")
}

// UpdateUserHandler handles PUT /users/{id}
func (h *HTTPHandler) UpdateUserHandler(w http.ResponseWriter, r *http.Request) {
	// Extract user ID from URL path
	path := r.URL.Path
	parts := strings.Split(path, "/")
	if len(parts) < 3 {
		h.sendErrorResponse(w, http.StatusBadRequest, "Invalid URL path")
		return
	}

	userID, err := strconv.Atoi(parts[2])
	if err != nil {
		h.sendErrorResponse(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	var user User
	if err := json.NewDecoder(r.Body).Decode(&user); err != nil {
		h.sendErrorResponse(w, http.StatusBadRequest, "Invalid JSON data")
		return
	}

	updatedUser, err := h.userService.UpdateUser(userID, &user)
	if err != nil {
		h.sendErrorResponse(w, http.StatusBadRequest, err.Error())
		return
	}

	h.sendSuccessResponse(w, http.StatusOK, updatedUser, "User updated successfully")
}

// DeleteUserHandler handles DELETE /users/{id}
func (h *HTTPHandler) DeleteUserHandler(w http.ResponseWriter, r *http.Request) {
	// Extract user ID from URL path
	path := r.URL.Path
	parts := strings.Split(path, "/")
	if len(parts) < 3 {
		h.sendErrorResponse(w, http.StatusBadRequest, "Invalid URL path")
		return
	}

	userID, err := strconv.Atoi(parts[2])
	if err != nil {
		h.sendErrorResponse(w, http.StatusBadRequest, "Invalid user ID")
		return
	}

	err = h.userService.DeleteUser(userID)
	if err != nil {
		h.sendErrorResponse(w, http.StatusNotFound, err.Error())
		return
	}

	h.sendSuccessResponse(w, http.StatusOK, nil, "User deleted successfully")
}

// ListUsersHandler handles GET /users
func (h *HTTPHandler) ListUsersHandler(w http.ResponseWriter, r *http.Request) {
	// Parse query parameters
	page := 1
	limit := 10

	if pageStr := r.URL.Query().Get("page"); pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}

	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil && l > 0 && l <= 100 {
			limit = l
		}
	}

	users, err := h.userService.ListUsers(page-1, limit) // Convert to 0-based indexing
	if err != nil {
		h.sendErrorResponse(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.sendSuccessResponse(w, http.StatusOK, users, "Users retrieved successfully")
}

// SearchUsersHandler handles GET /users/search
func (h *HTTPHandler) SearchUsersHandler(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query().Get("q")
	if strings.TrimSpace(query) == "" {
		h.sendErrorResponse(w, http.StatusBadRequest, "Search query is required")
		return
	}

	users, err := h.userService.SearchUsers(query)
	if err != nil {
		h.sendErrorResponse(w, http.StatusInternalServerError, err.Error())
		return
	}

	h.sendSuccessResponse(w, http.StatusOK, users, "Search completed successfully")
}

// HealthCheckHandler handles GET /health
func (h *HTTPHandler) HealthCheckHandler(w http.ResponseWriter, r *http.Request) {
	response := map[string]interface{}{
		"status":    "healthy",
		"timestamp": time.Now().Unix(),
		"service":   "user-management-api",
		"version":   "1.0.0",
	}

	h.sendSuccessResponse(w, http.StatusOK, response, "Service is healthy")
}

// Helper methods for sending responses
func (h *HTTPHandler) sendSuccessResponse(w http.ResponseWriter, statusCode int, data interface{}, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	response := HTTPResponse{
		Success: true,
		Data:    data,
		Message: message,
	}

	json.NewEncoder(w).Encode(response)
}

func (h *HTTPHandler) sendErrorResponse(w http.ResponseWriter, statusCode int, errorMsg string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(statusCode)

	response := HTTPResponse{
		Success: false,
		Error:   errorMsg,
	}

	json.NewEncoder(w).Encode(response)
}

// Middleware for logging requests
func loggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		
		// Log request
		log.Printf("Request: %s %s from %s", r.Method, r.URL.Path, r.RemoteAddr)
		
		// Call next handler
		next.ServeHTTP(w, r)
		
		// Log response time
		duration := time.Since(start)
		log.Printf("Response: %s %s completed in %v", r.Method, r.URL.Path, duration)
	})
}

// Middleware for CORS headers
func corsMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Access-Control-Allow-Origin", "*")
		w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
		w.Header().Set("Access-Control-Allow-Headers", "Content-Type, Authorization")
		
		if r.Method == "OPTIONS" {
			w.WriteHeader(http.StatusOK)
			return
		}
		
		next.ServeHTTP(w, r)
	})
}

// Server represents the HTTP server
type Server struct {
	httpServer *http.Server
	userService UserService
	handler     *HTTPHandler
}

// NewServer creates a new server instance
func NewServer(userService UserService) *Server {
	handler := NewHTTPHandler(userService)
	
	mux := http.NewServeMux()
	
	// Register routes
	mux.HandleFunc("/users", handler.CreateUserHandler)
	mux.HandleFunc("/users/", handler.GetUserHandler)
	mux.HandleFunc("/users/", handler.UpdateUserHandler)
	mux.HandleFunc("/users/", handler.DeleteUserHandler)
	mux.HandleFunc("/users/search", handler.SearchUsersHandler)
	mux.HandleFunc("/health", handler.HealthCheckHandler)
	
	// Wrap with middleware
	wrappedMux := loggingMiddleware(corsMiddleware(mux))
	
	return &Server{
		httpServer: &http.Server{
			Addr:         ":8080",
			Handler:      wrappedMux,
			ReadTimeout:  15 * time.Second,
			WriteTimeout: 15 * time.Second,
			IdleTimeout:  60 * time.Second,
		},
		userService: userService,
		handler:     handler,
	}
}

// Start starts the server
func (s *Server) Start() error {
	log.Println("Starting User Management API Server on :8080")
	return s.httpServer.ListenAndServe()
}

// Shutdown gracefully shuts down the server
func (s *Server) Shutdown(ctx context.Context) error {
	log.Println("Shutting down server...")
	return s.httpServer.Shutdown(ctx)
}

// Background task for cleanup
func (s *Server) startCleanupTask() {
	ticker := time.NewTicker(1 * time.Hour)
	go func() {
		for range ticker.C {
			log.Println("Running cleanup task...")
			// Perform any necessary cleanup here
		}
	}()
}

// Demo function to populate some test data
func populateTestData(userService UserService) {
	users := []*User{
		{
			Username:  "johndoe",
			Email:     "john@example.com",
			FirstName: "John",
			LastName:  "Doe",
			Roles:     []string{"user"},
		},
		{
			Username:  "janesmith",
			Email:     "jane@example.com",
			FirstName: "Jane",
			LastName:  "Smith",
			Roles:     []string{"user", "admin"},
		},
		{
			Username:  "bobwilson",
			Email:     "bob@example.com",
			FirstName: "Bob",
			LastName:  "Wilson",
			Roles:     []string{"user"},
		},
	}

	for _, user := range users {
		_, err := userService.CreateUser(user)
		if err != nil {
			log.Printf("Error creating test user %s: %v", user.Username, err)
		} else {
			log.Printf("Created test user: %s", user.Username)
		}
	}
}

// Main function
func main() {
	log.Println("Starting User Management API...")

	// Create user service
	userService := NewInMemoryUserService()

	// Populate test data
	populateTestData(userService)

	// Create and start server
	server := NewServer(userService)
	server.startCleanupTask()

	// Handle graceful shutdown
	go func() {
		log.Println("Server is ready to accept connections")
		if err := server.Start(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Server failed to start: %v", err)
		}
	}()

	// Wait for interrupt signal for graceful shutdown
	<-make(chan struct{})
}