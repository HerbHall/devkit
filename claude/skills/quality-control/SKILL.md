---
name: quality-control
description: Follow up after code changes to verify PRs pass CI, check for unresolved issues, ensure quality gates are met, and validate release readiness. Use after creating PRs, pushing code, auditing open PRs, or before tagging a release.
---

<essential_principles>

**Purpose**
This skill provides systematic quality verification for code changes. It catches CI failures, blocked PRs, stale branches, and unresolved issues before they accumulate into tech debt.

**When to Use**

- After creating or pushing to a PR
- When the user asks to check PR status or fix CI failures
- As a follow-up after other skills that produce code changes (e.g., after `/create-plan` execution)
- Periodically to audit all open PRs for health

**Core Quality Gates**

| Gate | What to Check | How |
|------|--------------|-----|
| CI Status | All checks pass (build, test, lint, vet, license) | `gh pr checks <number>` |
| Merge Conflicts | PR is mergeable, no conflicts with base branch | `gh pr view <number> --json mergeable` |
| Review Status | Required reviews are complete | `gh pr view <number> --json reviewDecision` |
| Branch Freshness | PR branch is up to date with base | `gh pr view <number> --json mergeStateStatus` |
| CLA Compliance | CLA check passes for all contributors | Check CLA status in checks |

**Quality Principles**

1. **Fail fast, fix fast.** Identify failures immediately after pushing. The longer a broken PR sits, the harder it is to fix.
2. **Root cause over symptoms.** When CI fails, identify whether the failure is in the PR's code, pre-existing in the base branch, or an infrastructure issue. Each requires a different fix strategy.
3. **Minimal intervention.** Fix only what's broken. Don't refactor unrelated code while fixing CI failures.
4. **Verify after fix.** Always confirm the fix by checking CI status after pushing. Never assume a fix worked.

**Failure Classification**

| Category | Description | Action |
|----------|-------------|--------|
| PR-introduced | Failure caused by code in the PR | Fix on the PR branch |
| Pre-existing | Failure exists in the base branch | Fix on PR branch (or separate fix PR to base) |
| Infrastructure | CI runner issues, flaky tests, timeouts | Re-run the workflow |
| Configuration | Wrong CI config (versions, paths, flags) | Fix the workflow/config file |
| Dependency | External dependency issue (license, vuln) | Update dependency or add exception |

</essential_principles>

<diagnostics>

**Diagnosing CI Failures**

For each failing check, follow this diagnostic flow:

1. **Get the failure details:**

   ```bash
   gh pr checks <number>
   ```

2. **For each failing job, get logs:**

   ```bash
   gh run view <run_id> --log --job=<job_id> 2>&1 | grep -E "error|Error|FAIL|fatal" | head -20
   ```

3. **Classify the failure** using the table above.

4. **For pre-existing failures**, verify by checking if the same error exists on the base branch:

   ```bash
   gh api repos/{owner}/{repo}/actions/runs?branch=main&per_page=3 --jq '.workflow_runs[0].conclusion'
   ```

**Common CI Failure Patterns**

<pattern name="golangci-lint-version-mismatch">
**Symptom:** `the Go language version used to build golangci-lint is lower than the targeted Go version`
**Cause:** golangci-lint binary was pre-built with older Go. Project uses newer Go.
**Fix:** Change `install-mode: binary` to `install-mode: goinstall` in golangci-lint-action config.
</pattern>

<pattern name="gosec-false-positive">
**Symptom:** `G101: Potential hardcoded credentials (gosec)` on a constant that contains "credential", "password", "secret", or "token" in its name but is not actually a credential.
**Fix:** Add `//nolint:gosec // G101: <reason>` comment on the line.
</pattern>

<pattern name="gocritic-rangeValCopy">
**Symptom:** `rangeValCopy: each iteration copies N bytes (consider pointers or indexing) (gocritic)`
**Cause:** Ranging over a slice of large structs by value.
**Fix:** Use `for i := range slice { ... slice[i].Field ... }` instead of `for _, v := range slice`.
</pattern>

<pattern name="license-check-unknown">
**Symptom:** `Failed to find license for <package>: cannot find a known open source license`
**Cause:** go-licenses can't find or classify the license file.
**Fix:** Use grep-based blocked-license approach instead of --allowed_licenses allowlist. Or add `--ignore <package>` for the project's own packages.
</pattern>

<pattern name="cancelled-checks">
**Symptom:** All CI jobs show as CANCELLED with no step output.
**Cause:** Concurrency group cancelled the run (another push), or workflow was manually cancelled.
**Fix:** Re-run the workflow: `gh api repos/{owner}/{repo}/actions/runs/{run_id}/rerun -X POST`
</pattern>

<pattern name="merge-conflict">
**Symptom:** PR shows "This branch has conflicts that must be resolved."
**Fix:** Rebase the PR branch onto the base branch: `git checkout <branch> && git rebase main && git push --force-with-lease`
</pattern>

</diagnostics>

<intake>
What would you like to do?

1. **Check a specific PR** - Diagnose and fix CI failures on a specific pull request
2. **Audit all open PRs** - Review all open PRs for CI failures, merge conflicts, and staleness
3. **Post-push verification** - Verify CI passes after a recent push (monitors until complete)
4. **Fix CI failures** - Automatically diagnose and fix CI failures across all open PRs
5. **Root cause analysis** - Investigate recurring failures and implement preventive measures
6. **Pre-release check** - Validate release readiness (git state, .gitignore, GoReleaser, ldflags, Dockerfile)
7. **File QC issues** - Create GitHub issues for findings from a QC testing session

**Wait for response before proceeding.**
</intake>

<routing>
| Response | Workflow |
|----------|----------|
| 1, "check", "specific", "PR", number | workflows/check-pr.md |
| 2, "audit", "all", "open", "review" | workflows/audit-prs.md |
| 3, "post-push", "verify", "monitor" | workflows/post-push-verify.md |
| 4, "fix", "CI", "failures", "auto" | workflows/fix-ci-failures.md |
| 5, "root cause", "recurring", "pattern", "why", "keeps happening" | workflows/root-cause-analysis.md |
| 6, "pre-release", "release check", "before tag", "release ready" | workflows/pre-release-check.md |
| 7, "file", "QC", "issues", "findings", "bugs found" | workflows/file-qc-issues.md |

**After reading the workflow, follow it exactly.**
</routing>

<workflows_index>

| Workflow | Purpose |
|----------|---------|
| check-pr.md | Diagnose and fix CI failures on a specific PR |
| audit-prs.md | Review all open PRs for issues |
| post-push-verify.md | Monitor CI after pushing and report results |
| fix-ci-failures.md | Auto-diagnose and fix CI failures across PRs |
| root-cause-analysis.md | Investigate recurring failures and implement prevention |
| pre-release-check.md | Validate release readiness (git state, GoReleaser, ldflags, Dockerfile) |
| file-qc-issues.md | Create GitHub issues for QC testing session findings |

</workflows_index>

<reference_index>

| Reference | Content |
|-----------|---------|
| ci-failure-patterns.md | Common CI failure patterns with diagnosis and fix steps |

</reference_index>

<skill_coordination>

**Related skills and when to use them:**

| Skill | When to Use Instead |
|-------|-------------------|
| `/setup-github-actions` | When creating new CI workflows from scratch (this skill fixes existing ones) |
| `/manage-github-issues` | When failures reveal missing issues that should be tracked |
| `/go-development` | When CI failures require Go-specific fixes (lint, test patterns) |
| `/create-plan` | When CI failures reveal systemic issues needing a larger refactor |

**Note:** The pre-release check workflow (option 6) consolidates what was previously the standalone `/pre-release-check` skill. Use it before tagging any release.

**Typical workflow sequence:**

1. Developer creates code changes using any skill
2. Developer creates PR using git workflow
3. **`/quality-control`** (post-push) -- verify CI passes
4. If failures found: **`/quality-control`** (fix) -- diagnose and fix
5. If new issues discovered: `/manage-github-issues` -- track them
6. Periodically: **`/quality-control`** (audit) -- catch stale PRs
7. After QC testing: **`/quality-control`** (file QC issues) -- capture all findings as GitHub issues

**Proactive Usage:**
Other skills that produce code changes SHOULD invoke quality-control after creating PRs:

- After `git push` + `gh pr create`, run post-push verification
- After fixing bugs, verify the fix passes CI before marking complete

</skill_coordination>

<success_criteria>
A successful quality control run produces:

- [ ] All target PRs checked for CI status
- [ ] Failing checks diagnosed with root cause identified
- [ ] Failures classified (PR-introduced, pre-existing, infrastructure, config)
- [ ] Fixes applied where possible (lint issues, config fixes, rebases)
- [ ] Fixes pushed and CI re-triggered
- [ ] Post-fix verification confirming CI passes
- [ ] Summary report of actions taken and remaining issues
- [ ] Any unresolvable issues reported to user with recommendations
</success_criteria>
