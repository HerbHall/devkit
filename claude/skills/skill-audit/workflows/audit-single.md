# Audit Single Skill

Run all quality checks against a single skill.

## Procedure

### Step 1: Identify the skill

Ask the user which skill to audit if not already specified. Accept either:

- A skill name (e.g., `quality-control`)
- A directory path (e.g., `claude/skills/quality-control`)

Verify the skill directory exists. If not, list available skills and ask again.

### Step 2: Run all checks

Run the same five checks as described in `audit-all.md`:

1. YAML Frontmatter validation
2. Silent wait state detection
3. Skip/dismiss routing check
4. Workflow file reference validation
5. Trigger breadth assessment

### Step 3: Output report

Output the per-skill report with PASS/WARN/FAIL per check, same format as audit-all.md.
