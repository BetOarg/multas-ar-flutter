package com.betOarg.multas_ar

import ai.onnxruntime.OnnxTensor
import ai.onnxruntime.OrtEnvironment
import ai.onnxruntime.OrtSession
import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Matrix
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import java.nio.FloatBuffer

// ══════════════════════════════════════════════════════════════════
// OCR CHANNEL — Android
// Platform channel Flutter ↔ Kotlin para PaddleOCR v4 con ONNX.
// Pipeline: Detección (det) → Clasificación (cls) → Reconocimiento (rec)
// Modelos en assets/models/: det.onnx, cls.onnx, rec.onnx, ppocr_keys.txt
// ══════════════════════════════════════════════════════════════════

class OcrChannel(
    private val context: Context,
    private val scope: CoroutineScope,
) {
    companion object {
        const val CHANNEL = "com.betOarg.multas_ar/ocr"

        // Dimensiones de entrada para cada modelo
        private const val DET_SIZE   = 960       // detección: 960×960
        private const val CLS_HEIGHT = 48        // clasificación: 48×192
        private const val CLS_WIDTH  = 192
        private const val REC_HEIGHT = 48        // reconocimiento: 48×320
        private const val REC_WIDTH  = 320
        private val MEAN = floatArrayOf(0.485f, 0.456f, 0.406f)
        private val STD  = floatArrayOf(0.229f, 0.224f, 0.225f)
    }

    private var env: OrtEnvironment? = null
    private var detSession: OrtSession? = null
    private var clsSession: OrtSession? = null
    private var recSession: OrtSession? = null
    private var charset: List<String> = emptyList()

    fun register(engine: FlutterEngine) {
        MethodChannel(
            engine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "recognizeImage" -> {
                    val path = call.argument<String>("imagePath")
                        ?: return@setMethodCallHandler result.error(
                            "INVALID_ARG", "imagePath requerido", null)
                    scope.launch {
                        try {
                            val texto = recognizeImage(path)
                            result.success(texto)
                        } catch (e: Exception) {
                            result.error("OCR_ERROR", e.message, null)
                        }
                    }
                }
                "isAvailable" -> result.success(modelsAvailable())
                else -> result.notImplemented()
            }
        }
    }

    // ── Pipeline OCR ─────────────────────────────────────────
    private suspend fun recognizeImage(imagePath: String): String =
        withContext(Dispatchers.Default) {
            ensureModelsLoaded()
            val bitmap = loadAndPrepareBitmap(imagePath)
            val boxes  = detect(bitmap)
            val lines  = boxes
                .map { box -> cropRegion(bitmap, box) }
                .map { crop -> classify(crop) }
                .mapNotNull { (crop, angle) ->
                    val rotated = if (angle > 90) rotateBitmap(crop, 180f) else crop
                    recognize(rotated)
                }
            lines.joinToString("\n").trim()
        }

    // La disponibilidad solo es verdadera si están presentes todos los
    // recursos necesarios. Evita anunciar PaddleOCR como operativo cuando
    // la distribución no incluye los modelos; Flutter podrá usar ML Kit.
    private fun modelsAvailable(): Boolean {
        val required = listOf(
            "models/det.onnx",
            "models/cls.onnx",
            "models/rec.onnx",
            "models/ppocr_keys.txt",
        )
        return required.all { asset ->
            try {
                context.assets.open(asset).use { }
                true
            } catch (_: Exception) {
                false
            }
        }
    }

    // ── Carga lazy de modelos ─────────────────────────────────
    private fun ensureModelsLoaded() {
        if (env != null) return
        env = OrtEnvironment.getEnvironment()

        val opts = OrtSession.SessionOptions().apply {
            setIntraOpNumThreads(4)
            setOptimizationLevel(OrtSession.SessionOptions.OptLevel.ALL_OPT)
        }

        detSession = env!!.createSession(assetBytes("models/det.onnx"), opts)
        clsSession = env!!.createSession(assetBytes("models/cls.onnx"), opts)
        recSession = env!!.createSession(assetBytes("models/rec.onnx"), opts)
        charset    = loadCharset()
    }

    // ── Detección de regiones de texto ───────────────────────
    private fun detect(bitmap: Bitmap): List<FloatArray> {
        // Mantener la relación de aspecto: estirar una foto vertical a 960×960
        // deforma las letras y reduce la precisión del reconocimiento.
        val scale = minOf(
            DET_SIZE.toFloat() / bitmap.width,
            DET_SIZE.toFloat() / bitmap.height,
        )
        val scaledW = (bitmap.width * scale).toInt().coerceIn(1, DET_SIZE)
        val scaledH = (bitmap.height * scale).toInt().coerceIn(1, DET_SIZE)
        val offsetX = (DET_SIZE - scaledW) / 2
        val offsetY = (DET_SIZE - scaledH) / 2
        val scaled = Bitmap.createScaledBitmap(bitmap, scaledW, scaledH, true)
        val letterboxed = Bitmap.createBitmap(
            DET_SIZE, DET_SIZE, Bitmap.Config.ARGB_8888,
        )
        android.graphics.Canvas(letterboxed).apply {
            drawColor(android.graphics.Color.WHITE)
            drawBitmap(scaled, offsetX.toFloat(), offsetY.toFloat(), null)
        }

        val tensor = bitmapToTensor(letterboxed, DET_SIZE, DET_SIZE)
        val output = detSession!!.run(mapOf("x" to tensor))
        val probabilityMap = extractProbabilityMap(output[0].value)
            ?: throw IllegalStateException(
                "Formato de salida ONNX de detección no reconocido: ${output[0].value.javaClass.name}",
            )

        return parseProbabilityMap(
            probabilityMap = probabilityMap,
            origW = bitmap.width,
            origH = bitmap.height,
            scaleX = scaledW.toFloat() / bitmap.width,
            scaleY = scaledH.toFloat() / bitmap.height,
            offsetX = offsetX,
            offsetY = offsetY,
        )
    }

    /**
     * PaddleOCR DBNet suele devolver [1, 1, H, W]. ONNX Runtime lo expone
     * como arrays anidados; quitar dimensiones batch/canal de forma segura.
     */
    private fun extractProbabilityMap(value: Any?): Array<FloatArray>? {
        return when (value) {
            is Array<*> -> when {
                value.isEmpty() -> null
                value.all { it is FloatArray } ->
                    value.map { it as FloatArray }.toTypedArray()
                value.size == 1 -> extractProbabilityMap(value[0])
                else -> null
            }
            else -> null
        }
    }

    // ── Clasificación de ángulo ───────────────────────────────
    private fun classify(crop: Bitmap): Pair<Bitmap, Int> {
        val resized = Bitmap.createScaledBitmap(crop, CLS_WIDTH, CLS_HEIGHT, true)
        val tensor  = bitmapToTensor(resized, CLS_WIDTH, CLS_HEIGHT)
        val inputs  = mapOf("x" to tensor)
        val output  = clsSession!!.run(inputs)
        val scores  = output[0].value as Array<FloatArray>
        val angle   = if (scores[0][1] > 0.9f) 180 else 0
        return Pair(crop, angle)
    }

    // ── Reconocimiento de texto ───────────────────────────────
    private fun recognize(crop: Bitmap): String? {
        val w      = (crop.width.toFloat() / crop.height * REC_HEIGHT).toInt()
                       .coerceIn(1, REC_WIDTH)
        val resized = Bitmap.createScaledBitmap(crop, w, REC_HEIGHT, true)
        // Pad a REC_WIDTH con blanco
        val padded  = Bitmap.createBitmap(REC_WIDTH, REC_HEIGHT, Bitmap.Config.RGB_565)
        android.graphics.Canvas(padded).also { c ->
            c.drawColor(android.graphics.Color.WHITE)
            c.drawBitmap(resized, 0f, 0f, null)
        }
        val tensor  = bitmapToTensor(padded, REC_WIDTH, REC_HEIGHT)
        val inputs  = mapOf("x" to tensor)
        val output  = recSession!!.run(inputs)
        val logits  = output[0].value as Array<Array<FloatArray>>
        return ctcDecode(logits[0])
    }

    // ── CTC Decode ───────────────────────────────────────────
    private fun ctcDecode(logits: Array<FloatArray>): String? {
        val sb        = StringBuilder()
        var lastIdx   = charset.size // blank token = último índice
        for (step in logits) {
            val idx = step.indices.maxByOrNull { step[it] } ?: continue
            if (idx != lastIdx && idx < charset.size) {
                sb.append(charset[idx])
            }
            lastIdx = idx
        }
        return sb.toString().takeIf { it.isNotBlank() }
    }

    // ── Helpers ───────────────────────────────────────────────
    private fun bitmapToTensor(bmp: Bitmap, w: Int, h: Int): OnnxTensor {
        val buf = FloatBuffer.allocate(1 * 3 * h * w)
        val pixels = IntArray(w * h)
        bmp.getPixels(pixels, 0, w, 0, 0, w, h)
        for (channel in 0 until 3) {
            for (idx in pixels.indices) {
                val px = pixels[idx]
                val v = when (channel) {
                    0 -> ((px shr 16) and 0xFF) / 255f
                    1 -> ((px shr 8)  and 0xFF) / 255f
                    else -> (px and 0xFF) / 255f
                }
                buf.put((v - MEAN[channel]) / STD[channel])
            }
        }
        buf.rewind()
        return OnnxTensor.createTensor(
            env!!, buf, longArrayOf(1L, 3L, h.toLong(), w.toLong()))
    }

    private fun loadAndPrepareBitmap(path: String): Bitmap {
        val bmp = BitmapFactory.decodeFile(path)
            ?: throw IllegalArgumentException("No se pudo leer imagen: $path")
        // Ajustar si es muy grande (máx 4096px en el lado mayor)
        val maxSide = maxOf(bmp.width, bmp.height)
        if (maxSide <= 4096) return bmp
        val scale = 4096f / maxSide
        return Bitmap.createScaledBitmap(
            bmp,
            (bmp.width * scale).toInt(),
            (bmp.height * scale).toInt(),
            true,
        )
    }

    private fun rotateBitmap(bmp: Bitmap, degrees: Float): Bitmap {
        val m = Matrix().apply { postRotate(degrees) }
        return Bitmap.createBitmap(bmp, 0, 0, bmp.width, bmp.height, m, true)
    }

    private fun cropRegion(src: Bitmap, box: FloatArray): Bitmap {
        val x = box[0].toInt().coerceIn(0, src.width - 1)
        val y = box[1].toInt().coerceIn(0, src.height - 1)
        val w = (box[2] - box[0]).toInt().coerceIn(1, src.width - x)
        val h = (box[3] - box[1]).toInt().coerceIn(1, src.height - y)
        return Bitmap.createBitmap(src, x, y, w, h)
    }

    private fun parseProbabilityMap(
        probabilityMap: Array<FloatArray>,
        origW: Int,
        origH: Int,
        scaleX: Float,
        scaleY: Float,
        offsetX: Int,
        offsetY: Int,
    ): List<FloatArray> {
        // Agrupar filas contiguas del mapa DBNet en líneas de texto.
        // La versión anterior generaba una caja por fragmento horizontal y
        // además interpretaba mal la dimensión batch/canal del tensor ONNX.
        data class LineBox(
            var left: Int,
            var top: Int,
            var right: Int,
            var bottom: Int,
            var lastActiveRow: Int,
        )

        val boxes = mutableListOf<FloatArray>()
        var current: LineBox? = null
        val threshold = 0.3f
        val maxVerticalGap = 4
        val horizontalTolerance = 16

        fun emit(box: LineBox) {
            val x0 = ((box.left - offsetX) / scaleX).coerceIn(0f, origW.toFloat())
            val y0 = ((box.top - offsetY) / scaleY).coerceIn(0f, origH.toFloat())
            val x1 = ((box.right + 1 - offsetX) / scaleX).coerceIn(0f, origW.toFloat())
            val y1 = ((box.bottom + 1 - offsetY) / scaleY).coerceIn(0f, origH.toFloat())
            if (x1 - x0 >= 3f && y1 - y0 >= 3f) {
                boxes.add(floatArrayOf(x0, y0, x1, y1))
            }
        }

        for (rowIndex in probabilityMap.indices) {
            val row = probabilityMap[rowIndex]
            var left = -1
            var right = -1
            for (columnIndex in row.indices) {
                if (row[columnIndex] > threshold) {
                    if (left < 0) left = columnIndex
                    right = columnIndex
                }
            }

            if (left < 0) {
                if (current != null &&
                    rowIndex - current.lastActiveRow > maxVerticalGap
                ) {
                    emit(current)
                    current = null
                }
                continue
            }

            val existing = current
            if (existing == null) {
                current = LineBox(left, rowIndex, right, rowIndex, rowIndex)
                continue
            }

            val overlapsHorizontally =
                minOf(existing.right, right) >=
                    maxOf(existing.left, left) - horizontalTolerance
            val closeVertically =
                rowIndex - existing.lastActiveRow <= maxVerticalGap

            if (overlapsHorizontally && closeVertically) {
                existing.left = minOf(existing.left, left)
                existing.right = maxOf(existing.right, right)
                existing.bottom = rowIndex
                existing.lastActiveRow = rowIndex
            } else {
                emit(existing)
                current = LineBox(left, rowIndex, right, rowIndex, rowIndex)
            }
        }

        current?.let(::emit)
        return boxes
    }

    private fun loadCharset(): List<String> {
        return try {
            context.assets.open("models/ppocr_keys.txt")
                .bufferedReader().readLines()
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun assetBytes(assetPath: String): ByteArray {
        return context.assets.open(assetPath).readBytes()
    }

    fun release() {
        detSession?.close()
        clsSession?.close()
        recSession?.close()
        env?.close()
        env = null
    }
}
