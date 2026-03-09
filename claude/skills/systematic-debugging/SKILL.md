---
name: systematic-debugging
description: 4-phase systematic debugging methodology with root cause analysis and evidence-based verification. Use when debugging complex issues.
allowed-tools: Read, Glob, Grep
---

# Systematic Debugging

## Overview

This skill provides a structured approach to debugging that prevents random guessing and ensures problems are properly understood before solving.

## 4-Phase Debugging Process

### Phase 1: Reproduce

Before fixing, reliably reproduce the issue.

```markdown
## Reproduction Steps
1. [Exact step to reproduce]
2. [Next step]
3. [Expected vs actual result]

## Reproduction Rate
- [ ] Always (100%)
- [ ] Often (50-90%)
- [ ] Sometimes (10-50%)
- [ ] Rare (<10%)
```

### Phase 2: Isolate

Narrow down the source.

```markdown
## Isolation Questions
- When did this start happening?
- What changed recently?
- Does it happen in all environments?
- Can we reproduce with minimal code?
- What's the smallest change that triggers it?
```

### Phase 3: Understand

Find the root cause, not just symptoms.

```markdown
## Root Cause Analysis
### The 5 Whys
1. Why: [First observation]
2. Why: [Deeper reason]
3. Why: [Still deeper]
4. Why: [Getting closer]
5. Why: [Root cause]
```

### Phase 4: Fix & Verify

Fix and verify it's truly fixed.

```markdown
## Fix Verification
- [ ] Bug no longer reproduces
- [ ] Related functionality still works
- [ ] No new issues introduced
- [ ] Test added to prevent regression
```

## Debugging Checklist

```markdown
## Before Starting
- [ ] Can reproduce consistently
- [ ] Have minimal reproduction case
- [ ] Understand expected behavior

## During Investigation
- [ ] Check recent changes (git log)
- [ ] Check logs for errors
- [ ] Add logging if needed
- [ ] Use debugger/breakpoints

## After Fix
- [ ] Root cause documented
- [ ] Fix verified
- [ ] Regression test added
- [ ] Similar code checked
```

## Common Debugging Commands

```bash
# Recent changes
git log --oneline -20
git diff HEAD~5

# Search for pattern
grep -r "errorPattern" --include="*.go"

# Check logs
journalctl -u myservice -n 100 --no-pager
```

## Anti-Patterns

- **Random changes** — "Maybe if I change this..."
- **Ignoring evidence** — "That can't be the cause"
- **Assuming** — "It must be X" without proof
- **Not reproducing first** — Fixing blindly
- **Stopping at symptoms** — Not finding root cause

## Go: Goroutine Deadlock Analysis

When `go test` times out with a goroutine dump, use this structured approach.

### Step 1: Identify the lock holder

Find the goroutine that HOLDS the mutex (it won't say "Mutex.Lock" — it will be
blocked elsewhere while owning it):

```text
goroutine N [chan send]:          ← blocked on channel while holding mutex
goroutine N [chan receive]:       ← blocked waiting for data
goroutine N [sync.WaitGroup.Wait]:  ← waiting for workers to finish
```

### Step 2: Identify all waiters

Look for `[sync.Mutex.Lock]` goroutines — these are blocked trying to acquire the mutex.
Note which functions they're in and at what line numbers.

### Step 3: Struct field offset calculation

If goroutine dump line numbers don't match current source (stale binary suspect),
use the struct pointer and mutex address to verify which mutex is being contended:

```text
Pool at 0x...e480, mutex at 0x...e4e0
Offset = 0xe4e0 - 0xe480 = 0x60 = 96 bytes

Count field sizes from struct definition:
  registry   *T    = 8 bytes  (offset 0)
  tracker    iface = 16 bytes (offset 8)
  store      iface = 16 bytes (offset 24)
  costs      *T    = 8 bytes  (offset 40)
  workers    int   = 8 bytes  (offset 48)
  tasks      chan  = 8 bytes  (offset 56)
  wg    WaitGroup  = 12 bytes (offset 64, padded to 16 → offset 80... check alignment)
  ...
  mu    sync.Mutex = 8 bytes  (offset 96 = 0x60) ✓ MATCH
```

If the offset matches the current struct layout, the **struct is unchanged** but
line numbers differ — confirms a stale binary with code added/removed above the mutex.

### Step 4: Stale binary check

If line numbers don't match current source:

```bash
# Check when the file was last committed vs when the test binary was compiled
git log --format="%H %ai %s" -- internal/pkg/file.go

# If the file was committed AFTER the test was launched, binary is stale.
# Verify by running fresh:
go test -count=1 -timeout 30s ./internal/pkg/...
# If it passes → current code is already fixed, old binary had the bug.
```

### Step 5: Deadlock cycle checklist

```text
Classic pool deadlock cycle:
□ Submit() holds mu → blocked on buffered channel send (buffer full)
□ Workers need to drain channel → workers also need mu
□ Shutdown() needs mu → also blocked

Root cause: a field read by workers was protected by mu.
Fix: switch to atomic.Pointer / atomic.Value for worker-hot-path fields.
```
