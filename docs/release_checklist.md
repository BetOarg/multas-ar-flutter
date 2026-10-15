# Release Checklist — Multas Argentina Pro
## Google Play Store v1.0.0

---

## PRE-BUILD

### Keystore y firma
- [ ] Ejecutar `scripts/keystore_setup.sh` y generar `android/app/multas-ar-release.jks`
- [ ] Guardar keystore y contraseñas en un gestor de secretos
- [ ] Confirmar que `android/key.properties` existe y NO está en Git
- [ ] Confirmar que `android/app/multas-ar-release.jks` NO está en Git
- [ ] Verificar que `android/app/build.gradle` usa `signingConfigs.release`, nunca la clave debug
- [ ] Confirmar que una release sin `key.properties` falla y no genera un artefacto firmado con debug

### .gitignore — verificar que contiene
```
android/key.properties
android/app/*.jks
android/app/*.keystore
```

No ignorar el Gradle Wrapper: `android/gradlew`, `android/gradlew.bat` y `android/gradle/wrapper/gradle-wrapper.jar` son parte de una estructura Android reproducible y deben versionarse cuando se incorporen.

### Versión
- [ ] Actualizar `version` en `pubspec.yaml`
- [ ] Confirmar que versionCode/versionName son los esperados para Play Console

### Assets PaddleOCR
- [ ] `assets/models/det.onnx` presente, o fallback OCR probado y documentado
- [ ] `assets/models/cls.onnx` presente, o fallback OCR probado y documentado
- [ ] `assets/models/rec.onnx` presente, o fallback OCR probado y documentado
- [ ] `assets/models/ppocr_keys.txt` presente, o fallback OCR probado y documentado
- [ ] Confirmar licencias, procedencia, compatibilidad y tamaño de los modelos

### Código
- [ ] `flutter analyze` sin errores
- [ ] `dart run build_runner build --delete-conflicting-outputs` ejecutado
- [ ] Tests unitarios y de integración pasan
- [ ] La clave de Anthropic no está hardcodeada ni incluida en el cliente sin una evaluación de seguridad
- [ ] Política de privacidad coincide con el almacenamiento, cifrado y tráfico reales
- [ ] Normativa y reglas jurídicas revisadas por jurisdicción, vigencia y fuente oficial

---

## BUILD

### Android AAB (recomendado para Play)
```bash
flutter build appbundle --release
```

### Verificación
- [ ] Validar AAB con bundletool
- [ ] Confirmar que el certificado de firma coincide con el esperado
- [ ] Instalar y probar el artefacto de release en un dispositivo real
- [ ] Registrar hash SHA-256 del artefacto publicado

### iOS
- [ ] Restaurar y verificar el proyecto Xcode/Podfile desde un clon limpio
- [ ] Ejecutar build de release en macOS con las credenciales y perfiles correspondientes
- [ ] Probar OCR, permisos, almacenamiento y notificaciones en dispositivo real

---

## PLAY CONSOLE — CONFIGURACIÓN INICIAL

- [ ] Crear app y completar listing
- [ ] Subir política de privacidad accesible públicamente
- [ ] Completar clasificación de contenido y Data Safety según comportamiento real
- [ ] Confirmar correo de soporte, capturas, icono y banner
- [ ] Revisar todos los requisitos vigentes de Play Console

---

## PRIMER RELEASE (Internal Testing)

- [ ] Subir AAB al track Internal Testing
- [ ] Instalar desde Play en un dispositivo real y probar el flujo completo
- [ ] Verificar OCR, plazos, nulidades, escritos, notificaciones, persistencia y normativa
- [ ] No promover a producción hasta cerrar los bloqueantes y registrar resultados

---

## RELEASE A PRODUCCIÓN

- [ ] Completar los requisitos de revisión de Play Console
- [ ] Hacer despliegue gradual y monitorizar Android Vitals
- [ ] Mantener un canal de soporte y un proceso de corrección de normativa

---

## NOTAS IMPORTANTES

No publicar mientras la compilación limpia, la firma, el OCR, la política de privacidad y las reglas jurídicas no hayan sido verificadas. La pérdida de la clave de firma puede impedir actualizar la aplicación con la misma identidad.
