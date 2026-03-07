# Audit All Skills

Run the full quality checklist against every skill directory under `claude/skills/`.

## Procedure

### Step 1: Enumerate skills

List all directories under `claude/skills/`:

```bash
ls -d claude/skills/*/
```

### Step 2: For each skill, run all checks

For each skill directory, read its `SKILL.md` and run the following checks:

#### Check 1: YAML Frontmatter

- Read the YAML frontmatter (between `---` delimiters)
- **FAIL** if `name` field is missing or empty
- **FAIL** if `description` field is missing or empty
- **FAIL** if `user_invocable` field is missing
- **WARN** if `description` is under 20 characters (likely too vague)

#### Check 2: Silent Wait States

- Search for `<intake>` sections in the SKILL.md
- If an `<intake>` section exists, verify there is visible text output (acknowledgment) before any "Wait for response" or blocking prompt
- **FAIL** if the intake section contains only a menu with no acknowledgment text before it
- **PASS** if the intake section has a clear acknowledgment line (e.g., "skill-name triggered. What would you like to do?")

#### Check 3: Skip/Dismiss Routing

- Check if the `<intake>` section mentions "skip" or "dismiss"
- If it does, check the `<routing>` table for an explicit cancel/skip/dismiss entry
- **FAIL** if intake mentions skip/dismiss but routing has no handler for it
- **PASS** if routing explicitly handles skip/dismiss, OR if intake does not mention them

#### Check 4: Workflow File References

- Parse the `<routing>` table for all workflow file paths (e.g., `workflows/foo.md`)
- For each referenced file, check if it exists on disk relative to the skill directory
- **FAIL** for each referenced workflow that does not exist
- **PASS** if all referenced workflows exist

#### Check 5: Trigger Breadth

- Read the `description` field from frontmatter
- **WARN** if it contains only generic single words like "code", "fix", "help", "debug", "test" without qualifying context
- **PASS** if the description is specific enough to avoid false-positive triggers

### Step 3: Generate report

Output a per-skill report:

```text
## Skill: <name> (<directory>)
- [PASS] YAML frontmatter
- [PASS] No silent wait states
- [FAIL] Missing skip/dismiss routing — intake mentions "skip" but routing has no cancel handler
- [PASS] All workflow references valid
- [WARN] Trigger may be too broad — description contains generic term "fix"
```

### Step 4: Summary line

After all skills are checked, output a summary:

```text
N skills audited: X pass, Y warnings, Z failing
```

A skill **passes** if it has zero FAIL findings. A skill has **warnings** if it has WARN but no FAIL findings.
