# Doc Review: Single File

Deep review of one document using the doc-reviewer agent with fresh context.

## Steps

### 1. Resolve File Path

The user provided a file path. Resolve it to an absolute path and verify it exists:

```bash
# Verify file exists
test -f "$FILE_PATH" && echo "exists" || echo "not found"
```

If the file does not exist, notify the user and stop.

### 2. Load Document Schemas

Read the schema definitions:

```bash
cat "D:/DevSpace/Toolkit/devkit/devspace/templates/doc-schemas.yaml"
```

### 3. Detect Document Type

Match the filename against `filename_patterns` from the schema. If no match, note the type as "unclassified" and proceed with general review (consistency and cross-references only, no structure validation).

### 4. Determine Project Context

Identify the project containing this file:

```bash
# Walk up from file to find .git directory
git -C "$(dirname "$FILE_PATH")" rev-parse --show-toplevel 2>/dev/null
```

Store the project root for cross-reference checking.

### 5. Gather Context Files

Collect files the reviewer needs for cross-reference checking:

- The target file itself
- The project's `CLAUDE.md` (if different from target)
- Any files linked from the target document (up to 10)
- The `doc-schemas.yaml` file

### 6. Spawn doc-reviewer Agent

Use the Agent tool to launch the `doc-reviewer` agent with fresh context:

```text
Review the following document for structure compliance, internal consistency,
cross-reference integrity, and semantic accuracy.

**Document to review**: {FILE_PATH}
**Document type**: {DETECTED_TYPE} (or "unclassified" if no schema match)
**Project**: {PROJECT_NAME} (root: {PROJECT_ROOT})

**Schema for this type** (from doc-schemas.yaml):
{SCHEMA_CONTENT_FOR_TYPE}

**Cross-reference context** (files linked from the document):
{LIST_OF_CONTEXT_FILES}

Follow your review workflow exactly. Check structure against the schema,
verify internal links resolve, spot-check that commands and paths are valid,
and flag any staleness indicators. Return a structured report with Summary,
Schema Compliance, Findings (by severity with file:line references), and
a Verdict of APPROVE, REVISE, or REJECT.
```

### 7. Handle the Verdict

**APPROVE** -- Present findings summary. The document is compliant.

**REVISE** -- Present findings. Offer to auto-fix what can be fixed (formatting via markdownlint, broken links if target is obvious). For structural issues, describe what sections need to be added.

**REJECT** -- Present findings with Critical issues highlighted. Describe what must change before the document is considered compliant. If the document is agent-generated, note that the producing agent's prompt may need updating to include the missing schema requirements.

### 8. Offer Follow-Up

After presenting results, offer relevant next actions:

- "Run `/doc-review fix` to auto-correct formatting issues"
- "Run `/doc-review consistency` to check for cross-document contradictions"
- For REVISE/REJECT verdicts: suggest specific edits to bring the document into compliance
