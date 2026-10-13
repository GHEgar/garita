load helpers

COMPOSE_RULE='{"content": [{"files": ["docker-compose*.y*ml", "compose*.y*ml"], "pattern": "\\$\\{[A-Za-z_][A-Za-z0-9_]*:?-", "message": "Sin defaults inline."}]}'

setup() {
    setup_project
}

@test 'no rules by default' {
    run write_hook "$PROJECT/docker-compose.yml" 'image: ${TAG:-latest}' guard-content.sh
    [[ "$(decision)" == allow ]]
}

@test 'compose rule denies inline defaults' {
    write_config "$COMPOSE_RULE"
    run write_hook "$PROJECT/docker-compose.yml" 'image: ${TAG:-latest}' guard-content.sh
    [[ "$(decision)" == deny ]]
    [[ "$(reason)" == 'Sin defaults inline.' ]]
}

@test 'compose rule matches yaml and compose names' {
    write_config "$COMPOSE_RULE"
    run write_hook "$PROJECT/svc/compose.prod.yaml" 'image: ${TAG-latest}' guard-content.sh
    [[ "$(decision)" == deny ]]
}

@test 'compose rule allows plain variables' {
    write_config "$COMPOSE_RULE"
    run write_hook "$PROJECT/docker-compose.yml" 'image: ${TAG}' guard-content.sh
    [[ "$(decision)" == allow ]]
}

@test 'compose rule ignores other files' {
    write_config "$COMPOSE_RULE"
    run write_hook "$PROJECT/run.sh" 'echo ${TAG:-latest}' guard-content.sh
    [[ "$(decision)" == allow ]]
}

@test 'edit payload is checked' {
    write_config "$COMPOSE_RULE"
    run bash -c "jq -n --arg p '$PROJECT/compose.yml' '{tool_input: {file_path: \$p, old_string: \"a\", new_string: \"x: \${A:-1}\"}}' | '$ROOT/hooks/guard-content.sh'"
    [[ "$(decision)" == deny ]]
}

@test 'multiedit payload is checked' {
    write_config "$COMPOSE_RULE"
    run bash -c "jq -n --arg p '$PROJECT/compose.yml' '{tool_input: {file_path: \$p, edits: [{old_string: \"a\", new_string: \"ok\"}, {old_string: \"b\", new_string: \"x: \${A:-1}\"}]}}' | '$ROOT/hooks/guard-content.sh'"
    [[ "$(decision)" == deny ]]
}

@test 'globs with a slash match the path relative to the project' {
    write_config '{"content": [{"files": ["docs/*.md"], "pattern": "TODO", "message": "Sin TODO."}]}'
    run write_hook "$PROJECT/docs/a.md" 'TODO: x' guard-content.sh
    [[ "$(decision)" == deny ]]
    run write_hook "$PROJECT/a.md" 'TODO: x' guard-content.sh
    [[ "$(decision)" == allow ]]
}
