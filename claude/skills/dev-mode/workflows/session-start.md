# Session Start

Runs automatically when `/dev-mode` is invoked. Checks for unprocessed research findings.

## Steps

### 1. Read Findings

Read `D:/DevSpace/.coordination/research-findings.md`.

### 2. Parse Unprocessed

Look for entries under `## Unprocessed` that have `Processed: No`.

### 3. Present Summary

**If unprocessed findings exist:**

```text
New research findings since last session:

| # | Impact | Summary |
|---|--------|---------|
| RF-001 | High | Scanopy gaps: no credential mgmt, no health monitoring |
| RF-002 | High | HA MQTT integration is table stakes for homelab community |

Should any of these influence today's priorities? (y/N, or specify RF-NNN)
```

**If user says yes to a finding:**
1. Mark it as `Processed: Yes` in research-findings.md
2. Move it from `## Unprocessed` to `## Processed`
3. Note what action was taken

**If no unprocessed findings:**

```text
No new research findings. Ready to code.
```

### 4. Proceed to Intake

Present the intake options from SKILL.md.
