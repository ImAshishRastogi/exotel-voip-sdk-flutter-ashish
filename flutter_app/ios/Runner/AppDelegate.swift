import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    
    lazy var flutterEngine = FlutterEngine(name: "my flutter engine")
    private var exotelSDKChannel:ExotelSDKChannel!
    
    
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      flutterEngine.run();
      exotelSDKChannel = ExotelSDKChannel(flutterEngine: flutterEngine)
      exotelSDKChannel.registerMethodChannel()
      
    GeneratedPluginRegistrant.register(with: flutterEngine)
    return true
  }
}
