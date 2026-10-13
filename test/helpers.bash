ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"

setup_project() {
    PROJECT="$BATS_TEST_TMPDIR/project"
    mkdir -p "$PROJECT/.claude"
    export CLAUDE_PROJECT_DIR="$PROJECT"
}

write_config() {
    printf '%s' "$1" >"$PROJECT/.claude/garita.json"
}

git_hook() {
    jq -n --arg c "$1" '{tool_input: {command: $c}}' | "${GUARD_GIT:-$ROOT/hooks/guard-git.sh}"
}

write_hook() {
    jq -n --arg p "$1" --arg c "$2" '{tool_input: {file_path: $p, content: $c}}' | "$ROOT/hooks/$3"
}

decision() {
    if [[ -z "$output" ]]; then
        echo allow
    else
        printf '%s' "$output" | jq -r '.hookSpecificOutput.permissionDecision'
    fi
}

reason() {
    printf '%s' "$output" | jq -r '.hookSpecificOutput.permissionDecisionReason'
}

expect() {
    run git_hook "$2"
    [[ "$status" -eq 0 ]]
    local got
    got="$(decision)"
    if [[ "$got" != "$1" ]]; then
        echo "expected $1, got $got for: $2" >&2
        return 1
    fi
}
