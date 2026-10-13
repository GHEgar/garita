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

@test 'push with empty quotes inside git' { expect deny 'gi""t push'; }
@test 'push with quoted git' { expect deny '"git" push'; }
@test 'push with single quoted git' { expect deny "'git' push"; }
@test 'push with backslash' { expect deny '\git push'; }
@test 'push with quoted subcommand' { expect deny 'git "push"'; }
@test 'push with eval' { expect deny 'eval git push'; }
@test 'push with eval and quotes' { expect deny 'eval "git push"'; }
@test 'push piped into bash' { expect deny 'echo "git push" | bash'; }
@test 'push with bash here-string' { expect deny "bash <<< 'git push'"; }
@test 'push with xargs' { expect deny 'echo . | xargs git push'; }
@test 'push with find -exec' { expect deny 'find . -maxdepth 0 -exec git push \;'; }
@test 'push with watch' { expect deny 'watch git push'; }
@test 'push with shell variable' { expect deny "\"\$SHELL\" -c 'git push'"; }
@test 'push with python' { expect deny "python3 -c \"import os; os.system('git push')\""; }
@test 'push over ssh' { expect deny "ssh host 'cd repo && git push'"; }
@test 'alias with bang' { expect deny "git -c alias.p='!git push' p"; }
@test 'alias set with config' { expect deny "git config alias.p '!git push'"; }

@test 'quoted push in grep' { expect allow 'grep -n "git push" README.md'; }
@test 'quoted push in rg' { expect allow "rg 'git push' docs/"; }
@test 'quoted push in echo' { expect allow "echo 'never git push'"; }
@test 'quoted push in log grep' { expect allow 'git log --grep="git push"'; }
@test 'quoted push in a commit message asks' { expect ask 'git commit -m "docs: bloquear git push"'; }
@test 'command substitution in quotes still counts' { expect deny 'echo "$(git push)"'; }
@test 'sed keeps the conservative rule' { expect deny "sed -i 's/\"git push is/x/' f"; }
@test 'separator inside quotes is conservative' { expect deny 'echo "a;git push"'; }

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
