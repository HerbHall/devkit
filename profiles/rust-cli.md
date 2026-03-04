---
name: rust-cli
version: 1.0
description: Rust CLI tools and utilities
requires: []
winget:
  - id: Rustlang.Rustup
    check: rustc
manual:
  - id: cargo-audit
    check: cargo-audit
    install: cargo install cargo-audit
  - id: cross
    check: cross
    install: cargo install cross --locked
    note: For cross-compilation targets
vscode-extensions:
  - rust-lang.rust-analyzer
  - vadimcn.vscode-lldb
  - streetsidesoftware.code-spell-checker
claude-skills:
  - security-review
---

# Rust CLI Profile

Use this profile for Rust command-line tools, utilities, and terminal applications. These compile to standalone binaries with no runtime dependencies.

## When to Use This

- Command-line tools and utilities
- Terminal UI applications (using ratatui, crossterm, etc.)
- System utilities and performance-critical tools
- Libraries published to crates.io

## Project Structure

A typical Rust CLI project:

```text
my-tool/
├── src/
│   ├── main.rs          # Entry point
│   ├── lib.rs           # Library code (optional)
│   └── cli.rs           # Argument parsing
├── tests/               # Integration tests
├── Cargo.toml
├── Cargo.lock           # Commit this for binaries
├── Makefile
├── VERSION
└── CHANGELOG.md
```

## Makefile

Copy `project-templates/Makefile.rust` and replace `{{BINARY_NAME}}` with your binary name. Key targets:

```text
build:      cargo build --release
test:       cargo test
lint:       cargo clippy -- -D warnings
fmt:        cargo fmt --check
lint-all:   lint + fmt + lint-md
ci:         build + test + lint-all
run:        cargo run
```

Run `make hooks` after cloning to install the pre-push hook.

## Linting and Formatting

### Clippy

Rust's official linter. Catches common mistakes, performance issues, and style problems:

```bash
cargo clippy -- -D warnings  # treat all warnings as errors
```

Configure per-project lints in `Cargo.toml`:

```toml
[lints.clippy]
pedantic = "warn"
nursery = "warn"
```

### Rustfmt

Formats code according to the Rust style guide:

```bash
cargo fmt          # format in place
cargo fmt --check  # check without modifying (CI mode)
```

Configure in `rustfmt.toml` if needed (usually the defaults are fine).

## Testing

```bash
cargo test              # all tests
cargo test -- --nocapture  # with stdout output
cargo test integration_ # only integration tests matching prefix
```

For TUI applications, unit test the model/state layer and use integration tests for the full application flow.

## Cross-Compilation

Use `cross` for building on different targets without installing the full toolchain:

```bash
cross build --release --target x86_64-unknown-linux-gnu
cross build --release --target aarch64-unknown-linux-gnu
cross build --release --target x86_64-pc-windows-msvc
```

For simpler cases, add targets directly:

```bash
rustup target add x86_64-unknown-linux-musl
cargo build --release --target x86_64-unknown-linux-musl
```

## Security Auditing

```bash
cargo audit  # check for known vulnerabilities in dependencies
```

Run this in CI and before releases. Configure exceptions in `.cargo/audit.toml` if needed.

## VS Code Extensions

- **rust-lang.rust-analyzer** -- language server, code completion, diagnostics
- **vadimcn.vscode-lldb** -- debugger integration
- **streetsidesoftware.code-spell-checker** -- catch typos in comments and strings

## Related Profiles

- **go-cli** -- if you prefer Go for CLI tools
