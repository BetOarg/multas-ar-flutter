# Changelog — Multas Argentina Pro

Todas las versiones significativas se documentan aquí.
Formato basado en [Keep a Changelog](https://keepachangelog.com/es/).

---

## [1.0.0] — 2026-10-xx (pendiente de publicación)

### Agregado
- **OCR nativo** PaddleOCR v4 + ONNX Runtime (Android) y Apple Vision
  Framework (iOS) con fallback a google_mlkit_text_recognition (retirado por requisito de privacidad en la rama actual)
- **Motor de nulidades formales**: Art. 3 Ley 13.927 PBA (6 causales
  absolutas), Art. 9 Ley 1217 CABA, Art. 70 Ley 24.449 Nacional,
  fotomultas (homologación + notificación)
- **Cálculo de plazos**: días hábiles administrativos/judiciales y
  corridos con feriados nacionales 2026 precargados
- **Alertas duales**: Fallo Andrade CABA (prescripción 2 vs 5 años),
  caducidad fotomultas PBA (Art. 28 vs Cámara San Martín 2018)
- **6 modelos de escritos**: descargo PBA/CABA, nulidad formal, recurso
  apelación PBA fundado, prescripción administrativa, telegrama,
  denuncia conductor real (Art. 35 inc. f Ley 13.927)
- **Base normativa**: 9 jurisdicciones con actualización OTA desde
  GitHub, seed local de feriados 2026
- **Notificaciones locales** de vencimientos con alarmas exactas
- **Almacenamiento seguro** con flutter_secure_storage (Keystore/Keychain)
- **5 tabs** con navegación go_router: Análisis, Casos, Escritos,
  Normativa, Configuración
- **Tema dark** consistente: fondo #0D1117, acento índigo #4361EE

### Arquitectura
- BLoC (flutter_bloc) como state management
- Drift + SQLite como único engine de base de datos local
- Repository Pattern: ICasosRepository → LocalCasosRepository
  (Firestore listo para Fase 5)
- OcrServiceFactory: selección automática PaddleOCR / Apple Vision; sin fallback ML Kit para evitar métricas de SDK fuera del dispositivo.
- NulidadesService: motor legal puro sin dependencias de UI

### Tests
- 12 tests unitarios PlazosService (hábiles, corridos, prescripción)
- 8 tests unitarios AnalisisService (campos, alertas duales, plan pagos)
- 14 tests unitarios OcrParser (PBA, CABA, fotomultas, patentes)
- 18 tests unitarios NulidadesService (todas las causales)
- 5 tests integración end-to-end (flujo OCR → nulidades)
- 4 tests widget AnalisisScreen (smoke)

---

## [Próximas versiones]

### [1.1.0] — Fase 5 (planificado)
- Firebase Auth (email + Google Sign-In)
- Sincronización Firestore de casos entre dispositivos
- FirestoreCasosRepository activado

### [1.2.0] — Fase 6 (planificado)
- Consulta SINAI/DVE online (si ANSV publica API REST pública)
- Integración DVE para verificación técnica del vehículo
- Deep links a portales provinciales por jurisdicción

### [2.0.0] — Futuro
- Backend GCP Cloud Run + OCR Cloud Vision para mayor precisión
- Base normativa expandida con jurisprudencia por provincia
- Historial de jurisprudencia citada con links a fuentes oficiales
- Exportación PDF de escritos con firma digital

---

## [1.1.0] — 2026-10-xx (Fase 5)

### Agregado
- **Firebase Auth**: email/password + Google Sign-In (IFirebaseService activada)
- **Firestore sync**: FirestoreCasosRepository offline-first (last-write-wins)
- **AuthScreen**: login con email, registro, Google y modo local sin cuenta
- **AuthBloc**: gestión completa del ciclo de vida de autenticación
- **Guard de autenticación**: GoRouter redirige a /auth si no hay sesión
- **7 tests** AuthBloc: verificación, email exitoso/fallido, Google, modo local, logout


## Privacidad local estricta (trabajo en curso)

- Eliminada la actualización automática de normativa por Internet.
- Eliminada la dependencia de red directa desde Android mediante el permiso INTERNET.
- Retirada la referencia a análisis remoto con Anthropic en la configuración.
- La URL de consulta CABA ya no incluye automáticamente la patente.
- Actualizada la política de privacidad y la ficha de tienda.
- Pendiente: validar builds nativos, tráfico de red y flujos de exportación en dispositivos reales.
