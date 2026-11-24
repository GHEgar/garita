load helpers
bats_require_minimum_version 1.5.0

setup() {
    setup_project
    export GARITA_STATE_DIR="$BATS_TEST_TMPDIR/state"
    write_config '{"git": {"push": "ask"}}'
}

@test 'push asks in ask mode' {
    expect ask 'git push'
    expect ask 'git push origin develop'
    expect ask 'git -C repo push -u origin production'
    expect ask 'git push --follow-tags'
    run git_hook 'git push'
    [[ "$(reason)" == 'Confirm the push: check repository, branch and remote.' ]]
}

@test 'force push is always denied' {
    expect deny 'git push --force'
    expect deny 'git push -f origin main'
    expect deny 'git push -uf origin main'
    expect deny 'git push --force-with-lease'
    expect deny 'git push --force-if-includes'
    expect deny 'git push --mirror'
    expect deny 'git push origin +main'
    expect deny 'git push origin +HEAD:main'
    run git_hook 'git push --force'
    [[ "$(reason)" == 'Force push is blocked.' ]]
}

@test 'force push is denied through evasions' {
    expect deny 'bash -c "git push -f"'
    expect deny 'gi""t push --force'
}

@test 'delete needs two confirmations' {
    run git_hook 'git push origin --delete feature'
    [[ "$(decision)" == deny ]]
    [[ "$(reason)" == *'two confirmations'* ]]
    run git_hook 'git push origin --delete feature'
    [[ "$(decision)" == ask ]]
    [[ "$(reason)" == 'Second confirmation: this deletes refs on the remote.' ]]
    run git_hook 'git push origin --delete feature'
    [[ "$(decision)" == deny ]]
}

@test 'every delete form needs two confirmations' {
    for c in 'git push origin :feature' 'git push -d origin feature' 'git push --prune origin'; do
        expect deny "$c"
        expect ask "$c"
    done
}

@test 'the second confirmation is per command' {
    expect deny 'git push origin --delete a'
    expect deny 'git push origin --delete b'
    expect ask 'git push origin --delete a'
}

@test 'a stale first confirmation starts over' {
    expect deny 'git push origin --delete a'
    touch -d '20 minutes ago' "$GARITA_STATE_DIR"/*
    expect deny 'git push origin --delete a'
}

@test 'commit and push ask together' {
    run git_hook 'git commit -m "feat: x" && git push'
    [[ "$(decision)" == ask ]]
    [[ "$(reason)" == *'Confirm the commit'*'Confirm the push'* ]]
}

@test 'attributions are still denied next to a push' {
    expect deny 'git commit -m "feat: x Co-Authored-By: y" && git push'
}

@test 'refs writes and push aliases stay denied' {
    expect deny 'gh api -X POST repos/o/r/git/refs -f ref=x'
    expect deny 'git config alias.p push'
}

@test 'deny mode ignores force and delete details' {
    write_config '{"git": {"push": "deny", "pushMessage": "no"}}'
    run git_hook 'git push --force'
    [[ "$(reason)" == no ]]
    run git_hook 'git push origin --delete x'
    [[ "$(reason)" == no ]]
}

@test 'extra ask rule' {
    write_config '{"git": {"extraAsk": [{"pattern": "make[[:space:]]+deploy", "message": "Confirma el deploy."}]}}'
    run git_hook 'make deploy'
    [[ "$(decision)" == ask ]]
    [[ "$(reason)" == 'Confirma el deploy.' ]]
    expect allow 'make build'
}

@test 'unrelated flags elsewhere do not count as force' {
    expect ask 'rm -f x.tmp; git push'
}
