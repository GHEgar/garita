#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: link-context.sh <context-dir> <projects-dir>" >&2
    exit 2
fi

CONTEXT_DIR="$(cd "$1" && pwd)"
PROJECTS_DIR="$(cd "$2" && pwd)"

link_one() {
    local repo="$1" name="$2" target="$3" dest="$4"

    if [[ -L "$dest" ]]; then
        ln -sfn "$target" "$dest"
        echo "  ~ $name (updated)"
        return
    fi

    if [[ -e "$dest" ]]; then
        if git -C "$repo" ls-files --error-unmatch "$name" >/dev/null 2>&1; then
            echo "  ! $name exists and is TRACKED in the repo, skipped, check it by hand"
        else
            echo "  ! $name exists as an untracked real file, skipped"
        fi
        return
    fi

    ln -s "$target" "$dest"
    echo "  + $name"
}

exclude_one() {
    local repo="$1" name="$2"
    local ex="$repo/.git/info/exclude"
    [[ -d "$repo/.git" ]] || return 0
    mkdir -p "$(dirname "$ex")"
    touch "$ex"
    grep -qxF "/$name" "$ex" || printf '%s\n' "/$name" >>"$ex"
}

for dir in "$CONTEXT_DIR"/repos/*/; do
    [[ -d "$dir" ]] || continue
    name="$(basename "$dir")"
    repo="$PROJECTS_DIR/$name"

    [[ -d "$repo" ]] || { echo "$name: not found in $PROJECTS_DIR, skipped"; continue; }
    [[ -f "$dir/CLAUDE.md" ]] || { echo "$name: no CLAUDE.md in the context, skipped"; continue; }
    [[ -f "$dir/.nolink" ]] && { echo "$name: marked .nolink, not linked"; continue; }

    echo "$name"
    target="$CONTEXT_DIR/repos/$name/CLAUDE.md"
    link_one "$repo" "CLAUDE.md" "$target" "$repo/CLAUDE.md"
    link_one "$repo" "AGENTS.md" "$target" "$repo/AGENTS.md"
    exclude_one "$repo" "CLAUDE.md"
    exclude_one "$repo" "AGENTS.md"
done

echo
echo "Done. The symlinks point to $CONTEXT_DIR and are excluded via .git/info/exclude."
