#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
# BUILD RELEASE — Multas Argentina Pro
# Automatiza el pipeline completo de release para Google Play.
#
# Uso:
#   ./scripts/build_release.sh            # AAB (Play Store)
#   ./scripts/build_release.sh --apk      # APK por ABI (testing)
#   ./scripts/build_release.sh --check    # Solo análisis y tests
#
# Requisitos:
#   - Flutter 3.22+
#   - dart run build_runner (Drift codegen)
#   - android/key.properties generado
#   - assets/models/ con modelos PaddleOCR
# ══════════════════════════════════════════════════════════════════

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
BUILD_AAB=true
CHECK_ONLY=false
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
OUTPUT_DIR="$PROJECT_DIR/releases/$TIMESTAMP"

# ── Colores ────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${CYAN}▶ $1${NC}"; }
ok()   { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
err()  { echo -e "${RED}❌ $1${NC}"; exit 1; }

# ── Argumentos ────────────────────────────────────────────────────
for arg in "$@"; do
  case $arg in
    --apk)   BUILD_AAB=false ;;
    --check) CHECK_ONLY=true ;;
  esac
done

echo ""
echo -e "${BOLD}══════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Multas Argentina Pro — Release Builder${NC}"
echo -e "${BOLD}══════════════════════════════════════════════${NC}"
echo ""

cd "$PROJECT_DIR"

# ── 1. Verificaciones previas ─────────────────────────────────────
log "Verificando requisitos..."

# Flutter disponible
command -v flutter &>/dev/null || err "Flutter no encontrado. Instalar desde flutter.dev"
FLUTTER_VERSION=$(flutter --version 2>&1 | head -1)
echo "  $FLUTTER_VERSION"

# key.properties existe
if [ ! -f "android/key.properties" ]; then
  err "android/key.properties no encontrado. Ejecutar scripts/keystore_setup.sh primero."
fi
ok "key.properties presente"

# Modelos PaddleOCR
MODELOS_OK=true
for modelo in det.onnx cls.onnx rec.onnx ppocr_keys.txt; do
  if [ ! -f "assets/models/$modelo" ]; then
    warn "Falta assets/models/$modelo"
    MODELOS_OK=false
  fi
done
$MODELOS_OK && ok "Modelos PaddleOCR presentes" || warn "Modelos faltantes — OCR Android usará MLKit como fallback"

# Normativa seed
[ -f "assets/normativa/normativa_base.json" ] \
  && ok "normativa_base.json presente" \
  || err "Falta assets/normativa/normativa_base.json"

# ── 2. Obtener versión del pubspec ────────────────────────────────
VERSION=$(grep '^version:' pubspec.yaml | awk '{print $2}')
log "Versión: $VERSION"

# ── 3. Flutter pub get ────────────────────────────────────────────
log "Actualizando dependencias..."
flutter pub get --no-example 2>&1 | tail -3
ok "Dependencias OK"

# ── 4. Codegen Drift ──────────────────────────────────────────────
log "Generando código Drift..."
dart run build_runner build --delete-conflicting-outputs 2>&1 | tail -5
ok "Codegen OK"

# ── 5. Análisis estático ──────────────────────────────────────────
log "Análisis estático..."
ANALYZE_OUT=$(flutter analyze 2>&1)
if echo "$ANALYZE_OUT" | grep -q "error"; then
  echo "$ANALYZE_OUT"
  err "Errores en flutter analyze. Corregir antes de publicar."
fi
ok "Sin errores de análisis"

# ── 6. Tests ──────────────────────────────────────────────────────
log "Ejecutando tests unitarios..."
flutter test test/unit/ --reporter=compact 2>&1
log "Ejecutando tests de integración..."
flutter test test/integration/ --reporter=compact 2>&1
ok "Todos los tests pasan"

# ── Check-only: salir acá ─────────────────────────────────────────
if $CHECK_ONLY; then
  echo ""
  ok "Check completado. Usar sin --check para compilar."
  exit 0
fi

# ── 7. Build ──────────────────────────────────────────────────────
mkdir -p "$OUTPUT_DIR"

if $BUILD_AAB; then
  log "Compilando AAB de release..."
  flutter build appbundle \
    --release \
    --no-pub \
    --target=lib/main.dart \
    --build-number="${VERSION##*+}" \
    --build-name="${VERSION%%+*}"

  AAB_SRC="build/app/outputs/bundle/release/app-release.aab"
  AAB_DST="$OUTPUT_DIR/multas-ar-${VERSION%%+*}.aab"

  if [ -f "$AAB_SRC" ]; then
    cp "$AAB_SRC" "$AAB_DST"
    AAB_SIZE=$(du -sh "$AAB_DST" | cut -f1)
    ok "AAB generado: $AAB_DST ($AAB_SIZE)"

    # Advertencia si supera 100 MB
    AAB_BYTES=$(stat -f%z "$AAB_DST" 2>/dev/null || stat -c%s "$AAB_DST")
    if [ "$AAB_BYTES" -gt 104857600 ]; then
      warn "AAB supera 100 MB. Considerar separar modelos ONNX con Play Asset Delivery."
    fi
  else
    err "AAB no encontrado en $AAB_SRC"
  fi

else
  log "Compilando APKs por ABI..."
  flutter build apk \
    --release \
    --no-pub \
    --split-per-abi \
    --target=lib/main.dart

  for abi in arm64-v8a armeabi-v7a x86_64; do
    APK_SRC="build/app/outputs/apk/release/app-${abi}-release.apk"
    APK_DST="$OUTPUT_DIR/multas-ar-${VERSION%%+*}-${abi}.apk"
    if [ -f "$APK_SRC" ]; then
      cp "$APK_SRC" "$APK_DST"
      SZ=$(du -sh "$APK_DST" | cut -f1)
      ok "APK $abi: $APK_DST ($SZ)"
    fi
  done
fi

# ── 8. Resumen ────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}══════════════════════════════════════════════${NC}"
echo -e "${BOLD}  ✅ Build completado exitosamente${NC}"
echo -e "${BOLD}══════════════════════════════════════════════${NC}"
echo ""
echo "  Versión   : $VERSION"
echo "  Timestamp : $TIMESTAMP"
echo "  Output    : $OUTPUT_DIR"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "  1. Subir AAB a Play Console → Internal Testing"
echo "  2. Completar listing (docs/play_store_listing.md)"
echo "  3. Enviar a revisión"
echo ""
