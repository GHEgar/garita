#!/usr/bin/env bash

garita_decide() {
    jq -n --arg d "$1" --arg r "$2" '{
        hookSpecificOutput: {
            hookEventName: "PreToolUse",
            permissionDecision: $d,
            permissionDecisionReason: $r
        }
    }'
    exit 0
}

deny() {
    garita_decide deny "$1"
}

ask() {
    garita_decide ask "$1"
}

garita_fail_open() {
    echo "garita: $1 failed, letting the tool call through" >&2
    exit 0
}

garita_fail_closed() {
    echo "garita: $1 failed on a command that mentions push, blocking it" >&2
    exit 2
}
