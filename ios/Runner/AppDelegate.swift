import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Registrar plugins generados por Flutter
        GeneratedPluginRegistrant.register(with: self)

        // Registrar OcrPlugin (Apple Vision)
        guard let controller = window?.rootViewController
                as? FlutterViewController
        else {
            return super.application(
                application,
                didFinishLaunchingWithOptions: launchOptions)
        }

        // Keep local case data out of iCloud/device backups.
        let privacyChannel = FlutterMethodChannel(
            name: "com.betOarg.multas_ar/privacy",
            binaryMessenger: controller.binaryMessenger
        )
        privacyChannel.setMethodCallHandler { call, result in
            guard call.method == "excludeFromBackup",
                  let args = call.arguments as? [String: String],
                  let path = args["path"] else {
                result(FlutterMethodNotImplemented)
                return
            }
            var url = URL(fileURLWithPath: path, isDirectory: true)
            var values = URLResourceValues()
            values.isExcludedFromBackup = true
            do {
                try url.setResourceValues(values)
                result(nil)
            } catch {
                result(FlutterError(
                    code: "BACKUP_EXCLUSION_FAILED",
                    message: error.localizedDescription,
                    details: nil
                ))
            }
        }

        OcrPlugin.register(
            with: controller.registrar(
                forPlugin: "OcrPlugin")!)

        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions)
    }
}
