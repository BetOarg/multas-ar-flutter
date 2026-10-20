# Release Checklist — Multas Argentina Pro
## Google Play Store v1.0.0

> **Estado verificado (2026-10-20): NO APTO PARA RELEASE.**
> En el commit `0e5039beeefb0c59b81f9cbbdc2b2a0a66ca4233` terminaron verdes:
> - Flutter checks: run [39457947628](https://github.com/BetOarg/multas-ar-flutter/actions/runs/39457947628).
> - Smoke nativo Android + iOS: run [39457947666](https://github.com/BetOarg/multas-ar-flutter/actions/runs/39457947666).
> - Propuesta de scaffold: run [39457947536](https://github.com/BetOarg/multas-ar-flutter/actions/runs/39457947536).
> El smoke test compila contra un scaffold temporal generado por Flutter; **no es una compilación del proyecto nativo versionado**.
> El árbol del repositorio aún carece de archivos nativos esenciales, incluidos `android/settings.gradle`, `android/gradlew`, `android/gradle/wrapper/gradle-wrapper.properties`, `ios/Podfile` y `ios/Runner.xcodeproj/project.pbxproj`. También faltan los modelos PaddleOCR binarios (`det.onnx`, `cls.onnx`, `rec.onnx`, `ppocr_keys.txt`).
> No se ha validado un build de producción firmado ni la privacidad en dispositivos físicos. Mantener bloqueada la publicación hasta integrar y compilar el scaffold real, resolver los modelos OCR y completar las pruebas de privacidad.

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
- [x] No se configura ni requiere API key de Anthropic ni otro servicio de IA/OCR en la nube; mantener la revisión de dependencias y tráfico de red como bloqueo de release.
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
- [ ] Declarar en Data Safety únicamente los flujos confirmados: procesamiento OCR local, almacenamiento local y cualquier exportación/compartición iniciada expresamente por el usuario. No declarar Anthropic ni IA remota opcional.
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
- [x] Revisar los workflows disparados por los cambios: en el HEAD `38af75e3`, Flutter checks, smoke test Android sobre scaffold temporal y propuesta de scaffold terminaron verdes. El smoke test ejecutó `flutter build apk --debug` correctamente, pero no integra el scaffold en el repositorio.
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


## Verificación posterior — HEAD 38af75e3 — 2026-10-19

- [x] Flutter checks: run [39339560982](https://github.com/BetOarg/multas-ar-flutter/actions/runs/39339560982) — análisis, generación Drift y tests verdes.
- [x] Android integration smoke test: run [39339561001](https://github.com/BetOarg/multas-ar-flutter/actions/runs/39339561001) — dependencias, generación Drift y APK debug verdes sobre scaffold temporal.
- [x] Scaffold proposal: run [39339560942](https://github.com/BetOarg/multas-ar-flutter/actions/runs/39339560942) — propuesta aislada generada y artefacto disponible hasta el 2026-10-26.
- [ ] Integrar y revisar los archivos nativos Android/iOS en la rama, preservando el registro de plugins OCR y permisos.
- [ ] Verificar los cuatro assets de PaddleOCR: el árbol actual solo contiene `assets/models/README.md`; los archivos de modelo no están presentes.
- [ ] Ejecutar build Android desde el scaffold ya integrado y build iOS en macOS/Xcode.
- [ ] Configurar y validar firma release; después generar y verificar el AAB.


## OCR gratuito y local — 2026-10-20

- Fuente de modelos: [gitakoos/ocr-models, release v1](https://github.com/gitakoos/ocr-models/releases/tag/v1), PP-OCRv5 Latin/ONNX bajo Apache-2.0.
- Se añadió a `android/app/build.gradle` la tarea `downloadOcrModels`: obtiene los cuatro recursos desde la release fijada, valida SHA-256 y los instala en `android/app/src/main/assets/models`, donde `OcrChannel.kt` los busca. También descarga LICENSE y NOTICE desde el commit upstream fijado `86b424bec2b9210e24db414d3ce7a534688fbc25`.
- El OCR no usa una API de pago ni envía imágenes a un servicio OCR en la nube. Android mantiene ML Kit como fallback; iOS utiliza Apple Vision integrado en el sistema.
- Los binarios no se versionan en Git; el build necesita conexión a GitHub para descargarlos. Sin conexión o si falla la validación de hash, la compilación falla explícitamente.
- [ ] Verificar en CI la tarea Gradle y los cuatro SHA-256.
- [ ] Validar el preprocesamiento y decodificación del modelo con imágenes de actas argentinas; no declarar PaddleOCR listo hasta pasar pruebas de inferencia.
- [ ] Verificar que el archivo LICENSE/NOTICE se distribuya con la app y la atribución quede accesible.
- [ ] Corregir y repetir el smoke test iOS: run previo `39352013457` rojo por `Cannot find 'OcrPlugin' in scope`; el workflow fue actualizado para compilar el plugin en el scaffold temporal.
- [ ] Seguir bloqueado para release hasta que los builds nativos reales del repositorio estén verdes.


## Privacidad estricta: datos solo en el dispositivo — 2026-10-20
- [ ] Probar en dispositivos reales que la base de datos y archivos locales quedan excluidos de copias de seguridad del sistema en Android e iOS.

- [x] Retirada de la llamada OTA automática a GitHub durante el arranque.
- [x] Eliminada la implementación de descarga OTA de normativa del repositorio; la normativa se carga desde assets locales.
- [x] Eliminado el permiso Android INTERNET para impedir conexiones de red directas desde el proceso de la app.
- [x] Eliminada la excepción ATS específica de Anthropic en Info.plist.
- [x] Retirado de Configuración el mensaje que anunciaba análisis de imagen con Anthropic.
- [x] Eliminada la patente de la URL de consulta CABA generada por la app.
- [x] Actualizada la política de privacidad y la ficha de tienda para no prometer IA remota ni actualizaciones automáticas.
- [ ] Compilar Android e iOS desde el proyecto nativo integrado y confirmar que los cambios compilan.
- [ ] Revisar todos los flujos de exportación/compartición: solo deben enviar archivos si el usuario inicia expresamente la acción.
- [ ] Ejecutar prueba de tráfico de red en Android e iOS; confirmar que la app no transmite imágenes, texto OCR, patentes, datos de casos ni configuración.
- [ ] Validar en dispositivos reales OCR local, consulta manual de portales, notificaciones y eliminación de datos.
- [ ] Revisar que ninguna dependencia agregue telemetría o conexiones automáticas.
- [ ] No declarar privacidad verificada ni publicar hasta completar las pruebas anteriores.

**Alcance:** abrir un portal en el navegador o compartir/exportar un documento puede transferir información solo si el usuario lo elige. La app no debe rellenar automáticamente URLs con patentes ni enviar contenido en segundo plano.


## Verificación CI y privacidad — 2026-10-20 (HEAD f89baee)

- [x] Flutter checks: run [39446233198](https://github.com/BetOarg/multas-ar-flutter/actions/runs/39446233198) — verde.
- [x] Propuesta de scaffold nativo: run [39446233225](https://github.com/BetOarg/multas-ar-flutter/actions/runs/39446233225) — verde; es una plantilla aislada, no una compilación de la app integrada.
- [ ] Native scaffold integration smoke test: run [39446233151](https://github.com/BetOarg/multas-ar-flutter/actions/runs/39446233151) — rojo en iOS con `Framework 'Pods_Runner' not found`; Android terminó verde. Quitar la segunda generación del scaffold no resolvió el error. No marcar iOS como validado; inspeccionar la integración CocoaPods/Xcode generada y sus configuraciones de build antes de otra corrección.
- [ ] Confirmar que el contacto de privacidad publicado en `docs/privacy_policy.html` existe y está operativo; el correo actual es un marcador pendiente de verificación.
- [ ] Pruebas en dispositivo real pendientes: tráfico de red, OCR offline, exclusión de backups, borrado local, exportación/compartición y revisión de dependencias.
- [ ] La base SQLite/Drift no está cifrada a nivel de archivo; comunicarlo con precisión y evaluar cifrado solo si el requisito de amenaza lo exige.

**Estado de release:** NO APTO. Los tests Dart verdes no compensan el build iOS rojo ni sustituyen builds nativos integrados y verificación de privacidad en dispositivos reales.


## Verificación CI más reciente — 2026-10-20

- [x] Flutter checks en `01139121338cc7f636ae874662b80c3570e85cfa`: [run 39460002637](https://github.com/BetOarg/multas-ar-flutter/actions/runs/39460002637) — success.
- [x] Propuesta de scaffold: [run 39460002658](https://github.com/BetOarg/multas-ar-flutter/actions/runs/39460002658) — success; el artefacto sigue siendo una referencia aislada.
- [x] Smoke de integración Android+iOS: [run 39460002545](https://github.com/BetOarg/multas-ar-flutter/actions/runs/39460002545) — success sobre scaffold Flutter temporal generado por el workflow.
- [ ] **Bloqueo de release sin resolver:** estos resultados no prueban que el scaffold nativo esté integrado en el árbol versionado de la app. Siguen pendientes la integración revisada de Android/iOS, los modelos OCR binarios, compilaciones reales desde el repositorio y las pruebas de privacidad en dispositivos físicos.
- [ ] Confirmar que el correo de soporte publicado es real y está bajo control del responsable antes de publicar.
