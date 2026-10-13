#!/usr/bin/env bash

GARITA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

garita_context_root() {
    local project="$1" dir target fichas
    for dir in "$project" "$(git -C "$project" rev-parse --show-toplevel 2>/dev/null || true)"; do
        [[ -n "$dir" && -L "$dir/CLAUDE.md" ]] || continue
        target="$(readlink -f "$dir/CLAUDE.md")"
        fichas="$(dirname "$(dirname "$target")")"
        [[ "$(basename "$fichas")" == repos ]] || continue
        printf '%s' "$(dirname "$fichas")"
        return 0
    done
    return 1
}

garita_merge() {
    local defaults="$GARITA_ROOT/defaults.json"
    if ! jq -s '.[0] * .[1]' "$defaults" "$1" 2>/dev/null; then
        echo "garita: $1 is not valid JSON, using defaults" >&2
        cat "$defaults"
    fi
}

garita_config() {
    local project="${CLAUDE_PROJECT_DIR:-$(pwd)}"
    local own="$project/.claude/garita.json"
    local context

    if [[ -f "$own" ]]; then
        garita_merge "$own"
        return
    fi

    if context="$(garita_context_root "$project")" && [[ -f "$context/.claude/garita.json" ]]; then
        garita_merge "$context/.claude/garita.json" | jq '.mirror = []'
    fi
}
