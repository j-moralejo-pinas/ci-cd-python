#!/usr/bin/env bash
# Apply GitHub settings that belong to a repository, not to the project template.
#
# Usage: configure_repo.sh <owner/repository> <gitflow|github_flow|trunk> [topics]

set -euo pipefail

REPO_SLUG="${1:?Repository slug is required}"
WORKFLOW="${2:?Workflow is required}"
TOPICS="${3:-}"
API=(-H "Accept: application/vnd.github+json" -H "X-GitHub-Api-Version: 2022-11-28")

case "$WORKFLOW" in
    gitflow|github_flow|trunk) ;;
    *) echo "Invalid workflow '$WORKFLOW'." >&2; exit 1 ;;
esac

gh api --method PATCH "/repos/$REPO_SLUG" "${API[@]}" --input <(jq -n \
    '{has_wiki:false, allow_auto_merge:true, allow_update_branch:true, delete_branch_on_merge:true}') >/dev/null

TOPICS_JSON=$(printf '%s' "$TOPICS" | tr ', ' '\n' | awk 'NF' | jq -R -s 'split("\n") | map(select(length > 0))')
gh api --method PUT "/repos/$REPO_SLUG/topics" "${API[@]}" \
    --input <(jq -n --argjson names "$TOPICS_JSON" '{names:$names}') >/dev/null

gh api --method PUT "/repos/$REPO_SLUG/actions/permissions/workflow" "${API[@]}" \
    --input <(jq -n '{default_workflow_permissions:"write",can_approve_pull_requests:true}') >/dev/null

delete_rulesets() {
    gh api "/repos/$REPO_SLUG/rulesets" "${API[@]}" --jq '.[].id' |
        while read -r ruleset_id; do
            [[ -z "$ruleset_id" ]] || gh api --method DELETE "/repos/$REPO_SLUG/rulesets/$ruleset_id" "${API[@]}" >/dev/null
        done
}

create_ruleset() {
    local name="$1" branch="$2" merges="$3" checks="$4"
    jq -n \
        --arg name "$name" \
        --arg branch "refs/heads/$branch" \
        --argjson merges "$merges" \
        --argjson checks "$checks" '
        {
          name: $name,
          target: "branch",
          enforcement: "active",
          conditions: {ref_name: {include: [$branch], exclude: []}},
          rules: (
            [{type: "deletion"}, {type: "non_fast_forward"}] +
            (if $merges != null then [{type: "pull_request", parameters: {
              dismiss_stale_reviews_on_push: true,
              require_code_owner_review: true,
              required_approving_review_count: 0,
              required_review_thread_resolution: true,
              require_last_push_approval: false,
              allowed_merge_methods: $merges
            }}] else [] end) +
            (if ($checks | length) > 0 then [{type: "required_status_checks", parameters: {
              do_not_enforce_on_create: false,
              required_status_checks: ($checks | map({context: .})),
              strict_required_status_checks_policy: false
            }}] else [] end)
          )
        }' |
        gh api --method POST "/repos/$REPO_SLUG/rulesets" "${API[@]}" --input - >/dev/null
}

delete_rulesets

if [[ "$WORKFLOW" == "gitflow" ]]; then
    create_ruleset Main main '["merge"]' '["call-reusable / check-source-branch","call-reusable / format","call-reusable / code-quality","call-reusable / test"]'
    create_ruleset Dev dev '["merge","squash"]' '["call-reusable / format","call-reusable / test"]'
elif [[ "$WORKFLOW" == "github_flow" ]]; then
    create_ruleset Main main '["merge","squash","rebase"]' '["call-reusable / check-source-branch","call-reusable / format","call-reusable / code-quality","call-reusable / test"]'
else
    create_ruleset Main main 'null' '[]'
fi

echo "GitHub repository settings configured for $REPO_SLUG."
