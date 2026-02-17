# Markdown Style Rules

When creating or editing `.md` files, follow markdownlint conventions. These rules apply to ALL markdown files written or modified by Claude Code.

## Heading Rules

- **ATX style only** (`# Heading`, not underline style) [MD003]
- **Increment by one level** -- don't skip from `##` to `####` [MD001]
- **Single space after `#`** -- `# Heading` not `#Heading` or `#  Heading` [MD018, MD019]
- **Blank line before and after headings** [MD022]
- **No trailing punctuation** in headings (no `:`, `.`, `;`) [MD026]
- **No duplicate sibling headings** -- two `## Setup` under the same parent is not allowed [MD024]
- **First line should be a top-level heading** (`# Title`) [MD041]
- **Single H1 per document** [MD025]

## List Rules

- **Dash (`-`) for unordered lists** -- not `*` or `+` [MD004]
- **2-space indent** for nested lists [MD007]
- **Consistent spacing** after list markers [MD030]
- **Blank line before and after lists** [MD032]
- **Ordered lists use sequential numbers** (`1.`, `2.`, `3.`) [MD029]

## Code Rules

- **Fenced code blocks** with backticks (not tildes) [MD046, MD048]
- **Specify language** on fenced code blocks (` ```go `, ` ```bash `, ` ```yaml `) [MD040]
- **Blank line before and after** fenced code blocks [MD031]
- **No spaces inside code spans** -- `` `code` `` not `` ` code ` `` [MD038]

## Emphasis Rules

- **Asterisks for emphasis** -- `*italic*` and `**bold**` (not underscores) [MD049, MD050]
- **No spaces inside emphasis markers** -- `**bold**` not `** bold **` [MD037]

## Link and Image Rules

- **No bare URLs** -- wrap in link syntax `[text](url)` [MD034]
- **No empty links** -- `[](url)` is not allowed [MD042]
- **No spaces inside link text** -- `[text](url)` not `[ text ](url)` [MD039]
- **Images must have alt text** -- `![alt](image.png)` not `![](image.png)` [MD045]
- **No reversed link syntax** -- `[text](url)` not `(text)[url]` [MD011]

## Whitespace Rules

- **No trailing spaces** at end of lines [MD009]
- **No hard tabs** -- use spaces [MD010]
- **No multiple consecutive blank lines** -- single blank line only [MD012]
- **File must end with a single newline** [MD047]

## Table Rules

- **Blank line before and after tables** [MD058]
- **Consistent column count** across all rows [MD056]

## Inline HTML

- **Avoid inline HTML** when markdown syntax suffices [MD033]
- Allowed elements: `<br>`, `<details>`, `<summary>`, `<img>`, `<a>`, `<sub>`, `<sup>`

## Horizontal Rules

- **Use `---`** style consistently [MD035]

## Disabled Rules

- **MD013 (line-length)**: Disabled -- tables, URLs, and code references make fixed line length impractical

## Quick Reference for Common Mistakes

```markdown
BAD:  ## Setup:             (trailing colon)
GOOD: ## Setup

BAD:  # Title               (then later another # Title)
GOOD: # Title               (only one H1 per file)

BAD:  * item                (asterisk list marker)
GOOD: - item                (dash list marker)

BAD:  ```                   (no language on code fence)
GOOD: ```go                 (language specified)

BAD:  https://example.com   (bare URL)
GOOD: [Example](https://example.com)

BAD:  **bold text with trailing space **
GOOD: **bold text with no trailing space**
```
