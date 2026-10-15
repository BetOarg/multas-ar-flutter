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
                "isAvailable" -> result.success(hasRequiredModels())
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

    // ── Disponibilidad real del motor ─────────────────────────
    private fun hasRequiredModels(): Boolean {
        val required = listOf(
            "flutter_assets/assets/models/det.onnx",
            "flutter_assets/assets/models/cls.onnx",
            "flutter_assets/assets/models/rec.onnx",
            "flutter_assets/assets/models/ppocr_keys.txt",
        )
        return required.all { path ->
            try {
                context.assets.open(path).use { true }
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

        detSession = env!!.createSession(assetBytes("assets/models/det.onnx"), opts)
        clsSession = env!!.createSession(assetBytes("assets/models/cls.onnx"), opts)
        recSession = env!!.createSession(assetBytes("assets/models/rec.onnx"), opts)
        charset    = loadCharset()
    }

    // ── Detección de regiones de texto ───────────────────────
    private fun detect(bitmap: Bitmap): List<FloatArray> {
        val resized = Bitmap.createScaledBitmap(bitmap, DET_SIZE, DET_SIZE, true)
        val tensor  = bitmapToTensor(resized, DET_SIZE, DET_SIZE)
        val inputs  = mapOf("x" to tensor)
        val output  = detSession!!.run(inputs)
        val map     = output[0].value as Array<*>

        // Parsear mapa de probabilidades → bounding boxes
        // Implementación simplificada: threshold 0.3, dilate, contours
        return parseProbabilityMap(map, DET_SIZE, DET_SIZE,
                                   bitmap.width, bitmap.height)
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
        map: Array<*>, detW: Int, detH: Int,
        origW: Int, origH: Int,
    ): List<FloatArray> {
        // Threshold + coordenadas escaladas al tamaño original
        // Implementación básica: retorna lista de [x0,y0,x1,y1]
        val scaleX = origW.toFloat() / detW
        val scaleY = origH.toFloat() / detH
        val boxes  = mutableListOf<FloatArray>()
        @Suppress("UNCHECKED_CAST")
        val prob = map as? Array<Array<FloatArray>> ?: return boxes
        val rows = prob[0]
        var inRegion  = false
        var regionTop = 0
        var regionLeft = 0
        for (r in rows.indices) {
            for (c in rows[r].indices) {
                val p = rows[r][c]
                if (p > 0.3f && !inRegion) {
                    inRegion   = true
                    regionTop  = r
                    regionLeft = c
                } else if (p <= 0.3f && inRegion) {
                    inRegion = false
                    boxes.add(floatArrayOf(
                        regionLeft * scaleX, regionTop  * scaleY,
                        c          * scaleX, (r + 1)    * scaleY,
                    ))
                }
            }
        }
        return boxes
    }

    private fun loadCharset(): List<String> {
        return try {
            context.assets.open("flutter_assets/assets/models/ppocr_keys.txt")
                .bufferedReader().readLines()
        } catch (e: Exception) {
            emptyList()
        }
    }

    private fun assetBytes(assetPath: String): ByteArray {
        return context.assets.open("flutter_assets/$assetPath").use { it.readBytes() }
    }

    fun release() {
        detSession?.close()
        clsSession?.close()
        recSession?.close()
        env?.close()
        env = null
    }
}
