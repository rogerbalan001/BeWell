#!/usr/bin/env bash
# Guarda los registros de la corrida en una rama aparte para poder revisarlos con git.
set -euo pipefail
RAMA=$1
cd "$RUNNER_TEMP/logs" 2>/dev/null || { mkdir -p "$RUNNER_TEMP/logs"; cd "$RUNNER_TEMP/logs"; echo "sin registros" > vacio.txt; }
echo "$GITHUB_SHA" > commit.txt
git init -q -b "$RAMA"
git -c user.name="ci" -c user.email="ci@users.noreply.github.com" add -A
git -c user.name="ci" -c user.email="ci@users.noreply.github.com" commit -qm "Registros de CI para $GITHUB_SHA"
git push -qf "https://x-access-token:${GH_TOKEN}@github.com/${GITHUB_REPOSITORY}.git" "$RAMA"
