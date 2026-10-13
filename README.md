# garita

A Claude Code plugin that guards agent context repositories:

- **Blocks `git push`** and its usual evasions: command prefixes (`command`, `env`, `sudo`,
  `timeout`…), absolute paths to `git`, global options (`git -C dir push`), subshells, `bash -c`,
  multi-line commands, `alias.x=push` and `gh api` writes to `/git/refs`.
- **Rejects agent attributions** (`Co-Authored-By`, `Generated with`, 🤖…) in commit, merge, tag,
  rebase and friends.
- **Asks for confirmation** before every `git commit`, and denies `-F/--file` so the message can be
  reviewed.
- **Content rules**: deny writes whose content matches a regex in files that match a glob.
- **Mirrors files** after an edit, by default `CLAUDE.md` → `AGENTS.md` at the project root.
- **Links context fichas**: `bin/link-context.sh` symlinks `repos/<name>/CLAUDE.md` from a context repo
  into each code repo as `CLAUDE.md` and `AGENTS.md`, excluded via `.git/info/exclude`. A `.nolink`
  file next to a ficha skips it.

Every message and pattern is configurable per project.

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

To try it without installing: `claude --plugin-dir /path/to/garita`.

## Configuration

`.claude/garita.json` in the project, merged over [`defaults.json`](defaults.json). Objects merge
recursively; lists replace the defaults.

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

- `git push` quoted as an argument right after a quote, as in `grep "git push" file`, is blocked too:
  the same rule catches `bash -c 'git push'`.
- Hooks only run in sessions where the plugin is enabled. Enabled at project scope, they do not reach
  sessions opened directly in another repository.

## Linking fichas

```bash
bin/link-context.sh <context-dir> <projects-dir>
```

Idempotent. Existing real files are never overwritten.

## Development

```bash
bats test/
shellcheck hooks/*.sh bin/*.sh lib/*.sh
claude plugin validate .
```

## License

AGPL-3.0-only.
