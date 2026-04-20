import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../core/grocery_ingredient_normalize.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/models/grocery_item.dart';
import '../data/repositories/grocery_list_repository.dart';

class GroceryListViewModel extends ChangeNotifier {
  GroceryListViewModel({
    required GroceryListRepository repository,
    required AppTelemetry appTelemetry,
    FirebaseAuth? firebaseAuth,
  })  : _repo = repository,
        _telemetry = appTelemetry,
        _auth = firebaseAuth ?? FirebaseAuth.instance;

  final GroceryListRepository _repo;
  final AppTelemetry _telemetry;
  final FirebaseAuth _auth;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<List<GroceryItem>>? _fireSub;

  List<GroceryItem> _items = [];
  List<GroceryItem> get items => List.unmodifiable(_items);

  bool _ready = false;
  bool get ready => _ready;

  Future<void> init() async {
    _authSub = _auth.authStateChanges().listen(_onAuthChanged);
    await _onAuthChanged(_auth.currentUser);
    _ready = true;
    notifyListeners();
  }

  Future<void> _onAuthChanged(User? user) async {
    await _fireSub?.cancel();
    _fireSub = null;

    if (user != null) {
      final guestItems = _repo.readGuestListSync();
      if (guestItems.isNotEmpty) {
        await _repo.batchAddToFirestore(user.uid, guestItems);
        await _repo.clearGuestList();
        await _telemetry.logFeatureInteraction(
          featureId: FeatureIds.groceryMergeGuestToCloud,
        );
      }
      _fireSub = _repo.watchFirestoreList(user.uid).listen((list) {
        _items = list;
        notifyListeners();
      });
    } else {
      _items = _repo.readGuestListSync();
      notifyListeners();
    }
  }

  bool get _isCloudUser => _auth.currentUser != null;

  Future<void> _persistGuest() async {
    await _repo.writeGuestList(_items);
    notifyListeners();
  }

  /// Adds ingredient lines from a recipe; merges rows with the same normalized name.
  Future<void> addLinesFromRecipe({
    required List<String> lines,
    String? recipeId,
    String? recipeName,
  }) async {
    if (lines.isEmpty) return;
    final now = DateTime.now();

    if (_isCloudUser) {
      for (final raw in lines) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) continue;
        final parsed =
            GroceryIngredientNormalize.normalizeRecipeIngredientLine(trimmed);
        final norm = GroceryItem.normalizeName(parsed.displayName);
        final idx = _items.indexWhere(
          (e) =>
              GroceryItem.normalizeName(e.name) == norm &&
              sameRecipeSource(e, recipeId, recipeName),
        );
        if (idx >= 0) {
          final existing = _items[idx];
          final merged = existing.copyWith(
            updatedAt: now,
            note: _mergeDuplicateNote(existing.note),
            sourceRecipeId: recipeId ?? existing.sourceRecipeId,
            sourceRecipeName: recipeName ?? existing.sourceRecipeName,
          );
          await _repo.upsertFirestore(merged);
        } else {
          await _repo.upsertFirestore(
            GroceryItem(
              id: GroceryItem.newId(),
              name: parsed.displayName,
              quantity: parsed.quantity,
              unit: parsed.unit,
              createdAt: now,
              updatedAt: now,
              sourceRecipeId: recipeId,
              sourceRecipeName: recipeName,
            ),
          );
        }
      }
    } else {
      var next = List<GroceryItem>.from(_items);
      for (final raw in lines) {
        final trimmed = raw.trim();
        if (trimmed.isEmpty) continue;
        final parsed =
            GroceryIngredientNormalize.normalizeRecipeIngredientLine(trimmed);
        final norm = GroceryItem.normalizeName(parsed.displayName);
        final idx = next.indexWhere(
          (e) =>
              GroceryItem.normalizeName(e.name) == norm &&
              sameRecipeSource(e, recipeId, recipeName),
        );
        if (idx >= 0) {
          final existing = next[idx];
          next[idx] = existing.copyWith(
            updatedAt: now,
            note: _mergeDuplicateNote(existing.note),
            sourceRecipeId: recipeId ?? existing.sourceRecipeId,
            sourceRecipeName: recipeName ?? existing.sourceRecipeName,
          );
        } else {
          next.add(
            GroceryItem(
              id: GroceryItem.newId(),
              name: parsed.displayName,
              quantity: parsed.quantity,
              unit: parsed.unit,
              createdAt: now,
              updatedAt: now,
              sourceRecipeId: recipeId,
              sourceRecipeName: recipeName,
            ),
          );
        }
      }
      _items = next;
      await _persistGuest();
    }
    await _telemetry.logFeatureInteraction(
      featureId: FeatureIds.groceryAddFromRecipe,
    );
  }

  /// Same recipe bucket: merge by name only when from the same recipe (or both manual).
  static bool sameRecipeSource(
    GroceryItem existing,
    String? recipeId,
    String? recipeName,
  ) {
    final rid = recipeId?.trim() ?? '';
    final erid = existing.sourceRecipeId?.trim() ?? '';
    if (rid.isNotEmpty || erid.isNotEmpty) {
      return rid == erid;
    }
    final rname = recipeName?.trim() ?? '';
    final ename = existing.sourceRecipeName?.trim() ?? '';
    return rname == ename;
  }

  String? _mergeDuplicateNote(String? existing) {
    const tag = '(duplicate line merged)';
    if (existing == null || existing.isEmpty) return tag;
    if (existing.contains(tag)) return existing;
    return '$existing $tag';
  }

  Future<void> addManualItem({
    required String name,
    String? quantity,
    String? unit,
    String? note,
  }) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    final item = GroceryItem(
      id: GroceryItem.newId(),
      name: trimmed,
      quantity:
          quantity == null || quantity.trim().isEmpty ? null : quantity.trim(),
      unit: unit == null || unit.trim().isEmpty ? null : unit.trim(),
      note: note == null || note.trim().isEmpty ? null : note.trim(),
      createdAt: now,
      updatedAt: now,
    );
    if (_isCloudUser) {
      await _repo.upsertFirestore(item);
    } else {
      _items = [..._items, item];
      await _persistGuest();
    }
    await _telemetry.logFeatureInteraction(featureId: FeatureIds.groceryAddManual);
  }

  Future<void> updateItem(GroceryItem item) async {
    if (_isCloudUser) {
      await _repo.upsertFirestore(item);
    } else {
      final i = _items.indexWhere((e) => e.id == item.id);
      if (i < 0) return;
      _items = List<GroceryItem>.from(_items)..[i] = item;
      await _persistGuest();
    }
  }

  Future<void> deleteItem(String id) async {
    if (_isCloudUser) {
      await _repo.deleteFirestore(id);
    } else {
      _items = _items.where((e) => e.id != id).toList();
      await _persistGuest();
    }
    await _telemetry.logFeatureInteraction(featureId: FeatureIds.groceryDeleteItem);
  }

  Future<void> setChecked(String id, bool checked) async {
    final i = _items.indexWhere((e) => e.id == id);
    if (i < 0) return;
    final updated = _items[i].copyWith(
      isChecked: checked,
      updatedAt: DateTime.now(),
    );
    await updateItem(updated);
  }

  Future<void> clearCheckedItems() async {
    final toClear = _items.where((e) => e.isChecked).map((e) => e.id).toList();
    if (toClear.isEmpty) return;
    if (_isCloudUser) {
      for (final id in toClear) {
        await _repo.deleteFirestore(id);
      }
    } else {
      _items = _items.where((e) => !e.isChecked).toList();
      await _persistGuest();
    }
    await _telemetry.logFeatureInteraction(featureId: FeatureIds.groceryClearChecked);
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _fireSub?.cancel();
    super.dispose();
  }
}
