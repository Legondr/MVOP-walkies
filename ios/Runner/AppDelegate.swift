import UIKit
import Flutter
import GoogleMaps  // Import the Google Maps package

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Initialize Google Maps SDK
    GMSServices.provideAPIKey("AIzaSyDDgt0QnrDwiztOKcB9PLa-SMlmLrYQmNE")

    // Standard Flutter app initialization
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
