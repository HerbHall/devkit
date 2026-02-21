---
name: go-web
version: 1.0
description: Go web server and API development (extends go-cli with HTTP/gRPC tooling)
requires:
  - go-cli
winget: []
manual:
  - id: buf
    check: buf
    install: go install github.com/bufbuild/buf/cmd/buf@latest
    note: Protobuf/gRPC toolchain
  - id: grpc-health-probe
    check: grpc-health-probe
    install: go install github.com/grpc-ecosystem/grpc-health-probe@latest
vscode-extensions:
  - zxh404.vscode-proto3
  - humao.rest-client
claude-skills:
  - go-development
  - webapp-testing
  - security-review
---

# Go Web Profile

Use this profile for Go web servers, REST APIs, and gRPC services. This profile extends **go-cli** with HTTP and protocol buffer tooling.

## When to Use This

- REST APIs and HTTP services
- gRPC microservices
- Web servers with request handlers
- Anything with `http.Handler` or protocol buffers

If your project is a standalone CLI tool with no network endpoints, use **go-cli** instead.

## Prerequisites

This profile requires **go-cli** to be installed first. The go-cli profile includes the Go toolchain and linters.

## Protobuf and gRPC Workflow

### buf: Protocol Buffer Toolchain

`buf` is the modern replacement for raw `protoc`. It handles code generation, linting, and breaking change detection.

#### Configuration

Create `buf.yaml` at the project root:

```yaml
version: v1
build:
  roots:
    - proto
lint:
  use:
    - DEFAULT
breaking:
  use:
    - FILE
```

#### Common Commands

```bash
# Generate Go code from .proto files
buf generate

# Lint .proto files for style issues
buf lint

# Check for breaking changes compared to main branch
buf breaking --against "https://github.com/owner/repo.git#branch=main"

# Format all .proto files
buf format -w
```

#### Generated Code Location

By convention, generated files go into `pkg/api/` or a similar package directory:

```text
proto/
├── example.proto
└── buf.yaml

pkg/api/
├── example.pb.go
└── example_grpc.pb.go
```

### gRPC Health Check Pattern

For gRPC services, implement the health check protocol so clients can verify service readiness:

```go
import "google.golang.org/grpc/health"

healthCheck := health.NewServer()
grpc.RegisterService(&grpc.ServiceDesc{ServiceName: "example.Example"}, &exampleServer{})
healthpb.RegisterHealthServer(grpcServer, healthCheck)

// Mark service as SERVING when ready
healthCheck.SetServingStatus("example.Example", healthpb.HealthCheckResponse_SERVING)
```

Test with `grpc-health-probe`:

```bash
grpc-health-probe -addr=localhost:50051 -service=example.Example
```

## REST API Development

### Swagger/OpenAPI Documentation

The **go-cli** profile includes `swag` for generating OpenAPI specs from handler comments:

```bash
swag init -g cmd/myserver/main.go -o api/swagger --parseDependency --parseInternal
```

Annotate handlers with swagger comments:

```go
// GetUser retrieves a user by ID.
//
// @Summary Get user
// @Description Get a user by their ID
// @ID get-user
// @Produce json
// @Param id path int true "User ID"
// @Success 200 {object} User
// @Router /users/{id} [get]
func GetUser(w http.ResponseWriter, r *http.Request) {
    // implementation
}
```

See known-gotchas.md sections 15-17 for swagger drift issues and platform-specific gotchas.

### REST Client Testing

Use VS Code's **REST Client** extension (`humao.rest-client`) to test APIs without external tools:

Create `.http` or `.rest` files in your project:

```http
@base = http://localhost:8080
@token = your-token-here

### Get a user
GET {{base}}/api/v1/users/123
Authorization: Bearer {{token}}

### Create a user
POST {{base}}/api/v1/users
Content-Type: application/json

{
  "name": "Alice",
  "email": "alice@example.com"
}
```

Click the "Send Request" link above each request to execute it. The response appears in a side panel.

## HTTP Handler Best Practices

### Middleware Pattern

Use a middleware wrapper for cross-cutting concerns (logging, auth, CORS):

```go
func withLogging(next http.HandlerFunc) http.HandlerFunc {
    return func(w http.ResponseWriter, r *http.Request) {
        log.Info("request", "method", r.Method, "path", r.URL.Path)
        next(w, r)
    }
}

// Register with middleware
mux.HandleFunc("/api/users", withLogging(getUsers))
```

### Request/Response JSON Encoding

Always validate and encode safely:

```go
var req CreateUserRequest
if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
    http.Error(w, "invalid request", http.StatusBadRequest)
    return
}

// Write response
w.Header().Set("Content-Type", "application/json")
json.NewEncoder(w).Encode(resp)
```

### Error Handling

Return HTTP status codes that reflect the error condition:

```go
if err := validate(req); err != nil {
    http.Error(w, err.Error(), http.StatusBadRequest) // 400
    return
}

if errors.Is(err, ErrNotFound) {
    http.Error(w, "not found", http.StatusNotFound)   // 404
    return
}

http.Error(w, "internal error", http.StatusInternalServerError) // 500
```

## VS Code Extensions

- **golang.go** (from go-cli) — language server, debugging
- **zxh404.vscode-proto3** — syntax highlighting and linting for .proto files
- **humao.rest-client** — test REST APIs directly in VS Code with .http files

## Testing HTTP Handlers

Use the standard `net/http/httptest` package:

```go
func TestGetUser(t *testing.T) {
    req := httptest.NewRequest("GET", "/users/123", nil)
    w := httptest.NewRecorder()

    GetUser(w, req)

    if w.Code != http.StatusOK {
        t.Errorf("expected 200, got %d", w.Code)
    }
}
```

## Docker Deployment

Common Dockerfile pattern for Go web services:

```dockerfile
FROM golang:1.22 as builder
WORKDIR /app
COPY go.mod go.sum ./
RUN go mod download
COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o app ./cmd/server

FROM alpine:latest
RUN apk --no-cache add ca-certificates
COPY --from=builder /app/app /app
EXPOSE 8080
CMD ["/app"]
```

## Related Profiles

- **go-cli** — for standalone CLI tools without HTTP handlers (required dependency)
