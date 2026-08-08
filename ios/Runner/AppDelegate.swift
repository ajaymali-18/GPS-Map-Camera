import Flutter
import UIKit
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var audioPlayer: AVAudioPlayer?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let shutterChannel = FlutterMethodChannel(name: "com.tachyonbyte.opengps/shutter_sound",
                                              binaryMessenger: controller.binaryMessenger)

    let key = FlutterDartProject.lookupKey(forAsset: "assets/sound/camera_shutter.mp3")
    if let path = Bundle.main.path(forResource: key, ofType: nil) {
      let url = URL(fileURLWithPath: path)
      try? audioPlayer = AVAudioPlayer(contentsOf: url)
      audioPlayer?.prepareToPlay()
    }

    shutterChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "playShutterSound" {
        self?.audioPlayer?.stop()
        self?.audioPlayer?.currentTime = 0
        self?.audioPlayer?.play()
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
