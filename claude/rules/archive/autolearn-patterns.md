# Archived Autolearn Patterns

Deprecated and superseded entries from `../autolearn-patterns.md`.
Full text stored in Synapset (pool: devkit). Query by entry ID tag to recover.

## AP#27 (archived, superseded by KG#17)

golangci-lint bodyclose with websocket.Dial. Close response body from Dial calls.
Synapset: pool=devkit, ID=553

## Archived 2026-03-07: Rules compaction (below 35k threshold)

### Project-specific entries (SubNetree/CLI-Play internals, not transferable)

## AP#5 (archived 2026-03-07)

WebSocket Auth: JWT via Query Parameter. Browser WS API doesn't support custom headers.
Synapset: pool=devkit, ID=554

## AP#9 (archived 2026-03-07)

React Flow Test Mocking Pattern. vi.mock('@xyflow/react') with comprehensive stubs.
Synapset: pool=devkit, ID=555

## AP#10 (archived 2026-03-07)

Slash Command / Skill Overlap Prevention. Check existing skills before creating commands.
Synapset: pool=devkit, ID=556

## AP#12 (archived 2026-03-07)

Astro Image Optimization: src/assets vs public/. Place images in src/assets for WebP.
Synapset: pool=devkit, ID=556

## AP#13 (archived 2026-03-07)

Astro Static on Cloudflare Pages. No adapter needed for output:static.
Synapset: pool=devkit, ID=556

## AP#21 (archived 2026-03-07)

Don't Start() Modules in Tests That Only Query the Store. Avoids goroutine races.
Synapset: pool=devkit, ID=557

## AP#25 (archived 2026-03-07)

Consumer-Side Adapter for Cross-Internal Imports. Define interface in consuming package.
Synapset: pool=devkit, ID=557

## AP#26 (archived 2026-03-07)

WebSocket Plugin Routes Need SimpleRouteRegistrar for different auth path.
Synapset: pool=devkit, ID=557

## AP#40 (archived 2026-03-07)

Go-Side Time-Bucket Aggregation Over SQL. SQLite strftime fails on RFC3339Nano.
Synapset: pool=devkit, ID=558

## AP#43 (archived 2026-03-07)

Viper Nested Mapstructure Keys Must Match Struct Hierarchy. Use dotted paths.
Synapset: pool=devkit, ID=558

## AP#44 (archived 2026-03-07)

React Nullable Local Override for Server State Sync. useState(null) with ?? fallback.
Synapset: pool=devkit, ID=558

## AP#89 (archived 2026-03-07)

Parallel Plain-Text Renderer for TUI Transition Animations. Mirror View() without ANSI.
Synapset: pool=devkit, ID=559

### Consolidation victims: gocritic cluster (merged into AP#2)

## AP#14 (archived 2026-03-07, consolidated into AP#2)

gocritic builtinShadow for Go Builtins.
Synapset: pool=devkit, ID=561

## AP#15 (archived 2026-03-07, consolidated into AP#2)

gocritic httpNoBody for GET/HEAD Requests.
Synapset: pool=devkit, ID=561

## AP#59 (archived 2026-03-07, consolidated into AP#2)

gocritic commentedOutCode on Math-Like Comments.
Synapset: pool=devkit, ID=561

## AP#61 (archived 2026-03-07, consolidated into AP#2)

gocritic unnamedResult: Named Returns Require = Not :=.
Synapset: pool=devkit, ID=561

## AP#62 (archived 2026-03-07, consolidated into AP#2)

gocritic appendCombine: Merge Consecutive Appends.
Synapset: pool=devkit, ID=561

## AP#64 (archived 2026-03-07, consolidated into AP#2)

gocritic paramTypeCombine: Consecutive Same-Type Params.
Synapset: pool=devkit, ID=561

## AP#65 (archived 2026-03-07, consolidated into AP#2)

gocritic dupBranchBody: Identical If/Else Branches.
Synapset: pool=devkit, ID=561

## AP#66 (archived 2026-03-07, consolidated into AP#2)

gocritic emptyStringTest: Prefer != "" Over len() > 0.
Synapset: pool=devkit, ID=561

## AP#105 (archived 2026-03-07, consolidated into AP#2)

gocritic sloppyReassign: Named Return Shadow in If Statement.
Synapset: pool=devkit, ID=561

## AP#113 (archived 2026-03-07, consolidated into AP#2)

gocritic preferFprint: Use fmt.Fprintf Over WriteString+Sprintf.
Synapset: pool=devkit, ID=561

### Consolidation victims: golangci-lint v2 migration (merged into AP#90)

## AP#115 (archived 2026-03-07, consolidated into AP#90)

golangci-lint v2 Formatters Are a Separate Top-Level Section.
Synapset: pool=devkit, ID=562

## AP#116 (archived 2026-03-07, consolidated into AP#90)

golangci-lint v2 Absorbs gosimple Into staticcheck.
Synapset: pool=devkit, ID=562

### Consolidation victims: golangci-lint rules (merged into AP#19)

## AP#102 (archived 2026-03-07, consolidated into AP#19)

noctx: Database Operations Must Use Context-Aware Variants.
Synapset: pool=devkit, ID=562

## AP#103 (archived 2026-03-07, consolidated into AP#19)

errcheck: resp.Body.Close Requires Explicit Error Discard.
Synapset: pool=devkit, ID=562

## AP#104 (archived 2026-03-07, consolidated into AP#19)

gosec G704: SSRF Nolint for Trusted Base URL Clients.
Synapset: pool=devkit, ID=562

### Consolidation victims: Swagger cluster (merged into AP#17)

## AP#35 (archived 2026-03-07, consolidated into AP#17)

Swagger CI Job Needs Explicit go mod download.
Synapset: pool=devkit, ID=562

### Consolidation victims: Parallel agent orchestration (merged into AP#48)

## AP#41 (archived 2026-03-07, consolidated into AP#48)

Subagent Recovery After Rate Limit or Session Break.
Synapset: pool=devkit, ID=563

## AP#52 (archived 2026-03-07, consolidated into AP#48)

Main.go Split for Parallel Agent Branches.
Synapset: pool=devkit, ID=563

## AP#67 (archived 2026-03-07, consolidated into AP#48)

Agent Autonomous Commit Disrupts Parallel Agent Work.
Synapset: pool=devkit, ID=563

### Consolidation victims: Git stash workflows (merged into AP#22)

## AP#37 (archived 2026-03-07, consolidated into AP#22)

git rebase --onto for Precise Stacked PR Cleanup.
Synapset: pool=devkit, ID=563

## AP#107 (archived 2026-03-07, consolidated into AP#22)

Stash Untracked Files Before Cross-Branch Push.
Synapset: pool=devkit, ID=563

### Consolidation victims: Merge sequencing (merged into AP#36)

## AP#53 (archived 2026-03-07, consolidated into AP#36)

Dependency PR Merge Ordering in Parallel Waves.
Synapset: pool=devkit, ID=563

## AP#98 (archived 2026-03-07, consolidated into AP#36)

4-PR Contributor Config Rollout Sequence.
Synapset: pool=devkit, ID=563

## AP#99 (archived 2026-03-07, consolidated into AP#36)

Dependabot Triage: Batch Check, Merge Green, Close Failing.
Synapset: pool=devkit, ID=563

### Consolidation victims: Competitive research (merged into AP#33)

## AP#34 (archived 2026-03-07, consolidated into AP#33)

Deep Competitive Analysis via gh CLI.
Synapset: pool=devkit, ID=564

## AP#42 (archived 2026-03-07, consolidated into AP#33)

Gap Exploitation Report Structure for Competitive Research.
Synapset: pool=devkit, ID=564

## AP#45 (archived 2026-03-07, consolidated into AP#33)

Blog Aggregation for Blocked Community Platforms.
Synapset: pool=devkit, ID=564

## AP#46 (archived 2026-03-07, consolidated into AP#33)

Curated List Ecosystem Mapping for Market Positioning.
Synapset: pool=devkit, ID=564

## Archived 2026-03-14: Rules compaction (below 35k threshold)

### Superseded entries

## AP#63 (archived 2026-03-14, superseded by KG#28)

Recharts Custom Tooltip Needs Partial Props.
Synapset: pool=devkit, ID=560

### Obsolete entries

## AP#70 (archived 2026-03-14)

SDD Tool Abstraction Level Check Before Integration.
Synapset: pool=devkit, ID=560

## AP#109 (archived 2026-03-14, consolidated into AP#122)

Standalone Python File for Regex-Heavy Bash Scripts.
Synapset: pool=devkit, ID=560

### Consolidation victims: Python UTF-8 (merged into AP#122)

## AP#11 (archived 2026-03-14, consolidated into AP#122)

Python as jq Replacement on Windows MSYS. UTF-8 I/O fix in AP#122.
Synapset: pool=devkit, ID=565

## Archived 2026-03-15: Rules compaction (governance + React + Windows consolidation)

### Superseded entry

## AP#27 (removed from active 2026-03-15)

golangci-lint bodyclose with websocket.Dial. Fully superseded by KG#17.
Synapset: pool=devkit, ID=553

### Consolidation victims: DevKit governance pipeline (merged into AP#18)

## AP#92 (archived 2026-03-15, consolidated into AP#18)

DevKit Scaffolding Must Include Executable Templates.
Synapset: pool=devkit, ID=564

## AP#93 (archived 2026-03-15, consolidated into AP#18)

Advisory Rules Without Enforcement Are Ignored Under Pressure.
Synapset: pool=devkit, ID=564

## AP#94 (archived 2026-03-15, consolidated into AP#18)

Autolearn Must Validate Before Writing Rules.
Synapset: pool=devkit, ID=564

## AP#95 (archived 2026-03-15, consolidated into AP#18)

Fix-Forward Replaces Pre-Existing Error Classification.
Synapset: pool=devkit, ID=564

## AP#108 (archived 2026-03-15, consolidated into AP#18)

Phased Research-Gate Workflow for New Projects.
Synapset: pool=devkit, ID=564

### Consolidation victims: React Compiler and MUI patterns (merged into AP#111)

## AP#112 (archived 2026-03-15, consolidated into AP#111)

useRef Guard to Prevent useEffect Re-Trigger Loops.
Synapset: pool=devkit, ID=565

## AP#114 (archived 2026-03-15, consolidated into AP#111)

React Callback Ref for MUI Popper Anchors (React Compiler Compliance).
Synapset: pool=devkit, ID=565

### Consolidation victims: Windows shell interop (merged into AP#73)

## AP#75 (archived 2026-03-15, consolidated into AP#73)

Start-Job Timeout for Commands That Might Hang.
Synapset: pool=devkit, ID=565

## AP#76 (archived 2026-03-15, consolidated into AP#73)

PowerShell Temp File for Complex Commands from MSYS Bash.
Synapset: pool=devkit, ID=565
