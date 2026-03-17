# Pool Conventions

Standard pool definitions, naming rules, and data lifecycle for Synapset.

## Pool Definitions

### `machines`

Hardware and software inventory per physical workstation.

- **Embedding model**: nomic-embed-text (Ollama, local)
- **Source convention**: Hostname lowercase (e.g., `hdh-nzxt`, `cm-asus`)
- **Category**: `general` for most entries, `architecture` for workspace layout
- **Tags**: Use hierarchical tags: `hardware,cpu` / `hardware,gpu` / `network,tailscale`
- **One memory per concern**: CPU, GPU, RAM, storage, network, OS, dev tools, workspace paths, etc.
- **Update frequency**: When hardware changes, tools are upgraded, or IPs shift

### `devkit`

Cross-project patterns, gotchas, corrections, and learned rules.

- **Embedding model**: nomic-embed-text (Ollama, local)
- **Source convention**: Origin identifier (e.g., `migration-from-openai`, skill name, session ID)
- **Category**: Use the standard learning hierarchy: `correction`, `gotcha`, `pattern`, `decision`, `preference`
- **Tags**: Platform and language tags: `powershell,gotcha` / `go,lint` / `git,workflow`
- **Relationship to autolearn**: Autolearn may store here for cross-project learnings

### `samverk`

Agent session completions and dispatcher operational data.

- **Embedding model**: nomic-embed-text (Ollama, local)
- **Source convention**: `session:sess_<issue>_<timestamp>` for agent completions
- **Category**: `completion` for finished agent work, standard categories for other entries
- **Tags**: Issue-specific tags
- **High volume**: This pool grows with every agent session; use pagination

### `mcp-memory`

Bridge pool for MCP Memory knowledge graph integration.

- **Embedding model**: text-embedding-3-small (OpenAI API)
- **Source convention**: Varies
- **Note**: Different embedding model from other pools. Similarity scores
  from `search_all` are not directly comparable across this pool and
  Ollama-backed pools.

## Naming Rules

- **Pool names**: lowercase, no spaces, hyphen-separated (e.g., `mcp-memory`)
- **Source values**: lowercase, hyphen or colon-separated (e.g., `hdh-nzxt`, `session:sess_577_123`)
- **Tags**: lowercase, comma-separated, no spaces (e.g., `hardware,gpu,ollama`)
- **Category**: Must be one of: `pattern`, `gotcha`, `correction`, `decision`, `preference`, `architecture`, `research`, `general`

## Data Lifecycle

### Creating New Pools

Pools are created implicitly on first `store_memory` call with a new
pool name. No explicit creation step needed.

### Updating Entries

Use `update_memory(id=<id>)` to modify content or metadata. If content
changes, the embedding vector is automatically regenerated. Prefer
updating over delete-and-recreate to preserve stable IDs.

### Deleting Entries

`delete_memory` performs a soft delete (archives the memory and removes
it from vector search). The record remains in the database but is no
longer returned by queries or searches.

### Bulk Operations

`import_memories` accepts a JSON array for seeding new pools or machines.
All imported memories share the same `source` value. Use when onboarding
a new workstation or migrating data between pools.
