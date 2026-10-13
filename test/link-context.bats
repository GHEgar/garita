load helpers

setup() {
    CONTEXT="$BATS_TEST_TMPDIR/context"
    PROJECTS="$BATS_TEST_TMPDIR/projects"
    mkdir -p "$CONTEXT/repos/a" "$CONTEXT/repos/b" "$CONTEXT/repos/c" "$CONTEXT/repos/missing"
    for r in a b c missing; do printf '# %s\n' "$r" >"$CONTEXT/repos/$r/CLAUDE.md"; done
    touch "$CONTEXT/repos/b/.nolink"
    for r in a b c; do git init -q "$PROJECTS/$r"; done
    printf 'real\n' >"$PROJECTS/c/CLAUDE.md"
}

link() {
    "$ROOT/bin/link-context.sh" "$CONTEXT" "$PROJECTS"
}

@test 'links CLAUDE.md and AGENTS.md to the ficha' {
    run link
    [[ "$status" -eq 0 ]]
    [[ "$(readlink "$PROJECTS/a/CLAUDE.md")" == "$CONTEXT/repos/a/CLAUDE.md" ]]
    [[ "$(readlink "$PROJECTS/a/AGENTS.md")" == "$CONTEXT/repos/a/CLAUDE.md" ]]
}

@test 'excludes the links via .git/info/exclude' {
    run link
    grep -qxF /CLAUDE.md "$PROJECTS/a/.git/info/exclude"
    grep -qxF /AGENTS.md "$PROJECTS/a/.git/info/exclude"
}

@test 'respects .nolink' {
    run link
    [[ "$output" == *'b: marked .nolink'* ]]
    [[ ! -e "$PROJECTS/b/CLAUDE.md" ]]
}

@test 'does not overwrite real files' {
    run link
    [[ ! -L "$PROJECTS/c/CLAUDE.md" ]]
    [[ "$(cat "$PROJECTS/c/CLAUDE.md")" == real ]]
}

@test 'skips fichas without a repo' {
    run link
    [[ "$output" == *'missing: not found'* ]]
}

@test 'is idempotent' {
    link
    link
    [[ "$(grep -c CLAUDE.md "$PROJECTS/a/.git/info/exclude")" -eq 1 ]]
    [[ -L "$PROJECTS/a/CLAUDE.md" ]]
}

@test 'requires two arguments' {
    run "$ROOT/bin/link-context.sh" "$CONTEXT"
    [[ "$status" -eq 2 ]]
}
