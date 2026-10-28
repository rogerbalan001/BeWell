#!/usr/bin/env bash
# Genera la carpeta android/, le da permiso de Internet y nombre "Bewell", y compila el APK de release.
set -euo pipefail
cd app
flutter create . --project-name bewell --org ve.unimet.bewell --platforms=android
MANIFEST=android/app/src/main/AndroidManifest.xml
# El manifiesto principal no trae el permiso de Internet (solo el de depuración): sin él la app no llega a la API.
grep -q 'android.permission.INTERNET' "$MANIFEST" || \
  sed -i 's#<application#<uses-permission android:name="android.permission.INTERNET"/>\n    <application#' "$MANIFEST"
sed -i 's#android:label="[^"]*"#android:label="Bewell"#' "$MANIFEST"
flutter pub get
flutter build apk --release --dart-define=API_URL="${API_URL}"
ls -lh build/app/outputs/flutter-apk/
