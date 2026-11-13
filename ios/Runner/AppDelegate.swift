import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var imagePickerDelegate: DeviceImagePickerDelegate?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let channel = FlutterMethodChannel(
      name: "findit/device_image_picker",
      binaryMessenger: engineBridge.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "pickImage" else {
        result(FlutterMethodNotImplemented)
        return
      }
      self?.pickImage(result: result)
    }
  }

  private func pickImage(result: @escaping FlutterResult) {
    guard UIImagePickerController.isSourceTypeAvailable(.photoLibrary),
          let rootViewController = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)?.rootViewController else {
      result(FlutterError(
        code: "picker_unavailable",
        message: "Pemilih foto tidak tersedia.",
        details: nil
      ))
      return
    }

    let picker = UIImagePickerController()
    let delegate = DeviceImagePickerDelegate(result: result)
    imagePickerDelegate = delegate
    picker.delegate = delegate
    picker.sourceType = .photoLibrary
    rootViewController.present(picker, animated: true)
  }
}

private final class DeviceImagePickerDelegate: NSObject,
  UIImagePickerControllerDelegate,
  UINavigationControllerDelegate {
  private let result: FlutterResult

  init(result: @escaping FlutterResult) {
    self.result = result
  }

  func imagePickerController(
    _ picker: UIImagePickerController,
    didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
  ) {
    let imageData = (info[.originalImage] as? UIImage)?
      .jpegData(compressionQuality: 0.9)
    picker.dismiss(animated: true) {
      if let imageData {
        self.result(FlutterStandardTypedData(bytes: imageData))
      } else {
        self.result(nil)
      }
    }
  }

  func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
    picker.dismiss(animated: true) {
      self.result(nil)
    }
  }
}
