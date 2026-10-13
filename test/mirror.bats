load helpers

setup() {
    setup_project
}

@test 'CLAUDE.md at the root is mirrored to AGENTS.md' {
    printf 'hola\n' >"$PROJECT/CLAUDE.md"
    run write_hook "$PROJECT/CLAUDE.md" '' mirror.sh
    [[ "$status" -eq 0 ]]
    cmp "$PROJECT/CLAUDE.md" "$PROJECT/AGENTS.md"
}

@test 'CLAUDE.md in a subdirectory is not mirrored' {
    mkdir -p "$PROJECT/repos/x"
    printf 'hola\n' >"$PROJECT/repos/x/CLAUDE.md"
    run write_hook "$PROJECT/repos/x/CLAUDE.md" '' mirror.sh
    [[ ! -e "$PROJECT/repos/x/AGENTS.md" ]]
    [[ ! -e "$PROJECT/AGENTS.md" ]]
}

@test 'custom mirror pairs replace the default' {
    write_config '{"mirror": [{"from": "a.md", "to": "b.md"}]}'
    printf 'uno\n' >"$PROJECT/a.md"
    printf 'dos\n' >"$PROJECT/CLAUDE.md"
    run write_hook "$PROJECT/a.md" '' mirror.sh
    cmp "$PROJECT/a.md" "$PROJECT/b.md"
    run write_hook "$PROJECT/CLAUDE.md" '' mirror.sh
    [[ ! -e "$PROJECT/AGENTS.md" ]]
}

@test 'empty mirror list disables it' {
    write_config '{"mirror": []}'
    printf 'hola\n' >"$PROJECT/CLAUDE.md"
    run write_hook "$PROJECT/CLAUDE.md" '' mirror.sh
    [[ ! -e "$PROJECT/AGENTS.md" ]]
}
