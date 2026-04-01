#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$ROOT_DIR/build"
OUT_DIR="$BUILD_DIR/pixel_neon_drone_dash"

TEMPLATE_DIR="$ROOT_DIR/template"

if ! command -v flutter >/dev/null 2>&1; then
  echo "Flutter не найден в PATH. Установите Flutter и проверьте: flutter --version" >&2
  exit 1
fi

mkdir -p "$BUILD_DIR"

if [ -d "$OUT_DIR" ]; then
  echo "Удаляю старую сборку: $OUT_DIR"
  rm -rf "$OUT_DIR"
fi

echo "Создаю Flutter-проект (Android-only) в $OUT_DIR"
flutter create --platforms=android --org com.flaype.pixelneondronedash "$OUT_DIR"

echo "Подкладываю шаблонные файлы игры"
cp "$TEMPLATE_DIR/pubspec.yaml" "$OUT_DIR/pubspec.yaml"
mkdir -p "$OUT_DIR/lib"
cp "$TEMPLATE_DIR/lib/main.dart" "$OUT_DIR/lib/main.dart"

KOTLIN_DIR="$OUT_DIR/android/app/src/main/kotlin/com/flaype/pixelneondronedash"
mkdir -p "$KOTLIN_DIR"
cp "$TEMPLATE_DIR/android/MainActivity.kt" "$KOTLIN_DIR/MainActivity.kt"

echo "Готово."
echo
echo "Дальше:"
echo "  cd \"$OUT_DIR\""
echo "  flutter pub get"
echo "  flutter run"

