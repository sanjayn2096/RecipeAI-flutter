import 'pantry_grocery_lexicon.dart';
import 'pantry_label_mapper.dart';
import 'pantry_scan_suggestion.dart';
import 'pantry_vision_raw.dart';

/// Merges raw on-device vision signals into grouped [PantryScanSuggestion] rows.
abstract class PantryVisionMerge {
  PantryVisionMerge._();

  static const int maxGroups = 40;

  static List<PantryScanSuggestion> toSuggestions(PantryVisionRawResult raw) {
    final candidates = <_Candidate>[];

    for (final c in raw.classifications) {
      final mapped = PantryLabelMapper.mapIdentifier(c.identifier, c.confidence);
      if (mapped != null) {
        candidates.add(_Candidate.fromLabel(mapped, priority: 1));
      }
    }

    for (final c in raw.regionClassifications) {
      final mapped = PantryLabelMapper.mapIdentifier(c.identifier, c.confidence);
      if (mapped != null) {
        candidates.add(_Candidate.fromLabel(mapped, priority: 2));
      }
    }

    for (final line in raw.ocrLines) {
      final match = PantryGroceryLexicon.matchLine(line);
      if (match != null) {
        final hints = PantryGroceryLexicon.parseQuantityHints(line);
        candidates.add(
          _Candidate(
            name: match.name,
            confidence: match.confidence,
            quantity: hints.quantity,
            unit: hints.unit,
            priority: 3,
          ),
        );
      }
    }

    for (final code in raw.barcodes) {
      candidates.add(
        _Candidate(
          name: 'Product $code',
          confidence: 0.5,
          priority: 2,
        ),
      );
    }

    return _groupCandidates(candidates);
  }

  static List<PantryScanSuggestion> _groupCandidates(List<_Candidate> candidates) {
    candidates.sort((a, b) {
      final p = b.priority.compareTo(a.priority);
      if (p != 0) return p;
      return b.confidence.compareTo(a.confidence);
    });

    final groups = <_Group>[];

    for (final c in candidates) {
      final name = c.name.trim();
      if (name.isEmpty) continue;

      _Group? target;
      for (final g in groups) {
        if (_shouldMerge(g.primaryName, name) ||
            g.alternates.any((a) => _shouldMerge(a, name))) {
          target = g;
          break;
        }
      }

      if (target == null) {
        groups.add(
          _Group(
            primaryName: name,
            quantity: c.quantity,
            unit: c.unit,
            confidence: c.confidence,
            priority: c.priority,
          ),
        );
      } else {
        target.mergeCandidate(c);
      }

      if (groups.length >= maxGroups) break;
    }

    return groups.map((g) => g.toSuggestion()).toList();
  }

  /// True when two names likely refer to the same product (e.g. Milk / 2% Milk).
  static bool _shouldMerge(String a, String b) {
    final la = a.toLowerCase().trim();
    final lb = b.toLowerCase().trim();
    if (la == lb) return true;
    if (la.contains(lb) || lb.contains(la)) return true;

    final wordsA = la.split(RegExp(r'\s+'));
    final wordsB = lb.split(RegExp(r'\s+'));
    if (wordsA.isNotEmpty && wordsB.isNotEmpty) {
      final lastA = wordsA.last;
      final lastB = wordsB.last;
      if (lastA.length > 2 && lastA == lastB) return true;
    }
    return false;
  }
}

class _Group {
  _Group({
    required this.primaryName,
    this.quantity = '',
    this.unit = '',
    required this.confidence,
    required this.priority,
  });

  String primaryName;
  String quantity;
  String unit;
  double confidence;
  int priority;
  final List<String> alternates = [];

  void mergeCandidate(_Candidate c) {
    final name = c.name.trim();
    if (name.isEmpty) return;

    final allNames = {primaryName, ...alternates};
    if (allNames.contains(name)) {
      _maybeUpgradeQuantity(c);
      return;
    }

    // Prefer longer (more specific) name as primary.
    if (name.length > primaryName.length) {
      alternates.remove(name);
      if (primaryName != name) alternates.add(primaryName);
      primaryName = name;
      confidence = c.confidence;
      priority = c.priority;
    } else {
      alternates.add(name);
    }

    _maybeUpgradeQuantity(c);
    alternates.sort();
  }

  void _maybeUpgradeQuantity(_Candidate c) {
    if (quantity.isEmpty && c.quantity.isNotEmpty) quantity = c.quantity;
    if (unit.isEmpty && c.unit.isNotEmpty) unit = c.unit;
  }

  PantryScanSuggestion toSuggestion() {
    final uniqueAlternates = alternates
        .where((a) => a.trim().isNotEmpty && a != primaryName)
        .toSet()
        .toList()
      ..sort();
    return PantryScanSuggestion(
      primaryName: primaryName,
      quantity: quantity,
      unit: unit,
      alternates: uniqueAlternates,
    );
  }
}

class _Candidate {
  const _Candidate({
    required this.name,
    required this.confidence,
    this.quantity = '',
    this.unit = '',
    this.priority = 1,
  });

  factory _Candidate.fromLabel(MappedLabel label, {required int priority}) =>
      _Candidate(
        name: label.name,
        confidence: label.confidence,
        priority: priority,
      );

  final String name;
  final double confidence;
  final String quantity;
  final String unit;
  final int priority;
}
