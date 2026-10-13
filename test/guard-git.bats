load helpers
bats_require_minimum_version 1.5.0

setup() {
    setup_project
}

@test 'default push message' {
    run git_hook 'git push'
    [[ "$(reason)" == 'git push is blocked. The user pushes manually.' ]]
}

@test 'custom push message' {
    write_config '{"git": {"pushMessage": "Push prohibido en mua."}}'
    run git_hook 'git push'
    [[ "$(reason)" == 'Push prohibido en mua.' ]]
}

@test 'extra deny rule' {
    write_config '{"git": {"extraDeny": [{"pattern": "ecosystem-push(\\.sh)?", "message": "Lo corre el usuario."}]}}'
    run git_hook 'make ecosystem-push'
    [[ "$(decision)" == deny ]]
    [[ "$(reason)" == 'Lo corre el usuario.' ]]
    run git_hook './scripts/ecosystem-push.sh'
    [[ "$(decision)" == deny ]]
    run git_hook 'make build'
    [[ "$(decision)" == allow ]]
}

@test 'extra deny keeps the defaults' {
    write_config '{"git": {"extraDeny": [{"pattern": "rm -rf /", "message": "no"}]}}'
    run git_hook 'git push'
    [[ "$(decision)" == deny ]]
}

@test 'custom attribution patterns replace the defaults' {
    write_config '{"git": {"attributionPatterns": ["made by bot"]}}'
    run git_hook 'git commit -m "feat: x made by bot"'
    [[ "$(decision)" == deny ]]
    run git_hook 'git commit -m "feat: x Co-Authored-By: y"'
    [[ "$(decision)" == ask ]]
}

@test 'empty attribution patterns disable the check' {
    write_config '{"git": {"attributionPatterns": []}}'
    run git_hook 'git commit -m "Co-Authored-By: y"'
    [[ "$(decision)" == ask ]]
}

@test 'confirmCommit false lets commits through' {
    write_config '{"git": {"confirmCommit": false}}'
    run git_hook 'git commit -m "feat: x"'
    [[ "$(decision)" == allow ]]
}

@test 'custom confirm message' {
    write_config '{"git": {"confirmMessage": "Confirma repo y rama."}}'
    run git_hook 'git commit -m "feat: x"'
    [[ "$(reason)" == 'Confirma repo y rama.' ]]
}

@test 'denyCommitFile false asks instead' {
    write_config '{"git": {"denyCommitFile": false}}'
    run git_hook 'git commit -F msg.txt'
    [[ "$(decision)" == ask ]]
}

@test 'invalid config falls back to defaults and still blocks push' {
    write_config '{not json'
    run --separate-stderr git_hook 'git push'
    [[ "$status" -eq 0 ]]
    [[ "$(decision)" == deny ]]
    [[ "$stderr" == *'not valid JSON'* ]]
}

@test 'invalid hook input mentioning push fails closed' {
    run "$ROOT/hooks/guard-git.sh" <<<'{broken git push'
    [[ "$status" -eq 2 ]]
}

@test 'invalid hook input without push fails open' {
    run "$ROOT/hooks/guard-git.sh" <<<'{broken git status'
    [[ "$status" -eq 0 ]]
}
