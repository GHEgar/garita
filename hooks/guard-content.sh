#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/decision.sh"

input=$(cat)
trap 'garita_fail_open guard-content' ERR
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null || true)
[[ -n "$path" ]] || exit 0

config=$(garita_config)
[[ "$(printf '%s' "$config" | jq '.content // [] | length')" -gt 0 ]] || exit 0

project="${CLAUDE_PROJECT_DIR:-$(pwd)}"
base=$(basename "$path")
relative="${path#"$project"/}"

file_matches() {
    local glob
    while IFS= read -r glob; do
        if [[ "$glob" == */* ]]; then
            [[ "$relative" == $glob ]] && return 0
        else
            [[ "$base" == $glob ]] && return 0
        fi
    done < <(printf '%s' "$1" | jq -r '.files // [] | .[]')
    return 1
}

payload=$(printf '%s' "$input" | jq -r '[.tool_input.content // "", .tool_input.new_string // "", (.tool_input.edits // [] | map(.new_string) | join("\n"))] | join("\n")')

while IFS= read -r rule; do
    file_matches "$rule" || continue
    if printf '%s' "$payload" | grep -qE "$(printf '%s' "$rule" | jq -r '.pattern')"; then
        deny "$(printf '%s' "$rule" | jq -r '.message')"
    fi
done < <(printf '%s' "$config" | jq -c '.content[]')

exit 0
