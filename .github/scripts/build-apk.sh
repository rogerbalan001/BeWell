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
# Algunos plugins (file_picker) compilan contra android-34, pero sus dependencias exigen compileSdk 36:
# se fuerza 36 en todas las librerías Android antes de que el plugin de Android cierre su configuración.
mkdir -p "$HOME/.gradle/init.d"
cat > "$HOME/.gradle/init.d/compile-sdk.gradle" <<'EOF'
allprojects { p ->
  p.afterEvaluate {
    if (p.plugins.hasPlugin('com.android.library')) {
      p.android.compileSdkVersion 36
    }
  }
}
EOF
# Ícono de la app: corazón blanco sobre azul Bewell (ícono adaptativo + versiones clásicas).
cp -r assets/icono/android/res/. android/app/src/main/res/
flutter pub get
flutter build apk --release --dart-define=API_URL="${API_URL}"
ls -lh build/app/outputs/flutter-apk/
