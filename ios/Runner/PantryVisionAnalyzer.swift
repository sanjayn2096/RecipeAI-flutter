import Foundation
import UIKit
import Vision

/// Runs on-device Vision requests for pantry / grocery photo analysis.
enum PantryVisionAnalyzer {
  private static let minConfidence: Float = 0.35
  private static let maxRegionCrops = 5

  struct ClassificationPayload: Encodable {
    let identifier: String
    let confidence: Double
  }

  struct ResultPayload: Encodable {
    let classifications: [ClassificationPayload]
    let regionClassifications: [ClassificationPayload]
    let ocrLines: [String]
    let barcodes: [String]
  }

  static func analyze(bytes: Data, mimeType: String) throws -> ResultPayload {
    guard let image = UIImage(data: bytes), let cgImage = image.cgImage else {
      throw NSError(
        domain: "PantryVision",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "Could not decode image"]
      )
    }

    let orientation = CGImagePropertyOrientation(image.imageOrientation)
    let handler = VNImageRequestHandler(cgImage: cgImage, orientation: orientation, options: [:])

    let classifyRequest = VNClassifyImageRequest()
    let textRequest = VNRecognizeTextRequest()
    textRequest.recognitionLevel = .accurate
    textRequest.usesLanguageCorrection = true

    let barcodeRequest = VNDetectBarcodesRequest()
    barcodeRequest.symbologies = [.ean13, .ean8, .upce, .code128, .code39, .qr]

    let saliencyRequest = VNGenerateObjectnessBasedSaliencyImageRequest()

    try handler.perform([classifyRequest, textRequest, barcodeRequest, saliencyRequest])

    var classifications = parseClassifications(classifyRequest.results)
    let ocrLines = parseOcrLines(textRequest.results)
    let barcodes = parseBarcodes(barcodeRequest.results)

    var regionClassifications: [ClassificationPayload] = []
    if let saliency = saliencyRequest.results?.first as? VNSaliencyImageObservation {
      regionClassifications = classifyRegions(
        cgImage: cgImage,
        orientation: orientation,
        saliency: saliency
      )
    }

    // Boost recall: region hits not in whole-image set are still useful.
    classifications = mergeClassifications(classifications, regionClassifications)

    return ResultPayload(
      classifications: classifications,
      regionClassifications: regionClassifications,
      ocrLines: ocrLines,
      barcodes: barcodes
    )
  }

  private static func parseClassifications(_ results: [Any]?) -> [ClassificationPayload] {
    guard let observations = results as? [VNClassificationObservation] else { return [] }
    return observations
      .filter { $0.confidence >= minConfidence }
      .prefix(25)
      .map {
        ClassificationPayload(
          identifier: $0.identifier,
          confidence: Double($0.confidence)
        )
      }
  }

  private static func parseOcrLines(_ results: [Any]?) -> [String] {
    guard let observations = results as? [VNRecognizedTextObservation] else { return [] }
    var lines: [String] = []
    for obs in observations {
      guard let candidate = obs.topCandidates(1).first else { continue }
      let text = candidate.string.trimmingCharacters(in: .whitespacesAndNewlines)
      if text.count >= 3 {
        lines.append(text)
      }
    }
    return Array(Set(lines)).sorted()
  }

  private static func parseBarcodes(_ results: [Any]?) -> [String] {
    guard let observations = results as? [VNBarcodeObservation] else { return [] }
    var codes: [String] = []
    for obs in observations {
      if let payload = obs.payloadStringValue?.trimmingCharacters(in: .whitespacesAndNewlines),
         !payload.isEmpty {
        codes.append(payload)
      }
    }
    return Array(Set(codes))
  }

  private static func classifyRegions(
    cgImage: CGImage,
    orientation: CGImagePropertyOrientation,
    saliency: VNSaliencyImageObservation
  ) -> [ClassificationPayload] {
    let objects = saliency.salientObjects ?? []
    let sorted = objects.sorted { $0.confidence > $1.confidence }
    var out: [ClassificationPayload] = []

    for obj in sorted.prefix(maxRegionCrops) {
      guard let crop = cropImage(cgImage, normalizedRect: obj.boundingBox) else { continue }
      let handler = VNImageRequestHandler(cgImage: crop, orientation: orientation, options: [:])
      let request = VNClassifyImageRequest()
      do {
        try handler.perform([request])
        let hits = parseClassifications(request.results)
        out.append(contentsOf: hits.prefix(3))
      } catch {
        continue
      }
    }

    return dedupeClassifications(out)
  }

  private static func cropImage(_ image: CGImage, normalizedRect: CGRect) -> CGImage? {
    let width = CGFloat(image.width)
    let height = CGFloat(image.height)
    // Vision bounding boxes are normalized with origin bottom-left.
    var rect = normalizedRect
    rect.origin.y = 1.0 - rect.origin.y - rect.size.height
    let pixelRect = CGRect(
      x: rect.origin.x * width,
      y: rect.origin.y * height,
      width: rect.size.width * width,
      height: rect.size.height * height
    ).integral

    guard pixelRect.width > 8, pixelRect.height > 8 else { return nil }
    return image.cropping(to: pixelRect)
  }

  private static func mergeClassifications(
    _ whole: [ClassificationPayload],
    _ regions: [ClassificationPayload]
  ) -> [ClassificationPayload] {
    var map: [String: ClassificationPayload] = [:]
    for item in whole + regions {
      if let existing = map[item.identifier] {
        if item.confidence > existing.confidence {
          map[item.identifier] = item
        }
      } else {
        map[item.identifier] = item
      }
    }
    return map.values.sorted { $0.confidence > $1.confidence }
  }

  private static func dedupeClassifications(_ items: [ClassificationPayload]) -> [ClassificationPayload] {
    var map: [String: ClassificationPayload] = [:]
    for item in items {
      if let existing = map[item.identifier] {
        if item.confidence > existing.confidence {
          map[item.identifier] = item
        }
      } else {
        map[item.identifier] = item
      }
    }
    return map.values.sorted { $0.confidence > $1.confidence }
  }
}

private extension CGImagePropertyOrientation {
  init(_ orientation: UIImage.Orientation) {
    switch orientation {
    case .up: self = .up
    case .down: self = .down
    case .left: self = .left
    case .right: self = .right
    case .upMirrored: self = .upMirrored
    case .downMirrored: self = .downMirrored
    case .leftMirrored: self = .leftMirrored
    case .rightMirrored: self = .rightMirrored
    @unknown default: self = .up
    }
  }
}
