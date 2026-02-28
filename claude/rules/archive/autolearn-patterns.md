# Archived Autolearn Patterns

Deprecated and superseded entries from `../autolearn-patterns.md`.

## 27. golangci-lint bodyclose with websocket.Dial

**Added:** 2026-02-17 | **Source:** SubNetree | **Status:** superseded-by-KG17

**Category:** lint-fix
**Context:** The `coder/websocket` library's `websocket.Dial()` returns `(conn, *http.Response, error)`. The golangci-lint `bodyclose` linter requires that the `*http.Response` body is always closed, even in test code where the response is typically discarded with `_, _, err := websocket.Dial(...)`.
**Mistake:** First fix only addressing some call sites, or using `replace_all` blindly which creates variable name collisions with other uses of `_` in the same scope (e.g., a `conn.Read()` return variable also named `resp`).
**Fix:** For each `websocket.Dial` call, change to:

```go
conn, resp, err := websocket.Dial(ctx, wsURL, nil)
if resp != nil && resp.Body != nil {
    resp.Body.Close()
}
if err != nil {
    t.Fatalf("websocket dial: %v", err)
}
```

**Lesson:** When fixing a lint issue across multiple call sites, ALWAYS grep for ALL occurrences first before making partial fixes. Check for variable name collisions in the surrounding scope before using `replace_all`.
