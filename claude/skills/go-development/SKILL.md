---
name: go-development
description: Go development patterns, idioms, and conventions. Use when writing Go code, structuring Go modules, implementing error handling, writing tests, or building network and security tools in Go.
---

<objective>
Provides Go development expertise including idiomatic patterns, module organization, error handling, testing conventions, and patterns specific to network and security tooling.
</objective>

<idioms>

<idiom name="error_handling">
Go uses explicit error returns. Never ignore errors silently.

```go
// GOOD: Handle or propagate errors explicitly
result, err := doSomething()
if err != nil {
    return fmt.Errorf("doSomething failed: %w", err)
}

// GOOD: Sentinel errors for expected conditions
var ErrNotFound = errors.New("not found")

if errors.Is(err, ErrNotFound) {
    // handle expected case
}

// GOOD: Custom error types for rich context
type ScanError struct {
    Host string
    Port int
    Err  error
}

func (e *ScanError) Error() string {
    return fmt.Sprintf("scan %s:%d: %v", e.Host, e.Port, e.Err)
}

func (e *ScanError) Unwrap() error { return e.Err }
```

Key principles:

- Wrap errors with `fmt.Errorf("context: %w", err)` for stack context
- Use `errors.Is()` and `errors.As()` for error inspection
- Define sentinel errors at package level for expected conditions
- Use custom error types when callers need structured error data
</idiom>

<idiom name="naming">
- Exported names: `PascalCase` (e.g., `ScanResult`, `NewScanner`)
- Unexported names: `camelCase` (e.g., `scanHost`, `portRange`)
- Interfaces: name by behavior, often single-method with `-er` suffix (`Scanner`, `Reader`, `Resolver`)
- Acronyms: all caps (`HTTP`, `URL`, `IP`, `TCP`, `DNS`)
- Package names: short, lowercase, no underscores (e.g., `scan`, `resolve`, `report`)
- Avoid stutter: `scan.Scanner` not `scan.ScanScanner`
</idiom>

<idiom name="interfaces">
- Accept interfaces, return structs
- Keep interfaces small (1-3 methods preferred)
- Define interfaces where they are consumed, not where implemented

```go
// GOOD: Small, focused interface defined by consumer
type HostResolver interface {
    Resolve(hostname string) ([]net.IP, error)
}

// Consumer accepts the interface
func ScanHosts(resolver HostResolver, hosts []string) ([]Result, error) {
    // ...
}
```

</idiom>

<idiom name="zero_values">
Design types so the zero value is useful:

```go
// sync.Mutex zero value is unlocked - ready to use
var mu sync.Mutex

// bytes.Buffer zero value is empty buffer - ready to use
var buf bytes.Buffer
```

</idiom>

</idioms>

<module_structure>
Standard Go project layout for CLI tools:

```text
project/
├── cmd/
│   └── toolname/
│       └── main.go          # Entry point, flag parsing, minimal logic
├── internal/
│   ├── scan/                # Core scanning logic
│   │   ├── scanner.go
│   │   └── scanner_test.go
│   ├── report/              # Output formatting
│   │   ├── report.go
│   │   └── report_test.go
│   └── config/              # Configuration handling
│       └── config.go
├── go.mod
├── go.sum
├── Makefile
└── README.md
```

Key principles:

- `cmd/` contains minimal entry points that wire dependencies together
- `internal/` for packages private to this module
- `pkg/` only when explicitly designing a public API
- Keep `main.go` thin -- parse flags, create dependencies, call into `internal/`
- One package per logical concern
</module_structure>

<testing>

<pattern name="table_driven_tests">
<!-- markdownlint-disable MD040 MD046 -->
```go
func TestParsePort(t *testing.T) {
    tests := []struct {
        name    string
        input   string
        want    int
        wantErr bool
    }{
        {name: "valid port", input: "8080", want: 8080},
        {name: "min port", input: "1", want: 1},
        {name: "max port", input: "65535", want: 65535},
        {name: "zero port", input: "0", wantErr: true},
        {name: "negative port", input: "-1", wantErr: true},
        {name: "overflow", input: "65536", wantErr: true},
        {name: "non-numeric", input: "abc", wantErr: true},
        {name: "empty string", input: "", wantErr: true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := ParsePort(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("ParsePort(%q) error = %v, wantErr %v", tt.input, err, tt.wantErr)
                return
            }
            if got != tt.want {
                t.Errorf("ParsePort(%q) = %v, want %v", tt.input, got, tt.want)
            }
        })
    }
}

```
<!-- markdownlint-enable MD040 MD046 -->
</pattern>

<pattern name="benchmark_tests">
```go
func BenchmarkScanPort(b *testing.B) {
    scanner := NewScanner(DefaultConfig())
    target := "127.0.0.1"

    b.ResetTimer()
    for i := 0; i < b.N; i++ {
        _ = scanner.ScanPort(target, 80)
    }
}
```

Run benchmarks: `go test -bench=. -benchmem ./...`
</pattern>

<pattern name="test_helpers">
```go
// testutil.go in same package
func setupTestServer(t *testing.T) (addr string, cleanup func()) {
    t.Helper()
    ln, err := net.Listen("tcp", "127.0.0.1:0")
    if err != nil {
        t.Fatal(err)
    }
    return ln.Addr().String(), func() { ln.Close() }
}
```

- Use `t.Helper()` for cleaner error messages
- Use `t.Cleanup()` or return cleanup functions
- Use `t.Parallel()` for independent tests
- Use `testdata/` directory for test fixtures
</pattern>

<pattern name="mock_interfaces">
<!-- markdownlint-disable MD040 MD046 -->
```go
// Mock in test file
type mockResolver struct {
    resolveFunc func(string) ([]net.IP, error)
}

func (m *mockResolver) Resolve(host string) ([]net.IP, error) {
    return m.resolveFunc(host)
}

func TestScanWithResolver(t *testing.T) {
    mock := &mockResolver{
        resolveFunc: func(host string) ([]net.IP, error) {
            return []net.IP{net.ParseIP("127.0.0.1")}, nil
        },
    }
    // use mock in test
}

```
<!-- markdownlint-enable MD040 MD046 -->
</pattern>

</testing>

<network_security_patterns>
Patterns common in network scanning and security tools:

<pattern name="concurrent_scanning">
```go
func ScanPorts(host string, ports []int, workers int) []Result {
    results := make([]Result, 0, len(ports))
    var mu sync.Mutex
    var wg sync.WaitGroup
    sem := make(chan struct{}, workers)

    for _, port := range ports {
        wg.Add(1)
        sem <- struct{}{}
        go func(p int) {
            defer wg.Done()
            defer func() { <-sem }()

            result := scanPort(host, p)
            mu.Lock()
            results = append(results, result)
            mu.Unlock()
        }(port)
    }
    wg.Wait()
    return results
}
```

</pattern>

<pattern name="context_timeout">
<!-- markdownlint-disable MD040 MD046 -->
```go
func ScanWithTimeout(ctx context.Context, target string, timeout time.Duration) (Result, error) {
    ctx, cancel := context.WithTimeout(ctx, timeout)
    defer cancel()

    conn, err := (&net.Dialer{}).DialContext(ctx, "tcp", target)
    if err != nil {
        return Result{}, err
    }
    defer conn.Close()
    // ...
}

```
<!-- markdownlint-enable MD040 MD046 -->
</pattern>

<pattern name="input_validation">
```go
func ValidateTarget(target string) error {
    if ip := net.ParseIP(target); ip != nil {
        return nil // valid IP
    }
    if _, err := net.LookupHost(target); err != nil {
        return fmt.Errorf("invalid target %q: %w", target, err)
    }
    return nil
}

func ValidatePortRange(start, end int) error {
    if start < 1 || start > 65535 {
        return fmt.Errorf("invalid start port: %d", start)
    }
    if end < start || end > 65535 {
        return fmt.Errorf("invalid end port: %d", end)
    }
    return nil
}
```

</pattern>

</network_security_patterns>

<lint_pitfalls>
Common golangci-lint failures to avoid proactively:

- **commentedOutCode (gocritic)**: Comments resembling code trigger this. Arithmetic-like comments in tests (e.g., `// Weight(15) + Weight(35) = 50`) are flagged. Use natural language instead: `// Expected: OUI weight plus BRIDGE-MIB weight`.
- **prealloc**: Preallocate slices when loop length is known: `make([]T, 0, len(source))` not `var slice []T` with append in a loop.
- **rangeValCopy (gocritic)**: Structs over 64 bytes copied per iteration. Use `for i := range slice` and access via `slice[i]`. Replace ALL loop variable references in the body.
- **httpNoBody (gocritic)**: Use `http.NoBody` instead of `nil` for GET/HEAD/DELETE requests without a body.
- **builtinShadow (gocritic)**: Never use Go builtins as parameter names (`new`, `make`, `len`, `copy`, `min`, `max`, `clear`). Rename to `n`, `count`, `limit`, `val`, etc.
- **nilerr**: When a function receives a non-nil error and returns `nil` as the error (encoding it into a result struct), the linter flags it. Return both result and wrapped error.
- **bodyclose**: Always close HTTP response bodies, including from `websocket.Dial()` responses.
</lint_pitfalls>

<success_criteria>
Go code produced with this skill should:

- Pass `go vet ./...` with no warnings
- Pass `golangci-lint run` with standard linters
- Have test coverage for exported functions
- Use `context.Context` for cancellable operations
- Handle all errors explicitly
- Follow standard project layout conventions
</success_criteria>
