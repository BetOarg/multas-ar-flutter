#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════
# KEYSTORE SETUP — Multas Argentina Pro
# Genera el keystore de producción para firmar el APK/AAB de release.
# EJECUTAR UNA SOLA VEZ. Guardar el archivo .jks y las contraseñas
# en un gestor de secretos (1Password, Bitwarden, etc.).
#
# Requisitos: Java JDK 17+ (keytool incluido)
# ══════════════════════════════════════════════════════════════════

set -euo pipefail

KEYSTORE_DIR="$(dirname "$0")/../android/app"
KEYSTORE_FILE="$KEYSTORE_DIR/multas-ar-release.jks"
KEY_ALIAS="multas-ar-key"
VALIDITY_DAYS=9125   # 25 años

echo "══════════════════════════════════════════════"
echo "  Multas Argentina Pro — Keystore Generator"
echo "══════════════════════════════════════════════"
echo ""

# Verificar que keytool esté disponible
if ! command -v keytool &> /dev/null; then
    echo "❌ keytool no encontrado. Instalar JDK 17+."
    exit 1
fi

# Verificar que el keystore no exista ya
if [ -f "$KEYSTORE_FILE" ]; then
    echo "⚠️  El keystore ya existe en: $KEYSTORE_FILE"
    echo "   Si querés regenerarlo, eliminá el archivo primero."
    exit 0
fi

echo "📋 Se generará el keystore en: $KEYSTORE_FILE"
echo ""
echo "Ingresá los datos para el certificado:"
echo ""

read -rp "Nombre completo (CN): " cn
read -rp "Organización (O) [BetOarg]: " org
org="${org:-BetOarg}"
read -rp "Ciudad (L) [Buenos Aires]: " city
city="${city:-Buenos Aires}"
read -rp "Provincia (ST) [Buenos Aires]: " state
state="${state:-Buenos Aires}"
read -rsp "Contraseña del keystore (mín. 6 chars): " ks_pass
echo ""
read -rsp "Contraseña de la clave (misma recomendada): " key_pass
echo ""

echo ""
echo "Generando keystore..."

keytool -genkeypair \
    -v \
    -keystore "$KEYSTORE_FILE" \
    -storetype JKS \
    -alias "$KEY_ALIAS" \
    -keyalg RSA \
    -keysize 2048 \
    -validity "$VALIDITY_DAYS" \
    -storepass "$ks_pass" \
    -keypass "$key_pass" \
    -dname "CN=$cn, O=$org, L=$city, ST=$state, C=AR"

echo ""
echo "✅ Keystore generado: $KEYSTORE_FILE"
echo ""
echo "══════════════════════════════════════════════"
echo "  IMPORTANTE — Guardá estos datos AHORA:"
echo "══════════════════════════════════════════════"
echo "  Archivo    : $KEYSTORE_FILE"
echo "  Alias      : $KEY_ALIAS"
echo "  Store pass : [la que ingresaste]"
echo "  Key pass   : [la que ingresaste]"
echo ""
echo "  ⚠️  Si perdés el keystore o las contraseñas,"
echo "     NO podrás actualizar la app en Play Store."
echo "══════════════════════════════════════════════"
echo ""

# Generar key.properties para Flutter (NO subir a git)
KEY_PROPS="$(dirname "$0")/../android/key.properties"

cat > "$KEY_PROPS" << EOF
storePassword=$ks_pass
keyPassword=$key_pass
keyAlias=$KEY_ALIAS
storeFile=../app/multas-ar-release.jks
EOF

echo "✅ key.properties generado en: $KEY_PROPS"
echo "   (NO subir a git — ya incluido en .gitignore)"
echo ""

# Mostrar fingerprint del certificado
echo "📌 Fingerprint SHA-256 (para Google Play):"
keytool -list -v \
    -keystore "$KEYSTORE_FILE" \
    -alias "$KEY_ALIAS" \
    -storepass "$ks_pass" 2>/dev/null \
    | grep "SHA256:"
