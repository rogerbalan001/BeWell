#!/usr/bin/env bash
# Publica app/build/web en la rama web-dist, desde donde Render sirve la app.
set -euo pipefail
cd app/build/web
echo "$GITHUB_SHA" > version.txt
git init -q -b web-dist
git -c user.name="ci" -c user.email="ci@users.noreply.github.com" add -A
git -c user.name="ci" -c user.email="ci@users.noreply.github.com" commit -qm "App web compilada desde $GITHUB_SHA"
git push -qf "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" web-dist
