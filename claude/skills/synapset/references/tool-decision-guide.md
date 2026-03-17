# Tool Decision Guide

Flowchart for choosing the right Synapset retrieval tool.

## Decision Tree

```text
START: "I need information from Synapset"
  │
  ├─ Do I know the exact pool, source, category, or tags?
  │   │
  │   ├─ YES → Use query_memory
  │   │   Examples:
  │   │   - "Get all machine specs for hdh-nzxt" → query_memory(pool="machines", source="hdh-nzxt")
  │   │   - "Find all PowerShell gotchas" → query_memory(pool="devkit", summary_contains="PowerShell")
  │   │   - "List completions for issue 577" → query_memory(pool="samverk", content_contains="#577")
  │   │   - "Show all GPU-tagged entries" → query_memory(pool="machines", tags="hardware,gpu")
  │   │
  │   └─ NO → Do I know which pool to search?
  │       │
  │       ├─ YES → Use search_memory
  │       │   Examples:
  │       │   - "How did we fix the dispatcher timeout?" → search_memory(pool="samverk", query="dispatcher timeout fix")
  │       │   - "What Go lint issues have we hit?" → search_memory(pool="devkit", query="golangci-lint failure")
  │       │
  │       └─ NO → Use search_all
  │           Examples:
  │           - "What do we know about Tailscale networking?" → search_all(query="Tailscale network configuration")
  │           - "Any prior work on Ollama setup?" → search_all(query="Ollama GPU inference setup")
  │
  └─ Am I storing, not retrieving?
      │
      ├─ Single new memory → store_memory (with pool, source, category, tags, summary)
      ├─ Updating existing → update_memory (with id, changed fields)
      ├─ Bulk import → import_memories (JSON array, shared source)
      └─ Removing stale data → delete_memory (by id, soft delete)
```

## Common Mistakes

### Mistake: Using search_memory for structured lookups

**Wrong:**

```text
search_memory(pool="machines", query="HDH-NZXT GPU specs")
→ Returns ranked results, may include irrelevant hardware from other machines
```

**Right:**

```text
query_memory(pool="machines", source="hdh-nzxt", tags="hardware,gpu")
→ Returns exactly the GPU entry for HDH-NZXT, nothing else
```

### Mistake: Using query_memory for exploratory questions

**Wrong:**

```text
query_memory(pool="devkit", content_contains="error handling")
→ Only finds memories with literal substring "error handling"
→ Misses memories about "nilerr", "bodyclose", "error wrapping"
```

**Right:**

```text
search_memory(pool="devkit", query="Go error handling patterns and gotchas")
→ Semantic search finds conceptually related memories regardless of wording
```

### Mistake: Forgetting the format parameter

When chaining Synapset results into code or reports, always use
`format: "json"` to get machine-parseable output instead of the
default human-readable text format.

### Mistake: Storing without metadata

**Wrong:**

```text
store_memory(pool="devkit", content="PowerShell $args is reserved")
→ No source, category, tags, or summary -- nearly impossible to find later with query_memory
```

**Right:**

```text
store_memory(
  pool="devkit",
  content="PowerShell $args is an automatic variable...",
  source="session-2026-03-16",
  category="gotcha",
  tags="powershell,variables,gotcha",
  summary="PowerShell $args is an automatic variable"
)
→ Findable by source, category, tags, or summary substring
```

## Anti-Patterns

### DON'T: Semantic search for structured data

```text
# BAD: Embedding similarity is unreliable for exact lookups
search_memory(pool="machines", query="HDH-NZXT GPU specs")
→ Might return GPU entries from other machines, or Ollama config instead of hardware

# GOOD: Exact source filter gets deterministic results
query_memory(pool="machines", source="hdh-nzxt", tags="hardware,gpu")
→ Returns exactly the GPU entry for that host
```

### DON'T: query_memory for fuzzy concepts

```text
# BAD: Exact filters miss conceptually related memories
query_memory(pool="devkit", content_contains="error handling")
→ Misses memories that say "exception management" or "fault tolerance"

# GOOD: Semantic search finds related concepts
search_memory(pool="devkit", query="error handling patterns")
→ Returns related memories regardless of exact wording
```

### DON'T: search_all when you know the pool

```text
# BAD: Searches all pools, mixed embedding models, slower
search_all(query="PowerShell gotcha")

# GOOD: Scoped to the right pool
search_memory(pool="devkit", query="PowerShell gotcha")
```

## Combining Tools

For complex lookups, chain tools:

1. `query_memory` to get structured context (machine specs, known issues)
2. `search_memory` to find related patterns or solutions
3. `update_memory` to correct stale entries discovered during the lookup
