#!/usr/bin/env bash
set -uo pipefail
LOGS="$RUNNER_TEMP/logs"; mkdir -p "$LOGS"
cd app
fallo=0
etapa() { local nombre=$1; shift; echo "::group::$nombre"; "$@" > "$LOGS/$nombre.log" 2>&1; local s=$?; cat "$LOGS/$nombre.log"; echo "::endgroup::"; echo "$nombre: $s" >> "$LOGS/resumen.txt"; [ $s -eq 0 ] || fallo=1; }
flutter --version > "$LOGS/0-version.log" 2>&1
etapa 1-create flutter create . --project-name bewell --platforms=web,android,ios
etapa 2-pub-get flutter pub get
etapa 3-analyze flutter analyze --no-fatal-infos --no-fatal-warnings
etapa 4-test flutter test
etapa 5-build-web flutter build web --release --dart-define=API_URL="${API_URL:-http://localhost:3000/api/v1}"
cat "$LOGS/resumen.txt"
exit $fallo
