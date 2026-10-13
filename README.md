# garita

A Claude Code plugin that guards agent context repositories:

- **Blocks `git push`** and its usual evasions: command prefixes (`command`, `env`, `sudo`,
  `timeout`…), absolute paths to `git`, global options (`git -C dir push`), subshells, `bash -c`,
  multi-line commands, quote and backslash tricks (`gi""t push`, `\git push`), `eval`, `xargs`,
  `find -exec`, `watch`, aliases that run push and `gh api` writes to `/git/refs`.
- **Rejects agent attributions** (`Co-Authored-By`, `Generated with`, 🤖…) in commit, merge, tag,
  rebase and friends.
- **Asks for confirmation** before every `git commit`, and denies `-F/--file` so the message can be
  reviewed.
- **Content rules**: deny writes whose content matches a regex in files that match a glob.
- **Mirrors files** after an edit, by default `CLAUDE.md` → `AGENTS.md` at the project root.
- **Links context fichas**: `bin/link-context.sh` symlinks `repos/<name>/CLAUDE.md` from a context repo
  into each code repo as `CLAUDE.md` and `AGENTS.md`, excluded via `.git/info/exclude`. A `.nolink`
  file next to a ficha skips it.

Every message and pattern is configurable per project. Without a config, garita does nothing, so it is
safe to enable for every session.

## Requirements

`bash` and `jq`.

## Install

The repository is its own marketplace. In the consuming project's `.claude/settings.json`:

```json
{
    "extraKnownMarketplaces": {
        "garita": { "source": { "source": "directory", "path": "/path/to/garita" } }
    },
    "enabledPlugins": { "garita@garita": true }
}
```

Keep a `permissions.deny` entry for `Bash(git push:*)` as well: a plugin cannot set permissions.

To cover every session, including code repositories without their own settings, enable it at user
scope as well:

```bash
claude plugin marketplace add /path/to/garita
claude plugin install garita@garita --scope user
```

To try it without installing: `claude --plugin-dir /path/to/garita`.

## Configuration

garita looks for its config in this order and stops at the first one found:

1. `.claude/garita.json` in the project.
2. The context repo the project's `CLAUDE.md` links to: when `CLAUDE.md` (in the project or its git
   top level) is a symlink to `<context>/repos/<name>/CLAUDE.md`, garita uses
   `<context>/.claude/garita.json`, with `mirror` turned off.
3. Nothing: every hook exits without a decision.

The config is merged over [`defaults.json`](defaults.json). Objects merge recursively; lists replace
the defaults. An empty `{}` turns on the defaults.

```json
{
    "git": {
        "pushMessage": "Push is done by the user.",
        "refsMessage": "Writing remote refs is a push.",
        "extraDeny": [{ "pattern": "deploy-prod", "message": "The user deploys." }],
        "attributionPatterns": ["co-authored-by:", "generated with"],
        "attributionMessage": "No agent attributions.",
        "confirmCommit": true,
        "confirmMessage": "Check repository, branch and message.",
        "denyCommitFile": true,
        "commitFileMessage": "Use git commit -m."
    },
    "content": [
        {
            "files": ["docker-compose*.y*ml", "compose*.y*ml"],
            "pattern": "\\$\\{[A-Za-z_][A-Za-z0-9_]*:?-",
            "message": "No inline ${VAR:-default} in compose files."
        }
    ],
    "mirror": [{ "from": "CLAUDE.md", "to": "AGENTS.md" }]
}
```

Patterns are extended regular expressions (`grep -E`); attribution patterns are case-insensitive.
Globs without a `/` match the file name; globs with a `/` match the path relative to the project.

## Failure behavior

If a hook fails (missing `jq`, broken input), it warns on stderr and lets the tool call through, except
`guard-git` on a command that mentions `push`, which blocks it.

## Known limitations

- Quoted text only counts as a command when the command line contains something that can execute a
  string (`bash`, `eval`, `ssh`, `xargs`, `find`, `sed`, `python`, a `$VAR` as command…). Then any
  quoted `git push` is blocked, even inside a harmless argument. Without such a word, `grep "git push"`
  or a commit message that mentions it passes.
- A separator inside quotes (`echo "a;git push"`) is treated as a real one.
- Enabled only at project scope, the hooks do not reach sessions opened directly in a code repository.
  Enable it at user scope for that.

## opencode

[`opencode/garita.js`](opencode/garita.js) is an opencode plugin that runs the same hooks with the same
config resolution: it blocks what `guard-git` and `guard-content` deny and mirrors files after a write.
An opencode plugin cannot ask, so commit confirmation comes from opencode's own permissions.

```bash
ln -s /path/to/garita/opencode/garita.js ~/.config/opencode/plugins/garita.js
```

```json
{
    "permission": {
        "bash": { "git commit *": "ask" }
    }
}
```

## Linking fichas

```bash
bin/link-context.sh <context-dir> <projects-dir>
```

Idempotent. Existing real files are never overwritten.

## Development

```bash
bats test/
bun test test/opencode.test.js
shellcheck hooks/*.sh bin/*.sh lib/*.sh
claude plugin validate .
```

## License

AGPL-3.0-only.
