# DevSpace - Development Workspace

Primary development workspace at `D:\DevSpace\`. All active projects, research, and tools live here.

## Settings Philosophy: Three-Tier Consistency

Consistency across projects without bloat. Settings live at the **highest level where they're universal**, and only push down what's specific. Three tiers:

### Tier 1: VS Code User Settings (global, automatic)

Location: `%APPDATA%\Code\User\settings.json`

Things that are truly universal — theme, font, tab size, format-on-save, git autofetch. These apply to every project automatically with zero duplication. If a preference applies to *all* code you write regardless of project, it belongs here.

### Tier 2: DevSpace shared configs (automatic for some, reference for others)

Location: `D:\DevSpace\` (this directory)

Two categories here — understand the difference:

**Auto-cascading files** — these tools walk up parent directories by spec, so every project under DevSpace inherits them automatically:

| File | Tool | How It Cascades |
|------|------|----------------|
| `.editorconfig` | EditorConfig spec | Editors walk up directories until `root = true` |
| `.markdownlint.json` | markdownlint | Walks up directories to find config |

Projects can override with a local copy. For `.editorconfig`, use `root = false` or omit `root` to inherit, or `root = true` to stop the walk.

**Reference resources** — these do NOT auto-apply. Projects copy or reference what they need:

| Directory | Purpose |
|-----------|---------|
| `.templates/` | Starter files for new projects (ADRs, design docs, CLAUDE.md boilerplate) |
| `.shared-vscode/` | Reusable VS Code setting fragments — copy into project workspace files |

### Tier 3: Project-level settings (scoped, intentional)

Location: `D:\DevSpace\{Project}\`

Each project has its own workspace file (`{project}.code-workspace` or `dev.code-workspace`) that defines only the **delta** from Tiers 1 and 2. If User Settings already say `formatOnSave: true`, the workspace file does not repeat it. The workspace file adds project-specific things like TypeScript SDK paths, project-specific extension recommendations, or folder exclusions unique to that project.

Within a multi-root workspace, settings cascade: **User → Workspace → Folder** (folder wins). Each folder in a workspace can have `.vscode/settings.json` for folder-specific overrides.

### What does NOT cascade

**VS Code workspace settings do not inherit from parent directories.** Opening `Runbooks\runbooks.code-workspace` does NOT pick up settings from `D:\DevSpace\dev.code-workspace`. Each workspace is independent. Shared VS Code patterns go in `.shared-vscode/` as copyable fragments.

**The `.coordination/` folder** does not cascade either. It's a cross-project coordination hub, not a settings layer. Projects that need coordination use it explicitly.

## Directory Structure

```text
D:\DevSpace\
├── CLAUDE.md                  # This file — workspace-wide conventions
├── .editorconfig              # Tier 2: auto-cascading editor config
├── .markdownlint.json         # Tier 2: auto-cascading markdown rules
├── .claude/                   # Claude Code settings for DevSpace scope
│   └── settings.local.json
│
├── .templates/                # Tier 2: starter files for new projects
│   ├── README.md              #   Usage guide
│   ├── adr-template.md        #   Architecture Decision Record template
│   ├── design-template.md     #   Design doc / lightweight RFC template
│   ├── test-plan-template.md  #   Test plan template
│   └── claude-md-template.md  #   CLAUDE.md boilerplate for new projects
│
├── .shared-vscode/            # Tier 2: copyable VS Code fragments
│   ├── README.md              #   How to use these fragments
│   ├── typescript.jsonc       #   TypeScript/React project settings
│   ├── go.jsonc               #   Go project settings
│   └── extensions.jsonc       #   Common extension recommendations
│
├── .coordination/             # MOVED to SubNetree/.coordination/ (2026-02-16)
│                              #   See SubNetree project for coordination files
│
├── subnetree.code-workspace   # SubNetree single-root workspace
│
├── SubNetree/                 # Network monitoring platform (Go + React)
├── Runbooks/                  # Docker Desktop extension — saved command scripts
├── DigitalRain/               # Rust terminal visual effect
├── IPScan/                    # C# network scanner
├── Timberborn-Mods/           # Unity/C# game mods
├── Cowork/                    # Desktop automation tool
├── Websites/                  # Web projects
│   └── herbhall.net/          #   Personal website
└── research/                  # Legacy — HomeLab research moved to SubNetree/research/ (2026-02-16)
                               #   Loose files (*.txt) may remain for other projects

D:\archive\                    # Inactive/completed work (at drive root)
├── Play with Claude/          #   Early experimental projects
├── requirements_generator/    #   Orphaned skill (installed at ~/.claude/skills/)
└── digital_rain.zip           #   Archive of DigitalRain release
```

## Conventions

- Every project has its own `CLAUDE.md` with build commands and architecture
- Use conventional commits: `feat:`, `fix:`, `refactor:`, `docs:`, `test:`, `chore:`
- Always cite sources in code and documentation
- Maintain `README.md` for GitHub with credits section

## Adding a New Project

1. Create a folder under `D:\DevSpace\`
2. Copy `CLAUDE.md` boilerplate from `.templates/claude-md-template.md`
3. Copy relevant VS Code fragments from `.shared-vscode/` into your workspace file
4. `.editorconfig` and `.markdownlint.json` apply automatically — no action needed
5. If the project needs cross-project coordination, add entries to `.coordination/`
6. Add the folder to `dev.code-workspace` only if it shares coordination with SubNetree; otherwise give it its own workspace file

## Coordination System

SubNetree keeps its coordination and research files inside the project directory (`SubNetree/.coordination/` and `SubNetree/research/`), both gitignored. This was consolidated from separate repos on 2026-02-16. Other projects (like Runbooks) use project-local `.coordination/` with the same pattern.

### Hub Files

| File | Purpose |
|------|---------|
| `DASHBOARD.md` | Session control station — start here |
| `status.md` | Current state of coordinated projects |
| `research-needs.md` | Requests from dev to research (`RN-NNN` entries) |
| `research-findings.md` | Research output for dev consumption (`RF-NNN` entries) |
| `decisions.md` | Cross-project architectural decisions (`D-NNN` entries) |
| `priorities.md` | Unified priority stack |

### Numbering Conventions

- **RN-NNN** (Research Need): Filed during dev when a question arises. Priority: High/Medium/Low. Status: Open/In-Progress/Complete.
- **RF-NNN** (Research Finding): Published from HomeLab after analysis. Includes impact rating, action items, and processed flag.
- **D-NNN** (Decision): Cross-project decisions with date, context, evidence, and impact assessment.

### Skills

| Skill | Purpose | Invoke |
|-------|---------|--------|
| `dashboard` | Session control station — start here | `/dashboard` |
| `research-mode` | Competitive analysis, market research | `/research-mode` |
| `coordination-sync` | Bidirectional sync between projects | `/coordination-sync` |
| `pm-view` | Bird's-eye project management view | `/pm-view` |

### Automation

- **Hooks**: Both SubNetree and HomeLab have `UserPromptSubmit` hooks that surface coordination context automatically.
- **VS Code tasks**: `Coordination: Full Sync`, `Coordination: Stale Check`, `Research: Process Needs` in HomeLab workspace.
