# Modelos OCR (opcional)

Esta carpeta debe contener los cuatro recursos de PaddleOCR para habilitar el motor nativo Android:

- `det.onnx`
- `cls.onnx`
- `rec.onnx`
- `ppocr_keys.txt`

Los binarios no se incluyen en este repositorio. Sin ellos, el canal Android debe informar que PaddleOCR no está disponible y la aplicación debe recurrir al motor OCR alternativo (ML Kit). Antes de incorporar modelos, verificar licencia, procedencia, compatibilidad de entradas/salidas y tamaño de distribución. No renombrar modelos incompatibles para aparentar disponibilidad.
