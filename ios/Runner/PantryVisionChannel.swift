import Flutter
import Foundation

enum PantryVisionChannel {
  private static let channelName = "com.recipeai/pantry_vision"

  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger)
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "analyzePantryImage":
        handleAnalyze(call: call, result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private static func handleAnalyze(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard let args = call.arguments as? [String: Any],
          let typedData = args["bytes"] as? FlutterStandardTypedData else {
      result(
        FlutterError(
          code: "invalid_args",
          message: "Expected bytes and mimeType",
          details: nil
        )
      )
      return
    }

    let mimeType = (args["mimeType"] as? String) ?? "image/jpeg"
    let bytes = typedData.data

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let payload = try PantryVisionAnalyzer.analyze(bytes: bytes, mimeType: mimeType)
        let encoder = JSONEncoder()
        let data = try encoder.encode(payload)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        DispatchQueue.main.async {
          result(json)
        }
      } catch {
        DispatchQueue.main.async {
          result(
            FlutterError(
              code: "vision_failed",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
  }
}
