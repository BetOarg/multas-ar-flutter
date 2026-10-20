# Modelos OCR (opcional)

Esta carpeta debe contener los cuatro recursos de PaddleOCR para habilitar el motor nativo Android:

- `det.onnx`
- `cls.onnx`
- `rec.onnx`
- `ppocr_keys.txt`

Los binarios no se incluyen en este repositorio. Sin ellos, el canal Android debe informar que PaddleOCR no está disponible y la aplicación debe recurrir al motor OCR alternativo (ML Kit). Antes de incorporar modelos, verificar licencia, procedencia, compatibilidad de entradas/salidas y tamaño de distribución. No renombrar modelos incompatibles para aparentar disponibilidad.


## Fuente gratuita propuesta (pendiente de integración y validación)

Repositorio GitHub: https://github.com/gitakoos/ocr-models
Release fijada: https://github.com/gitakoos/ocr-models/releases/tag/v1
Licencia declarada por upstream: Apache-2.0; conservar LICENSE, NOTICE y atribución en la distribución.

Assets publicados y SHA-256 del README upstream:
- det.onnx — d7fe3ea74652890722c0f4d02458b7261d9f5ae6c92904d05707c9eb155c7924
- cls.onnx — f4bb53707100c5f3d59ba834eb05bb400369f20aed35d4b26807b1bfadd2a70e
- rec_latin.onnx (destino local rec.onnx) — 995b0f5f28d2073896a78c03b5b863eae6af3744bafa0245b8522beea6994927
- ppocrv5_latin_dict.txt (destino local ppocr_keys.txt) — ccbcc45730b3fbbd9050c5bc74db6a99067141ef1035e3d14889a84a6b9b1aff

No incorporar los binarios al bundle hasta validar la compatibilidad de entradas/salidas y decodificación con OcrChannel.kt. El reconocimiento requiere entrada BGR normalizada a [-1, 1], tensor [N,3,48,W] y salida CTC [N,T,838]. La inferencia es local; no requiere API de pago ni llamadas a la nube.
