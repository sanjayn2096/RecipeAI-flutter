import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../core/constants.dart';
import '../models/grocery_item.dart';

/// Local grocery list when no Firebase user (guest mode or signed out).
class GroceryHiveStore {
  GroceryHiveStore(this._box);

  final Box<String> _box;

  static const String _payloadKey = 'guest_items';

  List<GroceryItem> readListSync() {
    final raw = _box.get(_payloadKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => GroceryItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> writeList(List<GroceryItem> items) async {
    final jsonStr = jsonEncode(items.map((e) => e.toJson()).toList());
    await _box.put(_payloadKey, jsonStr);
  }

  Future<void> clear() async {
    await _box.delete(_payloadKey);
  }

  static Future<Box<String>> openBox() {
    return Hive.openBox<String>(AppConstants.hiveGroceryBox);
  }
}
