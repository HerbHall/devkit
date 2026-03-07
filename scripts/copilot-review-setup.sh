#!/usr/bin/env bash
set -euo pipefail

# copilot-review-setup.sh -- Set up or audit Copilot auto-review on a GitHub repo.
#
# Usage:
#   ./scripts/copilot-review-setup.sh audit  OWNER/REPO   # check compliance
#   ./scripts/copilot-review-setup.sh setup  OWNER/REPO   # create ruleset + enable auto-merge
#   ./scripts/copilot-review-setup.sh audit-all OWNER      # audit all non-archived repos
#
# Requires: gh (GitHub CLI) authenticated with admin access.

ACTION="${1:-}"
TARGET="${2:-}"

if [[ -z "$ACTION" || -z "$TARGET" ]]; then
  echo "Usage: $0 {audit|setup|audit-all} OWNER/REPO_OR_OWNER"
  exit 1
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

pass() { echo -e "  ${GREEN}PASS${NC}: $1"; }
fail() { echo -e "  ${RED}FAIL${NC}: $1"; }
warn() { echo -e "  ${YELLOW}WARN${NC}: $1"; }

# -------------------------------------------------------------------
# audit_repo -- check compliance for a single repo
# -------------------------------------------------------------------
audit_repo() {
  local repo="$1"
  local errors=0

  echo "=== Auditing $repo ==="

  # 1. Auto-merge enabled
  local auto_merge
  auto_merge=$(gh api "repos/$repo" --jq '.allow_auto_merge' 2>/dev/null || echo "false")
  if [[ "$auto_merge" == "true" ]]; then
    pass "Auto-merge enabled"
  else
    fail "Auto-merge not enabled"
    errors=$((errors + 1))
  fi

  # 2. Copilot PR Review ruleset exists and is active (must be the combined standard)
  local ruleset_id=""
  local ruleset_enforcement=""
  local has_legacy_split="false"
  while IFS=$'\t' read -r rid rname renf; do
    if [[ "$rname" == "Copilot PR Review" && -z "$ruleset_id" ]]; then
      ruleset_id="$rid"
      ruleset_enforcement="$renf"
    elif [[ "$rname" == "Copilot Code Review" || "$rname" == "PR Merge Policy" ]]; then
      has_legacy_split="true"
    fi
  done < <(gh api "repos/$repo/rulesets" --jq '.[] | [.id, .name, .enforcement] | @tsv' 2>/dev/null || true)

  if [[ "$has_legacy_split" == "true" ]]; then
    fail "Legacy split rulesets detected (Copilot Code Review / PR Merge Policy) -- replace with combined 'Copilot PR Review'"
    errors=$((errors + 1))
  fi

  if [[ -z "$ruleset_id" ]]; then
    fail "No 'Copilot PR Review' combined ruleset found"
    errors=$((errors + 1))
  elif [[ "$ruleset_enforcement" != "active" ]]; then
    fail "Copilot review ruleset exists but enforcement is '$ruleset_enforcement' (expected 'active')"
    errors=$((errors + 1))
  else
    pass "Copilot PR Review ruleset exists and is active (id: $ruleset_id)"

    # 3. Check copilot_code_review rule with review_on_push
    local has_copilot_review
    has_copilot_review=$(gh api "repos/$repo/rulesets/$ruleset_id" \
      --jq '.rules[] | select(.type == "copilot_code_review") | .parameters.review_on_push' 2>/dev/null || echo "")
    if [[ "$has_copilot_review" == "true" ]]; then
      pass "copilot_code_review rule with review_on_push: true"
    else
      fail "Missing or misconfigured copilot_code_review rule"
      errors=$((errors + 1))
    fi

    # 4. Check pull_request rule with required_approving_review_count: 1
    local review_count
    review_count=$(gh api "repos/$repo/rulesets/$ruleset_id" \
      --jq '.rules[] | select(.type == "pull_request") | .parameters.required_approving_review_count' 2>/dev/null || echo "")
    if [[ "$review_count" == "1" ]]; then
      pass "pull_request rule with required_approving_review_count: 1"
    else
      fail "pull_request rule missing or review count is '$review_count' (expected 1)"
      errors=$((errors + 1))
    fi

    # 5. Check admin bypass actor
    local has_admin_bypass
    has_admin_bypass=$(gh api "repos/$repo/rulesets/$ruleset_id" \
      --jq '.bypass_actors[] | select(.actor_id == 5 and .actor_type == "RepositoryRole") | .bypass_mode' 2>/dev/null || echo "")
    if [[ "$has_admin_bypass" == "always" ]]; then
      pass "Admin bypass actor configured"
    else
      fail "Admin bypass actor missing"
      errors=$((errors + 1))
    fi
  fi

  # 6. Branch protection does NOT have required_pull_request_reviews
  local bp_reviews
  bp_reviews=$(gh api "repos/$repo/branches/main/protection/required_pull_request_reviews" \
    --jq '.required_approving_review_count' 2>/dev/null || echo "none")
  if [[ "$bp_reviews" == "none" ]]; then
    pass "Branch protection has no review requirement (avoids double review gate)"
  else
    warn "Branch protection has review requirement ($bp_reviews reviews) -- may conflict with ruleset"
  fi

  # 7. CODEOWNERS file exists
  local has_codeowners="false"
  for path in CODEOWNERS .github/CODEOWNERS docs/CODEOWNERS; do
    if gh api "repos/$repo/contents/$path" --jq '.name' >/dev/null 2>&1; then
      has_codeowners="true"
      break
    fi
  done
  if [[ "$has_codeowners" == "true" ]]; then
    pass "CODEOWNERS file exists"
  else
    fail "CODEOWNERS file not found"
    errors=$((errors + 1))
  fi

  echo ""
  if [[ "$errors" -eq 0 ]]; then
    echo -e "  ${GREEN}All checks passed${NC}"
  else
    echo -e "  ${RED}$errors check(s) failed${NC}"
  fi
  echo ""

  return "$errors"
}

# -------------------------------------------------------------------
# setup_repo -- create ruleset and enable auto-merge
# -------------------------------------------------------------------
setup_repo() {
  local repo="$1"
  local script_dir
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  local template="$script_dir/../project-templates/copilot-ruleset.json"

  echo "=== Setting up Copilot auto-review on $repo ==="

  # Enable auto-merge
  echo "Enabling auto-merge..."
  gh api "repos/$repo" -X PATCH -f allow_auto_merge=true --silent
  pass "Auto-merge enabled"

  # Create ruleset from template
  echo "Creating Copilot PR Review ruleset..."
  if gh api "repos/$repo/rulesets" -X POST --input "$template" --silent 2>/dev/null; then
    pass "Ruleset created"
  else
    warn "Ruleset creation failed (may already exist)"
  fi

  echo ""
  echo -e "${YELLOW}MANUAL STEPS REQUIRED:${NC}"
  echo "1. Go to repo Settings > Rules > Rulesets > 'Copilot PR Review'"
  echo "2. Click Edit on the 'Require a pull request before merging' rule"
  echo "3. Under 'Additional settings', enable 'Require review from GitHub Copilot'"
  echo "   (This toggle is UI-only -- the API creates the copilot_code_review rule"
  echo "    but the UI toggle may need to be confirmed)"
  echo "4. Verify: Create a test PR with a real file change, confirm Copilot reviews it"
  echo ""

  # Run audit to verify
  echo "Running compliance audit..."
  audit_repo "$repo" || true
}

# -------------------------------------------------------------------
# main
# -------------------------------------------------------------------
case "$ACTION" in
  audit)
    audit_repo "$TARGET"
    ;;
  setup)
    setup_repo "$TARGET"
    ;;
  audit-all)
    OWNER="$TARGET"
    total=0
    compliant=0
    repos=$(gh repo list "$OWNER" --json name,isArchived --jq '.[] | select(.isArchived == false) | .name' | sort)
    for repo_name in $repos; do
      if audit_repo "$OWNER/$repo_name"; then
        compliant=$((compliant + 1))
      fi
      total=$((total + 1))
    done
    echo "=== Summary: $compliant/$total repos compliant ==="
    ;;
  *)
    echo "Unknown action: $ACTION"
    echo "Usage: $0 {audit|setup|audit-all} OWNER/REPO_OR_OWNER"
    exit 1
    ;;
esac
