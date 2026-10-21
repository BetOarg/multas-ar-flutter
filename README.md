# Multas Argentina Pro — Flutter App

Asistente legal para análisis de infracciones de tránsito en Argentina.

## Stack técnico

| Capa | Tecnología |
|------|-----------|
| Framework | Flutter 3.x / Dart 3.3+ |
| Estado | BLoC (flutter_bloc) |
| Base de datos | Drift + SQLite |
| OCR Android | Canal nativo PaddleOCR/ONNX (requiere modelos; no verificado en build) |
| OCR iOS | Apple Vision Framework (implementación presente; build iOS no verificado) |
| OCR local | PaddleOCR/ONNX (Android), Apple Vision (iOS) |
| Análisis | Motor local de reglas y plazos; sin IA remota ni envío automático de datos |
| Navegación | go_router |
| Notificaciones | flutter_local_notifications |
| Almacenamiento seguro | flutter_secure_storage para secretos compatibles; no implica cifrado de la base SQLite |

## Requisitos

- Flutter 3.22+
- Dart 3.3+
- Android: minSdk 26 (Android 8.0+), NDK 27.0.12077973
- iOS: 13.0+
- Xcode 15+

## Setup inicial

```bash
# 1. Clonar
git clone https://github.com/BetOarg/multas-ar-flutter.git
cd multas-ar-flutter

# 2. Instalar dependencias
flutter pub get

# 3. Generar código Drift
dart run build_runner build --delete-conflicting-outputs

# 4. Ejecutar en modo debug
flutter run

# 5. Tests
flutter test test/unit/
flutter test test/integration/
```

## Modelos PaddleOCR (Android)

Los modelos se descargan y verifican durante la compilación Android desde una fuente fijada en Gradle; no se descargan durante el uso de la app. La inferencia debe validarse antes de declarar PaddleOCR operativo. Assets esperados:
```
assets/models/
├── det.onnx          # Detección de regiones (960×960)
├── cls.onnx          # Clasificación de ángulo
├── rec.onnx          # Reconocimiento de texto
└── ppocr_keys.txt    # Charset español
```

Fuente: https://github.com/PaddlePaddle/PaddleOCR/releases

## Estructura

```
lib/
├── main.dart                    ← Entry point + DI
├── core/
│   ├── constants/               ← Jurisdicciones, normas, plazos
│   ├── database/                ← Drift: tablas, DAOs, migraciones
│   ├── repository/              ← ICasosRepository, NormativaRepository
│   └── services/
│       ├── ocr_service.dart     ← PaddleOCR / Apple Vision (sin fallback remoto)
│       ├── plazos_service.dart  ← Motor de plazos hábiles/corridos
│       ├── analisis_service.dart ← Alertas y oportunidades
│       ├── nulidades_service.dart ← Art. 3 Ley 13.927 + Art. 9 Ley 1217
│       ├── notification_service.dart
│       ├── sinai_service.dart   ← URLs portales gubernamentales
│       └── firebase_service.dart ← stub heredado, no usado en runtime
├── features/
│   ├── analisis/    ← OCR + análisis IA (BLoC + UI)
│   ├── casos/       ← CRUD casos + detalle (BLoC + UI)
│   ├── escritos/    ← 6 modelos de escritos (BLoC + UI)
│   ├── nulidades/   ← Motor nulidades formales (BLoC + UI)
│   ├── normativa/   ← 9 jurisdicciones (UI)
│   └── configuracion/ ← Perfil usuario (UI)
└── shared/
    ├── router/      ← go_router (5 tabs)
    ├── theme/       ← Dark theme: bg #0D1117, acento #4361EE
    └── widgets/     ← LegalAlert, PlazoCard, CampoFaltante, ScaffoldNav
```

## Normativa implementada

- **CABA**: Ley 1217 (t.c. 6.764/2024), Ley 451, Fallo Andrade
- **PBA**: Ley 13.927, Ley 15.002, Art. 3 nulidades, fotomultas
- **Mendoza**: Ley 9024, Art. 94 prescripción tripartita
- **Nacional**: Ley 24.449, Decreto 779/95
- **+ Córdoba, Santa Fe, Tucumán, Salta, Neuquén**

## Alertas duales implementadas

| Jurisdicción | Norma A | Norma B | Advertencia |
|---|---|---|---|
| CABA | Prescripción 5 años (Ley 451) | 2 años (Fallo Andrade PCyF N°15) | Verificar alzada |
| PBA fotomultas | Caducidad automática 60 días hábiles (Art. 28) | Plazo ordenatorio (Cám. San Martín 2018) | Acreditar perjuicio |

## Estado de verificación

La presencia de código fuente no demuestra que una función esté lista para producción. La app arranca directamente en modo local, sin cuentas ni sincronización, sin llamada OTA automática ni permiso Android INTERNET. La opción de eliminación local ya existe; falta validar los builds nativos, el OCR en dispositivos, el tráfico de red y el borrado en dispositivos reales. SQLite/Drift no está cifrado a nivel de archivo.

## Roadmap

| Fase | Estado |
|------|--------|
| 1 — Core local (OCR, nulidades, plazos, escritos) | ✅ Completo |
| 2 — OCR nativo PaddleOCR + Apple Vision | ⚠️ Código parcial; modelos y builds nativos por verificar |
| 3 — Motor nulidades + Firebase stub | ⚠️ Stub heredado, no se instancia en runtime |
| 4 — Google Play Store | 🔜 Pendiente |
| 5 — Cuentas y sincronización remota | ❌ Excluidas del producto local-only |
| 6 — SINAI/DVE integración | 🔜 Pendiente |

## Disclaimer

**MULTAS ARGENTINA PRO** es una herramienta informativa.
No constituye asesoramiento jurídico profesional ni reemplaza
la intervención de un abogado/a matriculado/a (Ley 23.187).
