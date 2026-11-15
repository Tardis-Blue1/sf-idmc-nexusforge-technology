#!/usr/bin/env bash
# Push this standalone NexusForge repo to GitHub once the Cursor GitHub App
# (or a PAT) can see Tardis-Blue1/sf-idmc-nexusforge-technology.
# Does NOT touch Gen-Code.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
REPO="${1:-Tardis-Blue1/sf-idmc-nexusforge-technology}"
ALT="${2:-Tardis-Blue1/sf-idmc-nexusforge-technology-v2}"
cd "$ROOT"

if [ ! -d .git ]; then
  echo "No .git in $ROOT — init first."
  exit 1
fi

target=""
if gh repo view "$REPO" --json url >/dev/null 2>&1; then
  target="$REPO"
elif gh repo view "$ALT" --json url >/dev/null 2>&1; then
  target="$ALT"
  echo "Primary name not found; using $ALT"
else
  echo "Repo not visible yet."
  echo "1) As Tardis-Blue1, create private empty repo: $REPO (or $ALT if taken)"
  echo "2) Grant Cursor GitHub App access to that repo (Selected repos or All)"
  echo "3) Re-run: $0"
  echo "Intended URL: https://github.com/$REPO"
  exit 2
fi

URL=$(gh repo view "$target" --json url -q .url)
git remote remove origin 2>/dev/null || true
git remote add origin "https://github.com/${target}.git"
gh auth setup-git
BRANCH=$(git rev-parse --abbrev-ref HEAD)
git push -u origin "$BRANCH"
echo "Pushed to $URL (branch $BRANCH)"
