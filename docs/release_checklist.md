# Release Checklist — Multas Argentina Pro
## Google Play Store v1.0.0

> **Estado verificado (2026-10-19): NO APTO PARA RELEASE.**
> Los workflows `Analyze and test` de push y PR pasaron en el HEAD `12664f2acf28ec03eaa2df0b9b6cade7fbff3b5e`
> (análisis estático, generación de Drift y suite Flutter). Esto no valida los builds nativos.
> La rama aún no contiene el scaffold completo de Android (settings Gradle y wrapper)
> ni el proyecto Xcode y la configuración de dependencias iOS (Podfile o Swift Package Manager, según la versión de Flutter). Se quitó la asignación explícita de firma debug
> en `android/app/build.gradle`, pero todavía no se ha validado una compilación nativa
> ni una firma de producción. La presencia de los modelos PaddleOCR también está pendiente de verificación.
> No generar ni subir un AAB de producción hasta cerrar estos bloqueos y ejecutar
> builds nativos reales.

---

## PRE-BUILD

### Keystore y firma
- [ ] **Bloqueo previo:** completar scaffold Android/Gradle antes de configurar la firma.
- [x] Eliminar la asignación explícita de `signingConfigs.debug` al tipo `release` (commit `f633527`).
- [ ] Ejecutar una compilación nativa con la configuración Gradle completa y confirmar que release no usa firma debug.
- [ ] Validar que `android/app/key.properties` contiene las cuatro propiedades requeridas y que la ruta del keystore resuelve correctamente.
- [ ] Ejecutar `scripts/keystore_setup.sh` y generar `multas-ar-release.jks`
- [ ] Guardar keystore + contraseñas en gestor de secretos (1Password, etc.)
- [ ] Confirmar que `android/app/key.properties` existe y NO está en git
- [ ] Confirmar que `android/app/multas-ar-release.jks` NO está en git
- [ ] No copiar ciegamente `build_release.gradle`: es una plantilla histórica; mantener `android/app/build.gradle` como fuente de verdad y verificar la configuración en CI.

### .gitignore — verificar que contiene
```
android/key.properties
android/app/*.jks
android/app/*.keystore
```

### Versión
- [ ] Actualizar `version` en `pubspec.yaml` → `1.0.0+1`
- [ ] Confirmar `versionCode: 1` y `versionName: "1.0.0"`

### Assets PaddleOCR
- [ ] `assets/models/det.onnx` presente
- [ ] `assets/models/cls.onnx` presente
- [ ] `assets/models/rec.onnx` presente
- [ ] `assets/models/ppocr_keys.txt` presente
- [ ] Tamaño total de modelos < 80 MB (límite APK inicial)

### Scaffold nativo — bloqueo previo al build
- [ ] Generar y revisar la estructura Android con Flutter estable: `android/settings.gradle`, `android/gradlew`, `android/gradlew.bat` y `android/gradle/wrapper/gradle-wrapper.properties`.
- [ ] Generar y revisar la estructura iOS: `ios/Runner.xcodeproj/project.pbxproj` y la configuración de dependencias/plugins compatible con Flutter (Podfile si usa CocoaPods o configuración Swift Package Manager si corresponde).
- [ ] Ejecutar build Android en CI y compilar iOS en macOS/Xcode; no basta con `flutter analyze` ni con los tests Dart.
- [ ] Revisar el artefacto del workflow `Generate native scaffold proposal`; es una referencia aislada, no una integración.
- [ ] Revisar el workflow `Native scaffold integration smoke test`: genera un scaffold temporal, superpone el código Android existente solo en el runner y ejecuta `flutter pub get`, `flutter analyze` y build APK debug.
- [ ] Confirmar que el APK debug compila y resolver cualquier incompatibilidad reportada antes de incorporar configuración Gradle al repositorio.
- [ ] Validar iOS por separado en macOS/Xcode conservando el registro de `OcrPlugin.swift` y `AppDelegate.swift`.

### Código
- [ ] `flutter analyze` sin errores
- [ ] `dart run build_runner build` ejecutado (código Drift generado)
- [ ] `flutter test test/unit/ test/integration/` — todos pasan
- [ ] API key Anthropic NO hardcodeada (se ingresa en configuración)
- [ ] `debugShowCheckedModeBanner: false` en MaterialApp
- [ ] Logs de debug eliminados o detrás de `kDebugMode`

---

## BUILD

### Android AAB (recomendado para Play)
```bash
flutter build appbundle --release
# Output: build/app/outputs/bundle/release/app-release.aab
```

### Verificar firma del AAB
```bash
# Requiere bundletool
java -jar bundletool.jar validate --bundle=app-release.aab
```

### APK para testing directo (opcional)
```bash
flutter build apk --release --split-per-abi
# Output: build/app/outputs/apk/release/
```

### Tamaño del AAB
- [ ] AAB < 150 MB (límite Play Store sin expansión)
- Si supera: revisar modelos ONNX, comprimir assets

---

## PLAY CONSOLE — CONFIGURACIÓN INICIAL

### Crear app
- [ ] Crear cuenta de desarrollador Google Play (USD 25 — único pago)
- [ ] Crear nueva app en Play Console
- [ ] Nombre: "Multas Argentina Pro"
- [ ] Idioma por defecto: Español (es-419)
- [ ] App o juego: App
- [ ] Gratis o de pago: Gratis

### Presencia en la tienda
- [ ] Título (30 chars): `Multas Argentina Pro`
- [ ] Descripción corta (80 chars): ver `play_store_listing.md`
- [ ] Descripción larga (4000 chars): ver `play_store_listing.md`
- [ ] Ícono 512×512 PNG (sin alfa): generar y subir
- [ ] Banner 1024×500 PNG: generar y subir
- [ ] Screenshots teléfono (mín. 2, máx. 8): 6 capturas
- [ ] Screenshots tablet (opcional): 1 captura
- [ ] Categoría: Herramientas
- [ ] Email de soporte: soporte@multasargentina.app
- [ ] URL política de privacidad: subir `docs/privacy_policy.html` a host

### Clasificación de contenido
- [ ] Completar cuestionario (ver `play_store_listing.md`)
- [ ] Clasificación esperada: Everyone / PEGI 3

### Seguridad de datos (Data Safety)
- [ ] Completar formulario (ver tabla en `play_store_listing.md`)
- [ ] Declarar: fotos procesadas localmente + Anthropic opcional
- [ ] Declarar: sin venta de datos, sin analíticas

### Precios y distribución
- [ ] Precio: Gratis
- [ ] Países: Argentina + todos disponibles
- [ ] Apto para familias: No (herramienta legal, +18)

---

## PRIMER RELEASE (Internal Testing)

- [ ] Subir AAB a track "Internal Testing"
- [ ] Agregar testers (mín. 1 cuenta Google personal)
- [ ] Completar todas las secciones requeridas por Play
- [ ] Enviar a revisión interna
- [ ] Instalar desde Play en dispositivo real y testear flujo completo

### Checklist de smoke test en dispositivo
- [ ] App abre sin crash
- [ ] Cámara funciona y OCR procesa una acta
- [ ] Plazos se calculan correctamente
- [ ] Motor de nulidades detecta un defecto de prueba
- [ ] Notificaciones aparecen cuando se configuran
- [ ] Escritos se generan y pueden copiarse
- [ ] Normativa carga para CABA y PBA
- [ ] Configuración guarda y recarga los datos

---

## RELEASE A PRODUCCIÓN

- [ ] Al menos 7 días en Internal Testing sin crashs
- [ ] Promover a "Production"
- [ ] Rollout al 10% inicial — monitorear Play Console → Android Vitals
- [ ] Rollout al 50% a las 48hs si sin anomalías
- [ ] Rollout al 100% a los 5 días

### Monitoreo post-release
- [ ] ANR rate < 0.47% (umbral Google Play)
- [ ] Crash rate < 1.09% (umbral Google Play)
- [ ] Calificación promedio objetivo: ≥ 4.0

---

## NOTAS IMPORTANTES

> ⚠️ **El keystore es IRRECUPERABLE**. Si lo perdés, deberás publicar
> la app con un nuevo package name y perderás todas las instalaciones
> existentes. Guardarlo en al menos 2 lugares seguros distintos.

> ⚠️ Google Play puede tardar **1-3 días hábiles** en revisar la primera
> publicación. Las actualizaciones posteriores suelen ser < 24hs.

> ℹ️ Para la versión v1.0 no es necesario Google Play Billing ni
> ninguna SDK adicional de Google. La app cumple las políticas de
> Play sin módulos extra.

## Diagnóstico CI — 2026-10-19

- El workflow `Flutter checks` terminó verde en los runs `39338450647` y `39338446492`: análisis, generación Drift y tests Flutter completados.
- La propuesta de scaffold terminó verde en el run `39338446398`; esto valida solo la plantilla aislada.
- El smoke test Android falló en el run `39338446581` porque `android/app/build.gradle` declaraba un artefacto inexistente para ML Kit: `com.google.mlkit:text-recognition-latin:16.0.1`. El artefacto Latin correcto ya está cubierto por `com.google.mlkit:text-recognition:16.0.1`; se eliminó la dependencia incorrecta.
- El mismo build reportó que los plugins requieren NDK `28.2.13676358`; se alineó `ndkVersion` con esa versión.
- [ ] Esperar y revisar los workflows disparados por estos cambios. No marcar el smoke test verde hasta que termine `flutter build apk --debug`.
- Las ejecuciones canceladas corresponden a commits reemplazados durante las correcciones; no equivalen a pruebas fallidas del HEAD actual.
- El build de release, la firma de producción y la compilación iOS siguen pendientes.

## Seguimiento nativo — 2026-10-19

- Commit `699e724`: se retiraron las reglas de `.gitignore` que impedían versionar `android/gradlew`, `android/gradlew.bat` y `gradle-wrapper.jar`; también se añadió `android/app/key.properties` a las exclusiones de secretos.
- Commit `c39b2a7`: el workflow de propuesta de scaffold se ejecuta en cada push a `fix/**` y valida que el scaffold aislado generado incluya wrapper Android, configuración Gradle, Podfile y proyecto Xcode antes de publicar el artefacto. Aún no integra esos archivos en la app ni demuestra compilación de la aplicación.
- Esto corrige las reglas de seguimiento, pero no restaura los archivos wrapper ausentes: todavía deben generarse, revisarse y subirse como archivos de código del proyecto.


- Se eliminó la asignación explícita de la firma debug al tipo `release` en `android/app/build.gradle`.
- La firma de release ahora lee `android/app/key.properties` y selecciona `signingConfigs.release` solo si ese archivo existe; si falta, emite una advertencia y no configura la firma debug.
- Commit: [f633527](https://github.com/BetOarg/multas-ar-flutter/commit/f633527139cfc6b28f0846c9ce233cc0822f4464).
- **Pendiente de validar:** sintaxis y resolución Gradle en runner real; no hay evidencia de build Android exitoso. La ausencia del scaffold Gradle completo continúa bloqueando la compilación reproducible.
- **No publicar** hasta configurar y verificar la clave de producción, completar el scaffold Android/iOS y obtener builds nativos verdes.
