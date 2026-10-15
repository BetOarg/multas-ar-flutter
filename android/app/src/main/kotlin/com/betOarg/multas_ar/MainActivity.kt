package com.betOarg.multas_ar

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel

// ══════════════════════════════════════════════════════════════════
// MAIN ACTIVITY
// Registra los platform channels nativos:
//   - OcrChannel  → PaddleOCR vía ONNX Runtime
// El scope se cancela con el ciclo de vida de la Activity.
// ══════════════════════════════════════════════════════════════════

class MainActivity : FlutterActivity() {

    private val activityScope = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private lateinit var ocrChannel: OcrChannel

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        ocrChannel = OcrChannel(applicationContext, activityScope)
        ocrChannel.register(flutterEngine)
    }

    override fun onDestroy() {
        ocrChannel.release()
        activityScope.cancel()
        super.onDestroy()
    }
}
