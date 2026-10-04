import Flutter
import UIKit
import AVKit
import FirebaseCore
import FirebaseAuth

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate, AVPictureInPictureControllerDelegate {
  // MARK: - Properties
  var pipController: AVPictureInPictureController?
  var player: AVPlayer?
  var playerLayer: AVPlayerLayer?

  var isPlaying: Bool = false
  var playbackPosition: Int = 0
  var videoUrl: String?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    application.registerForRemoteNotifications()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  override func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
  ) {
    Auth.auth().setAPNSToken(deviceToken, type: AuthAPNSTokenType.unknown)
    super.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
  }

  override func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable : Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
  ) {
    if Auth.auth().canHandleNotification(userInfo) {
      completionHandler(.noData)
      return
    }
    completionHandler(.noData)
  }

  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    if Auth.auth().canHandle(url) {
      return true
    }
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    guard let controller = window?.rootViewController as? FlutterViewController else {
        return
    }

    let pipChannel = FlutterMethodChannel(
        name: "com.javstory.prjkt/pip",
        binaryMessenger: controller.binaryMessenger
    )

    pipChannel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }

        switch call.method {

        case "updateVideoState":
            if let args = call.arguments as? [String: Any] {
                self.isPlaying = args["isPlaying"] as? Bool ?? false
                self.playbackPosition = args["position"] as? Int ?? 0
                self.videoUrl = args["videoUrl"] as? String
            }
            result(nil)

        case "videoProgress":
            if let args = call.arguments as? [String: Any] {
                self.playbackPosition = args["position"] as? Int ?? 0
            }
            result(nil)

        case "enterPipMode":
            if let args = call.arguments as? [String: Any] {
                self.playbackPosition = args["position"] as? Int ?? 0
                self.videoUrl = args["videoUrl"] as? String
            }
            self.enterPipMode()
            result(nil)

        default:
            result(FlutterMethodNotImplemented)
        }
    }
  }

  // MARK: - App Lifecycle

  override func applicationWillResignActive(_ application: UIApplication) {
      if isPlaying {
          enterPipMode()
      }
  }

  override func applicationDidEnterBackground(_ application: UIApplication) {
      if let pipController = pipController,
          !pipController.isPictureInPictureActive {
          pipController.startPictureInPicture()
      }
  }

  // MARK: - PiP Logic

  func enterPipMode() {

      guard let videoUrl = videoUrl,
            let rootVC = window?.rootViewController,
            let url = URL(string: videoUrl),
            AVPictureInPictureController.isPictureInPictureSupported()
      else {
          return
      }

      DispatchQueue.main.async {

          // Recreate player if URL changed
          if self.player == nil ||
              (self.player?.currentItem?.asset as? AVURLAsset)?.url != url {

              self.player = AVPlayer(url: url)
          }

          guard let player = self.player else { return }

          // Seek correctly
          let time = CMTime(seconds: Double(self.playbackPosition),
                            preferredTimescale: 600)
          player.seek(to: time)

          player.play()

          // Attach invisible player layer
          if self.playerLayer == nil {
              self.playerLayer = AVPlayerLayer(player: player)
              self.playerLayer?.frame = CGRect(x: 0, y: 0, width: 1, height: 1)
              rootVC.view.layer.addSublayer(self.playerLayer!)
          }

          // Initialize PiP controller once
          if self.pipController == nil {
              self.pipController = AVPictureInPictureController(playerLayer: self.playerLayer!)
              self.pipController?.delegate = self
          }

          if let pipController = self.pipController,
              !pipController.isPictureInPictureActive {
              pipController.startPictureInPicture()
          }
      }
  }

  // MARK: - PiP Delegate Cleanup

  func pictureInPictureControllerDidStopPictureInPicture(
      _ controller: AVPictureInPictureController
  ) {
      player?.pause()
      playerLayer?.removeFromSuperlayer()
      playerLayer = nil
      pipController = nil
  }
}
