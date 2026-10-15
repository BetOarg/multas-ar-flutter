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

        OcrPlugin.register(
            with: controller.registrar(
                forPlugin: "OcrPlugin")!)

        return super.application(
            application,
            didFinishLaunchingWithOptions: launchOptions)
    }
}
