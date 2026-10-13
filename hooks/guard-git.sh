#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/decision.sh"

input=$(cat)
trap 'if [[ "$input" == *push* ]]; then garita_fail_closed guard-git; else garita_fail_open guard-git; fi' ERR
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
[[ -n "$cmd" ]] || exit 0

config=$(garita_config)
cfg() {
    printf '%s' "$config" | jq -r "$1"
}

sep='(^|[;&|(`{]|\$\(|&&|\|\||["'"'"'][[:space:]]*)'
pre='([[:space:]]*(command|builtin|exec|env|sudo|nohup|time|nice|timeout[[:space:]]+[0-9]+[smh]?)([[:space:]]+-[^[:space:]]+)*)*([[:space:]]*[A-Za-z_]+=[^[:space:]]*)*'
gitbin='[[:space:]]*([^[:space:];&|()]*/)?git'
gitopts='([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*'
flat=$(printf '%s' "$cmd" | tr '\n' ';')

matches() {
    printf '%s' "$flat" | grep -qE "$1"
}

git_sub() {
    matches "${sep}${pre}${gitbin}${gitopts}[[:space:]]+$1([[:space:]]|[;&|)\"'\`]|\$)"
}

if git_sub push; then
    deny "$(cfg '.git.pushMessage')"
fi

if matches 'alias\.[^=[:space:]]+=[^[:space:]]*push' \
   || matches '(^|[[:space:]])gh[[:space:]]+api([[:space:]].*)?[[:space:]](-X|--method)[[:space:]]*(POST|PATCH|PUT|DELETE)([[:space:]].*)?/git/refs'; then
    deny "$(cfg '.git.refsMessage')"
fi

while IFS= read -r rule; do
    [[ -n "$rule" ]] || continue
    if matches "$(printf '%s' "$rule" | jq -r '.pattern')"; then
        deny "$(printf '%s' "$rule" | jq -r '.message')"
    fi
done < <(cfg '.git.extraDeny // [] | .[] | tojson')

attribution=$(cfg '.git.attributionPatterns // [] | join("|")')
if [[ -n "$attribution" ]] && git_sub '(commit|merge|tag|commit-tree|notes|am|cherry-pick|revert|rebase)'; then
    if printf '%s' "$flat" | grep -qiE "$attribution"; then
        deny "$(cfg '.git.attributionMessage')"
    fi
fi

if git_sub commit; then
    if [[ "$(cfg '.git.denyCommitFile')" != "false" ]] \
       && matches '[[:space:]](-F|--file)(=|[[:space:]]|$)|[[:space:]]-[A-Za-z]*F([[:space:]]|$)'; then
        deny "$(cfg '.git.commitFileMessage')"
    fi
    if [[ "$(cfg '.git.confirmCommit')" != "false" ]]; then
        ask "$(cfg '.git.confirmMessage')"
    fi
fi

exit 0
