load helpers

setup() {
    setup_project
}

@test 'plain push' { expect deny 'git push'; }
@test 'push with remote and branch' { expect deny 'git push origin develop'; }
@test 'push with -C' { expect deny 'git -C ~/mua/biombo push'; }
@test 'push with -c option' { expect deny 'git -c core.pager=cat push'; }
@test 'push with command prefix' { expect deny 'command git push'; }
@test 'push with env and variable' { expect deny 'env FOO=1 git push'; }
@test 'push with variable assignment' { expect deny 'GIT_TRACE=1 git push'; }
@test 'push with sudo' { expect deny 'sudo git push'; }
@test 'push with timeout' { expect deny 'timeout 30s git push'; }
@test 'push with absolute path' { expect deny '/usr/bin/git push'; }
@test 'push after &&' { expect deny 'git add . && git push'; }
@test 'push after ;' { expect deny 'ls; git push'; }
@test 'push after pipe' { expect deny 'true | git push'; }
@test 'push in subshell' { expect deny '(git push)'; }
@test 'push in command substitution' { expect deny 'echo $(git push)'; }
@test 'push in backticks' { expect deny 'echo `git push`'; }
@test 'push in bash -c' { expect deny "bash -c 'git push'"; }
@test 'push in bash -c with double quotes' { expect deny 'bash -c "git push --force"'; }
@test 'push on a second line' { expect deny $'git status\ngit push'; }
@test 'push at end of a group' { expect deny '{ git push; }'; }
@test 'alias to push' { expect deny 'git -c alias.p=push p'; }
@test 'gh api writing refs' { expect deny 'gh api -X POST repos/o/r/git/refs -f ref=refs/heads/x'; }
@test 'gh api patching refs' { expect deny 'gh api --method PATCH repos/o/r/git/refs/heads/x'; }

@test 'known false positive: push quoted as an argument' { expect deny 'grep -n "git push" README.md'; }

@test 'status' { expect allow 'git status'; }
@test 'log' { expect allow 'git log --oneline -5'; }
@test 'stash push' { expect allow 'git stash push -m wip'; }
@test 'word push in echo' { expect allow 'echo pushing'; }
@test 'npm script named push' { expect allow 'npm run push'; }
@test 'gh api read refs' { expect allow 'gh api repos/o/r/git/refs'; }

@test 'commit asks' { expect ask 'git commit -m "feat: x"'; }
@test 'commit with -C asks' { expect ask 'git -C ~/mua/biombo commit -m "fix: y"'; }
@test 'commit with co-authored-by' { expect deny 'git commit -m "feat: x" -m "Co-Authored-By: Claude <noreply@anthropic.com>"'; }
@test 'commit with generated with' { expect deny 'git commit -m "feat: x Generated with Claude Code"'; }
@test 'commit with robot' { expect deny 'git commit -m "feat: x 🤖"'; }
@test 'tag with attribution' { expect deny 'git tag -a v1 -m "Co-Authored-By: x"'; }
@test 'merge with attribution' { expect deny 'git merge develop -m "Generated with x"'; }
@test 'commit with -F' { expect deny 'git commit -F msg.txt'; }
@test 'commit with --file' { expect deny 'git commit --file=msg.txt'; }
@test 'commit with combined -aF' { expect deny 'git commit -aF msg.txt'; }
@test 'attribution outside a commit is allowed' { expect allow 'echo "Co-Authored-By: x"'; }
