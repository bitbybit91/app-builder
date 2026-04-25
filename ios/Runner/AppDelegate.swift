import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        GeneratedPluginRegistrant.register(with: self)

        #if !FDROID_BUILD
        // Firebase is only initialised for non-F-Droid builds.
        // The Firebase pod is not included in the fdroid scheme, so this block
        // must remain guarded by the compilation condition.
        FirebaseApp.configure()
        #endif

        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
