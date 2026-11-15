#!/usr/bin/env bash
set -euo pipefail
branch="${1:?usage: scripts/worktree.sh <new-branch-name>}"
root="$(git rev-parse --show-toplevel)"
git check-ref-format --branch "$branch" >/dev/null
if ! git -C "$root" rev-parse --verify main >/dev/null 2>&1; then
  echo "Create an initial reviewed local commit on main before adding worktrees." >&2
  exit 1
fi
target="$(dirname "$root")/$(basename "$root")-${branch//\//-}"
git -C "$root" worktree add -b "$branch" "$target" main
printf 'Worktree ready: %s
Start Claude from that directory.
' "$target"
