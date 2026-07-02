/// Raw on-device vision output from the platform channel (iOS / Android).
class PantryVisionRawResult {
  const PantryVisionRawResult({
    this.classifications = const [],
    this.regionClassifications = const [],
    this.ocrLines = const [],
    this.barcodes = const [],
  });

  final List<PantryVisionClassification> classifications;
  final List<PantryVisionClassification> regionClassifications;
  final List<String> ocrLines;
  final List<String> barcodes;

  factory PantryVisionRawResult.fromJson(Map<String, dynamic> json) {
    return PantryVisionRawResult(
      classifications: _parseClassifications(json['classifications']),
      regionClassifications: _parseClassifications(json['regionClassifications']),
      ocrLines: _parseStringList(json['ocrLines']),
      barcodes: _parseStringList(json['barcodes']),
    );
  }

  static List<PantryVisionClassification> _parseClassifications(dynamic raw) {
    if (raw is! List) return const [];
    final out = <PantryVisionClassification>[];
    for (final e in raw) {
      if (e is! Map) continue;
      final map = Map<String, dynamic>.from(e);
      final id = (map['identifier'] ?? '').toString().trim();
      if (id.isEmpty) continue;
      final confRaw = map['confidence'];
      final conf = confRaw is num ? confRaw.toDouble().clamp(0.0, 1.0) : 0.0;
      out.add(PantryVisionClassification(identifier: id, confidence: conf));
    }
    return out;
  }

  static List<String> _parseStringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
}

class PantryVisionClassification {
  const PantryVisionClassification({
    required this.identifier,
    required this.confidence,
  });

  final String identifier;
  final double confidence;
}
