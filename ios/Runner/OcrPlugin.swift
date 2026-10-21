import Flutter
import UIKit
import Vision

// ══════════════════════════════════════════════════════════════════
// OCR PLUGIN — iOS
// Platform channel Flutter ↔ Swift usando Apple Vision Framework.
// VNRecognizeTextRequest con accuracyLevel = .accurate.
// Idiomas: es-419 (español latinoamérica), es-ES, en-US (fallback).
// ══════════════════════════════════════════════════════════════════

@objc class OcrPlugin: NSObject, FlutterPlugin {

    static let channel = "com.betOarg.multas_ar/ocr"

    // ── Registro del plugin ───────────────────────────────────
    static func register(with registrar: FlutterPluginRegistrar) {
        let ch = FlutterMethodChannel(
            name: channel,
            binaryMessenger: registrar.messenger()
        )
        let instance = OcrPlugin()
        registrar.addMethodCallDelegate(instance, channel: ch)
    }

    // ── Dispatch de métodos ───────────────────────────────────
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {

        case "recognizeImage":
            guard
                let args = call.arguments as? [String: Any],
                let imagePath = args["imagePath"] as? String
            else {
                result(FlutterError(
                    code: "INVALID_ARG",
                    message: "imagePath requerido",
                    details: nil))
                return
            }
            recognizeImage(path: imagePath, result: result)

        case "isAvailable":
            // Vision disponible desde iOS 13
            result(true)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // ── Reconocimiento principal ──────────────────────────────
    private func recognizeImage(path: String, result: @escaping FlutterResult) {
        DispatchQueue.global(qos: .userInitiated).async {
            guard
                let uiImage = UIImage(contentsOfFile: path),
                let cgImage = uiImage.cgImage
            else {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "IMAGE_ERROR",
                        message: "No se pudo cargar la imagen: \(path)",
                        details: nil))
                }
                return
            }

            let request = VNRecognizeTextRequest { req, err in
                if let err = err {
                    DispatchQueue.main.async {
                        result(FlutterError(
                            code: "VISION_ERROR",
                            message: err.localizedDescription,
                            details: nil))
                    }
                    return
                }

                let observations = req.results as? [VNRecognizedTextObservation] ?? []

                // Ordenar por posición vertical (top → bottom) y luego horizontal
                let sorted = observations.sorted {
                    let dy = $1.boundingBox.maxY - $0.boundingBox.maxY
                    if abs(dy) > 0.02 { return dy < 0 }          // misma línea si Δy < 2%
                    return $0.boundingBox.minX < $1.boundingBox.minX
                }

                let lines = sorted.compactMap { obs -> String? in
                    obs.topCandidates(1).first?.string
                }

                let texto = lines.joined(separator: "\n")
                DispatchQueue.main.async {
                    result(texto)
                }
            }

            // Configuración de precisión
            request.recognitionLevel     = .accurate
            request.usesLanguageCorrection = true
            request.minimumTextHeight    = 0.01   // ignorar texto muy pequeño

            // Idiomas preferidos: español latinoamericano primero
            if #available(iOS 16.0, *) {
                request.recognitionLanguages = ["es-419", "es-ES", "en-US"]
            } else {
                request.recognitionLanguages = ["es-ES", "en-US"]
            }

            let handler = VNImageRequestHandler(
                cgImage: cgImage,
                orientation: self.cgOrientation(from: uiImage),
                options: [:]
            )

            do {
                try handler.perform([request])
            } catch {
                DispatchQueue.main.async {
                    result(FlutterError(
                        code: "HANDLER_ERROR",
                        message: error.localizedDescription,
                        details: nil))
                }
            }
        }
    }

    // ── Orientación EXIF → CGImagePropertyOrientation ────────
    private func cgOrientation(from image: UIImage) -> CGImagePropertyOrientation {
        switch image.imageOrientation {
        case .up:            return .up
        case .down:          return .down
        case .left:          return .left
        case .right:         return .right
        case .upMirrored:    return .upMirrored
        case .downMirrored:  return .downMirrored
        case .leftMirrored:  return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default:    return .up
        }
    }
}
