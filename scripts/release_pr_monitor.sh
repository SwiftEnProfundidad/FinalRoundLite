#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SMOKE_DIR="$ROOT_DIR/build/smoke"
SUMMARY_FILE="$SMOKE_DIR/release_pr_monitor.txt"
PR_NUMBER="${1:-3}"
RUN_AT_UTC="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

mkdir -p "$SMOKE_DIR"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI no disponible en el entorno." >&2
  exit 1
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "ERROR: gh CLI no autenticado. Ejecuta 'gh auth login'." >&2
  exit 1
fi

state="$(gh pr view "$PR_NUMBER" --json state --jq '.state')"
merge_state_status="$(gh pr view "$PR_NUMBER" --json mergeStateStatus --jq '.mergeStateStatus')"
review_decision="$(gh pr view "$PR_NUMBER" --json reviewDecision --jq '.reviewDecision // ""')"
url="$(gh pr view "$PR_NUMBER" --json url --jq '.url')"
base_ref="$(gh pr view "$PR_NUMBER" --json baseRefName --jq '.baseRefName')"
head_ref="$(gh pr view "$PR_NUMBER" --json headRefName --jq '.headRefName')"
comments_count="$(gh pr view "$PR_NUMBER" --json comments --jq '.comments | length')"
reviews_count="$(gh pr view "$PR_NUMBER" --json reviews --jq '.reviews | length')"
changes_requested_count="$(gh pr view "$PR_NUMBER" --json reviews --jq '[.reviews[] | select(.state == "CHANGES_REQUESTED")] | length')"
checks_count="$(gh pr view "$PR_NUMBER" --json statusCheckRollup --jq '.statusCheckRollup | length')"
checks_not_green_count="$(gh pr view "$PR_NUMBER" --json statusCheckRollup --jq '[.statusCheckRollup[] | select((.conclusion // "") != "SUCCESS" and (.conclusion // "") != "SKIPPED")] | length')"

action_required="false"
action_reason="none"

if [[ "$state" != "OPEN" ]]; then
  action_required="true"
  action_reason="pr_not_open"
elif [[ "$merge_state_status" != "CLEAN" ]]; then
  action_required="true"
  action_reason="merge_state_not_clean"
elif [[ "$changes_requested_count" -gt 0 ]]; then
  action_required="true"
  action_reason="changes_requested"
elif [[ "$checks_not_green_count" -gt 0 ]]; then
  action_required="true"
  action_reason="checks_not_green"
fi

{
  echo "release_pr_monitor=OK"
  echo "run_at_utc=$RUN_AT_UTC"
  echo "pr_number=$PR_NUMBER"
  echo "pr_url=$url"
  echo "state=$state"
  echo "merge_state_status=$merge_state_status"
  echo "review_decision=$review_decision"
  echo "base_ref=$base_ref"
  echo "head_ref=$head_ref"
  echo "checks_count=$checks_count"
  echo "checks_not_green_count=$checks_not_green_count"
  echo "comments_count=$comments_count"
  echo "reviews_count=$reviews_count"
  echo "changes_requested_count=$changes_requested_count"
  echo "action_required=$action_required"
  echo "action_reason=$action_reason"
  echo "monitor_command=bash scripts/release_pr_monitor.sh $PR_NUMBER"
} >"$SUMMARY_FILE"

echo "RELEASE_PR_MONITOR_OK"
echo " - summary: $SUMMARY_FILE"
echo " - pr: $url"
echo " - state: $state"
echo " - merge_state_status: $merge_state_status"
echo " - action_required: $action_required ($action_reason)"
