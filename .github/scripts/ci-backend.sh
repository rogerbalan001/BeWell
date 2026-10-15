#!/usr/bin/env bash
# Ejecuta cada etapa aunque falle la anterior para reunir todos los errores en una sola corrida.
set -uo pipefail
LOGS="$RUNNER_TEMP/logs"; mkdir -p "$LOGS"
cd backend
fallo=0
etapa() { local nombre=$1; shift; echo "::group::$nombre"; "$@" > "$LOGS/$nombre.log" 2>&1; local s=$?; cat "$LOGS/$nombre.log"; echo "::endgroup::"; echo "$nombre: $s" >> "$LOGS/resumen.txt"; [ $s -eq 0 ] || fallo=1; }
etapa 1-install npm install --no-audit --no-fund
etapa 2-tsc npx tsc --noEmit -p tsconfig.json
etapa 3-test npx jest --ci
etapa 4-build npm run build
cat "$LOGS/resumen.txt"
exit $fallo
