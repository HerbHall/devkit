# Review Pipeline E2E Test

Validates that the independent review pipeline (plan-reviewer + review-code agents) correctly identifies security and design flaws in test artifacts.

## Prerequisites

- Claude Code CLI installed and authenticated (`claude --version` works)
- PowerShell 7+ (`pwsh`)

## Running

```powershell
pwsh -File tests/review-pipeline/run-review-test.ps1
```

Add `-Verbose` to see detail on passing tests:

```powershell
pwsh -File tests/review-pipeline/run-review-test.ps1 -Verbose
```

## Test Structure

```text
tests/review-pipeline/
├── README.md                  # This file
├── run-review-test.ps1        # Test runner
├── test-plan.md               # Flawed plan (Critical: plaintext passwords, no token expiry)
├── test-plan-fixed.md         # Corrected plan (should APPROVE)
├── test-code/
│   ├── handler.go             # Flawed code (Critical: SQL injection, command injection)
│   └── handler-fixed.go       # Corrected code (should APPROVE)
└── expected-findings.md       # Documents what reviewers should catch
```

## What It Tests

| Test | Input | Expected Verdict | Key Findings |
|------|-------|-----------------|--------------|
| 1. Plan review (flawed) | `test-plan.md` | REVISE or REJECT | Plaintext password storage, no token expiration |
| 2. Plan review (fixed) | `test-plan-fixed.md` | APPROVE | No Critical/High findings |
| 3. Code review (flawed) | `handler.go` | REQUEST_CHANGES | SQL injection, command injection |
| 4. Code review (fixed) | `handler-fixed.go` | APPROVE | No Critical findings |

## Intentional Flaws

See [expected-findings.md](expected-findings.md) for the full list of intentional flaws and where they appear.

## Using as a Template

Copy this directory into any project to validate its review pipeline. Replace the test artifacts with project-relevant examples:

1. Replace `test-plan.md` with a plan containing domain-specific flaws
2. Replace `handler.go` with code in the project's primary language
3. Update `expected-findings.md` with the new expected findings
4. Keep `run-review-test.ps1` as-is (it uses Claude CLI generically)
