#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/decision.sh"

input=$(cat)
trap 'if [[ "$input" == *push* ]]; then garita_fail_closed guard-git; else garita_fail_open guard-git; fi' ERR
cmd=$(printf '%s' "$input" | jq -r '.tool_input.command // ""')
[[ -n "$cmd" ]] || exit 0

config=$(garita_config)
[[ -n "$config" ]] || exit 0
cfg() {
    printf '%s' "$config" | jq -r "$1"
}

strict='(^|[;&|(`{]|\$\(|&&|\|\||-exec(dir)?[[:space:]]|-ok[[:space:]])'
quoted='(^|[;&|(`{]|\$\(|&&|\|\||-exec(dir)?[[:space:]]|-ok[[:space:]]|["'"'"'][[:space:]]*)'
pre='([[:space:]]*(command|builtin|exec|eval|env|sudo|doas|nohup|time|nice|setsid|stdbuf|chronic|watch|xargs|timeout[[:space:]]+[0-9]+[smh]?)([[:space:]]+-[^[:space:]]+)*)*([[:space:]]*[A-Za-z_]+=[^[:space:]]*)*'
gitbin='[[:space:]]*([^[:space:];&|()]*/)?git'
gitopts='([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*'
executors='(^|[^[:alnum:]_.-])(bash|sh|zsh|dash|ksh|fish|eval|exec|source|ssh|su|sudo|doas|env|xargs|watch|nohup|timeout|nice|setsid|stdbuf|parallel|script|find|sed|awk|gawk|perl|ruby|python[0-9.]*|node|deno|bun|npx|npm|tclsh)([^[:alnum:]_.-]|$)|\$[[:alpha:]_{]'
flat=$(printf '%s' "$cmd" | tr '\n' ';')
plain=$(printf '%s' "$flat" | tr -d "\"'\\\\")

matches() {
    printf '%s' "$flat" | grep -qE "$1"
}

sep="$strict"
if matches "$executors"; then
    sep="$quoted"
fi

git_sub() {
    local tail="${pre}${gitbin}${gitopts}[[:space:]]+$1([[:space:]]|[;&|)\"'\`]|\$)"
    matches "${sep}${tail}" || printf '%s' "$plain" | grep -qE "${strict}${tail}"
}

if git_sub push; then
    deny "$(cfg '.git.pushMessage')"
fi

if matches 'alias\.[^=[:space:]]+([[:space:]]+|=)[^;&|]*push' \
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
