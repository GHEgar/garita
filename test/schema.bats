load helpers

SCHEMA="$BATS_TEST_DIRNAME/../schema/garita.schema.json"

validate() {
    jq -rn --slurpfile s "$SCHEMA" --slurpfile v "$1" '[$s[0], $v[0]]' | jq -r -f "$BATS_TEST_DIRNAME/schema.jq"
}

@test 'defaults match the schema' {
    run validate "$ROOT/defaults.json"
    [[ "$status" -eq 0 ]]
    [[ -z "$output" ]]
}

@test 'consumer configs match the schema' {
    for config in "$HOME/mua/ideas-mua/.claude/garita.json" "$HOME/mua/ideas-IIEG/.claude/garita.json"; do
        [[ -f "$config" ]] || skip "$config not present"
        run validate "$config"
        [[ -z "$output" ]] || { echo "$config: $output" >&2; return 1; }
    done
}

@test 'unknown keys are reported' {
    printf '%s' '{"git": {"pushMesage": "x"}, "mirorr": []}' >"$BATS_TEST_TMPDIR/bad.json"
    run validate "$BATS_TEST_TMPDIR/bad.json"
    [[ "$output" == *'unknown key pushMesage'* ]]
    [[ "$output" == *'unknown key mirorr'* ]]
}

@test 'wrong types and missing fields are reported' {
    printf '%s' '{"git": {"confirmCommit": "no", "extraDeny": [{"pattern": "x"}]}, "content": [{"files": [], "pattern": "a", "message": "b"}]}' >"$BATS_TEST_TMPDIR/bad.json"
    run validate "$BATS_TEST_TMPDIR/bad.json"
    [[ "$output" == *'confirmCommit: expected boolean'* ]]
    [[ "$output" == *'extraDeny[0]: missing message'* ]]
    [[ "$output" == *'files: too few items'* ]]
}
