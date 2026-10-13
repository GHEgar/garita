#!/usr/bin/env bash

GARITA_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

garita_config_file() {
    printf '%s' "${CLAUDE_PROJECT_DIR:-$(pwd)}/.claude/garita.json"
}

garita_config() {
    local defaults="$GARITA_ROOT/defaults.json"
    local file
    file="$(garita_config_file)"

    if [[ ! -f "$file" ]]; then
        cat "$defaults"
        return
    fi

    if ! jq -s '.[0] * .[1]' "$defaults" "$file" 2>/dev/null; then
        echo "garita: $file is not valid JSON, using defaults" >&2
        cat "$defaults"
    fi
}
