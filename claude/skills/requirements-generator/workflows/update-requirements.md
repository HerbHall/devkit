<required_reading>
**Read these reference files NOW:**

1. references/requirements-template.md (for structure reference)
</required_reading>

<process>

**Step 1: Read Existing Requirements**

Read the current requirements.md file. Parse:

- Current version number
- Existing requirements and priorities
- Changelog history

**Step 2: Understand the Change**

Ask user using AskUserQuestion:

1. **What changed?** - New feature, scope change, removed requirement, clarification?
2. **Which requirements are affected?** - List specific items or sections
3. **Reason for change** - Why is this changing? (for changelog)

**Step 3: Determine Version Bump**

Apply versioning rules:

- **MAJOR bump** (1.0 -> 2.0): New features added, requirements removed, significant scope change
- **MINOR bump** (1.0 -> 1.1): Clarifications, refinements, acceptance criteria updates

**Step 4: Apply Changes**

Make the requested modifications:

- Add new requirements with appropriate MoSCoW priority
- Update existing requirement text
- Move items between priority levels
- Move items to/from out-of-scope
- Update acceptance criteria

**Step 5: Update Changelog**

Add entry at top of changelog:

```markdown
## [X.Y] - YYYY-MM-DD
### Added
- New requirement descriptions

### Changed
- Modified requirement descriptions

### Removed
- Removed requirement descriptions (moved to out-of-scope or deleted)
```

**Step 6: Review Changes**

Show user a diff-style summary of changes:

- What was added
- What was modified
- What was removed
- New version number

Ask for approval before writing.

**Step 7: Write Updated File**

Write the updated requirements.md with new version and changelog.

</process>

<success_criteria>
This workflow is complete when:

- [ ] Existing requirements read and parsed
- [ ] Changes understood and validated
- [ ] Version number correctly bumped
- [ ] Changelog updated with all changes
- [ ] User approved the changes
- [ ] Updated file written
</success_criteria>
