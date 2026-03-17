---
name: synapset
description: Synapset semantic memory and structured retrieval. Use when storing, searching, or querying persistent memories across sessions and projects. Covers tool selection (semantic vs exact-match), pool conventions, session-start machine context loading, and storage best practices.
user_invocable: true
---

# Synapset: Semantic Memory & Structured Retrieval

Synapset is a Go-based MCP server providing persistent vector memory across
sessions and projects. It stores text with embeddings for semantic search
and supports exact-match structured queries for precise retrieval.

<essential_principles>

**Two Retrieval Modes -- Pick the Right One**

| Need | Tool | Why |
|------|------|-----|
| "What do I know about X?" | `search_memory` / `search_all` | Semantic similarity finds conceptually related memories even with different wording |
| "Give me the GPU specs for HDH-NZXT" | `query_memory` | Exact filters on source, category, tags, or content substrings -- no embedding overhead, deterministic results |

**Decision Framework**

Use `query_memory` when:

- You know the pool, source, category, or tags you want
- You need all records matching a structured filter (e.g., all memories from source `hdh-nzxt`)
- You need deterministic, complete results (not ranked by similarity)
- You are loading machine context at session start
- You want JSON output for programmatic consumption (`format: "json"`)

Use `search_memory` / `search_all` when:

- You have a natural-language question ("how did we fix the dispatcher timeout?")
- You want conceptually related results ranked by relevance
- You don't know which pool, source, or category to filter on
- You are exploring -- looking for patterns across projects

**Never use semantic search for structured lookups.** Embeddings rank by
cosine similarity, which means a query for "HDH-NZXT GPU" might return
results about GPUs on other machines or unrelated hardware topics. Use
`query_memory` with `source` or `content_contains` instead.

**Session-Start Machine Context**

At the start of a session on a physical workstation, load machine context:

1. Get the hostname (e.g., `$env:COMPUTERNAME` or Desktop Commander)
2. Query: `query_memory(pool="machines", source=<hostname-lowercase>)`
3. This returns CPU, GPU, RAM, storage, network, dev tools, workspace
   paths, Tailscale peers, and installed software for that machine

This replaces the need to hardcode machine specs in memory or CLAUDE.md.
The `machines` pool is the single source of truth for hardware context.

**Pool Conventions**

| Pool | Purpose | Source convention | Embedding model |
|------|---------|-------------------|-----------------|
| `machines` | Hardware specs, network, dev tools per host | hostname lowercase (e.g., `hdh-nzxt`) | nomic-embed-text |
| `devkit` | Cross-project patterns, gotchas, corrections | `migration-from-openai` or skill name | nomic-embed-text |
| `samverk` | Agent session completions, dispatcher learnings | `session:sess_<issue>_<ts>` | nomic-embed-text |
| `mcp-memory` | General knowledge graph bridge | varies | nomic-embed-text |

All pools use the same active embedding model (Ollama `nomic-embed-text`,
768 dimensions). Cross-pool `search_all` scores are directly comparable.

**Storage Best Practices**

When storing memories, structure them for later retrieval:

- **source**: Use a consistent, queryable identifier. For machines,
  use the hostname lowercase. For sessions, use `session:sess_<id>`.
  For skills/tools, use the skill or tool name.
- **category**: Use the standard set: `pattern`, `gotcha`, `correction`,
  `decision`, `preference`, `architecture`, `research`, `general`.
- **tags**: Comma-separated, lowercase. Use specific tags that support
  `query_memory` filtering (e.g., `hardware,gpu,ollama`).
- **summary**: Brief one-line summary. Supports `summary_contains`
  substring search in `query_memory`.
- **content**: The full memory text. Keep each memory focused on one
  concept -- split multi-topic content into separate memories.

**Updating Memories**

Use `update_memory` to correct or refresh existing entries rather than
deleting and re-creating. When content changes, the embedding is
automatically regenerated. This preserves the memory ID for any
references that point to it.

</essential_principles>

<tool_reference>

## Full Tool Inventory

| Tool | Purpose | Key parameters |
|------|---------|----------------|
| `store_memory` | Store new memory with embedding | pool, content, category, source, tags, summary |
| `search_memory` | Semantic KNN search in one pool | pool, query, limit, min_similarity, category, format |
| `search_all` | Semantic KNN search across all pools | query, limit, min_similarity, category, format |
| `query_memory` | Exact-match structured retrieval | pool, source, category, tags, content_contains, summary_contains, format |
| `list_memories` | List/paginate memories in a pool | pool, category, source, limit, offset |
| `list_pools` | Show all pools with metadata | (none) |
| `update_memory` | Update content/metadata (re-embeds) | id, content, category, source, tags, summary |
| `delete_memory` | Soft-delete a memory | id |
| `import_memories` | Bulk import JSON array | pool, source, memories (JSON) |

## Format Parameter

Both `search_memory` and `query_memory` accept `format`:

- `text` (default): Human-readable output for conversation
- `json`: Machine-parseable JSON array for programmatic use

Use `json` when passing results to code, building reports, or chaining
tool calls. Use `text` for conversational responses.

</tool_reference>

<!-- examples -->

## Common Patterns

**Load machine context at session start:**

```text
query_memory(pool="machines", source="hdh-nzxt")
→ Returns all 13 hardware/software entries for that host
```

**Find all PowerShell gotchas in devkit:**

```text
query_memory(pool="devkit", summary_contains="PowerShell")
→ Exact substring match, returns all PS-related memories
```

**Semantic search for a concept you can't name precisely:**

```text
search_memory(pool="samverk", query="dispatcher timeout recovery")
→ Ranked results by embedding similarity
```

**Store a new machine entry:**

```text
store_memory(
  pool="machines",
  source="cm-asus",
  category="general",
  tags="hardware,cpu",
  summary="CPU specifications",
  content="CM-ASUS CPU: AMD Ryzen 5 5600X, 6 cores, 12 threads."
)
```

**Update stale info without losing the memory ID:**

```text
update_memory(id=484, content="HDH-NZXT GPU: NVIDIA GeForce RTX 5090, 32GB VRAM. Ollama native Windows install working. Running qwen2.5-coder:32b.")
```

<!-- /examples -->

<references>
- references/pool-conventions.md -- Detailed pool schema, naming rules, and data lifecycle
- references/tool-decision-guide.md -- Flowchart for choosing the right retrieval tool
</references>

<routing>

This skill is invoked explicitly or referenced when Synapset tools are
relevant to the current task.

| Context | Action |
|---------|--------|
| Session start on a physical workstation | Load machine context via `query_memory` |
| Pre-task lookup (before coding/debugging) | `search_memory` in relevant pool for patterns/gotchas |
| Storing a learning (autolearn integration) | `store_memory` with proper pool, source, category, tags |
| Updating stale machine or project data | `update_memory` with the memory ID |
| Bulk seeding a new machine or pool | `import_memories` with JSON array |

</routing>

<success_criteria>

- Machine context is loaded at session start without manual prompting
- Exact-match lookups use `query_memory`, not `search_memory`
- Semantic searches use `search_memory` or `search_all`
- All stored memories have source, category, tags, and summary populated
- No duplicate memories are created (check before storing)
- Cross-pool search results account for mixed embedding models

</success_criteria>
