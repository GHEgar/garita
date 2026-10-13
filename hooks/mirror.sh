#!/usr/bin/env bash
set -Eeuo pipefail

source "$(dirname "${BASH_SOURCE[0]}")/../lib/config.sh"
source "$(dirname "${BASH_SOURCE[0]}")/../lib/decision.sh"

input=$(cat)
trap 'garita_fail_open mirror' ERR
path=$(printf '%s' "$input" | jq -r '.tool_input.file_path // ""' 2>/dev/null || true)
[[ -n "$path" ]] || exit 0

root="${CLAUDE_PROJECT_DIR:-$(pwd)}"
config=$(garita_config)
[[ -n "$config" ]] || exit 0

while IFS=$'\t' read -r from to; do
    [[ -n "$from" && -n "$to" ]] || continue
    if [[ "$path" == "$root/$from" && -f "$root/$from" ]]; then
        cp "$root/$from" "$root/$to"
        echo "$to synced from $from" >&2
    fi
done < <(printf '%s' "$config" | jq -r '.mirror // [] | .[] | [.from, .to] | @tsv')

exit 0
