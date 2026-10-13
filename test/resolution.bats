load helpers
bats_require_minimum_version 1.5.0

setup() {
    CONTEXT="$BATS_TEST_TMPDIR/context"
    CODE="$BATS_TEST_TMPDIR/code"
    mkdir -p "$CONTEXT/.claude" "$CONTEXT/repos/code"
    printf '# code\n' >"$CONTEXT/repos/code/CLAUDE.md"
    printf '%s' '{"git": {"pushMessage": "desde el contexto"}, "content": [{"files": ["*.yml"], "pattern": "x", "message": "sin x"}]}' >"$CONTEXT/.claude/garita.json"
    git init -q "$CODE"
    ln -s "$CONTEXT/repos/code/CLAUDE.md" "$CODE/CLAUDE.md"
    ln -s "$CONTEXT/repos/code/CLAUDE.md" "$CODE/AGENTS.md"
    export CLAUDE_PROJECT_DIR="$CODE"
}

@test 'without any config garita does nothing' {
    export CLAUDE_PROJECT_DIR="$BATS_TEST_TMPDIR/other"
    mkdir -p "$CLAUDE_PROJECT_DIR"
    run git_hook 'git push'
    [[ "$status" -eq 0 ]]
    [[ -z "$output" ]]
    printf 'hola\n' >"$CLAUDE_PROJECT_DIR/CLAUDE.md"
    run write_hook "$CLAUDE_PROJECT_DIR/CLAUDE.md" '' mirror.sh
    [[ ! -e "$CLAUDE_PROJECT_DIR/AGENTS.md" ]]
}

@test 'a linked ficha inherits the context config' {
    run git_hook 'git push'
    [[ "$(decision)" == deny ]]
    [[ "$(reason)" == 'desde el contexto' ]]
}

@test 'inherited content rules apply in the code repo' {
    run write_hook "$CODE/a.yml" 'x' guard-content.sh
    [[ "$(decision)" == deny ]]
}

@test 'inherited config does not mirror' {
    run --separate-stderr write_hook "$CODE/CLAUDE.md" '' mirror.sh
    [[ "$status" -eq 0 ]]
    [[ -z "$stderr" ]]
    [[ -L "$CODE/AGENTS.md" ]]
}

@test 'a session opened in a subdirectory finds the ficha through git' {
    mkdir -p "$CODE/src/deep"
    export CLAUDE_PROJECT_DIR="$CODE/src/deep"
    run git_hook 'git push'
    [[ "$(reason)" == 'desde el contexto' ]]
}

@test 'own config wins over the context' {
    mkdir -p "$CODE/.claude"
    printf '%s' '{"git": {"pushMessage": "propio"}}' >"$CODE/.claude/garita.json"
    run git_hook 'git push'
    [[ "$(reason)" == 'propio' ]]
}

@test 'a link outside a repos directory is ignored' {
    rm "$CODE/CLAUDE.md"
    mkdir -p "$BATS_TEST_TMPDIR/loose"
    printf '# x\n' >"$BATS_TEST_TMPDIR/loose/CLAUDE.md"
    ln -s "$BATS_TEST_TMPDIR/loose/CLAUDE.md" "$CODE/CLAUDE.md"
    run git_hook 'git push'
    [[ -z "$output" ]]
}

@test 'a context without garita.json is ignored' {
    rm "$CONTEXT/.claude/garita.json"
    run git_hook 'git push'
    [[ -z "$output" ]]
}
