import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../core/firestore_paths.dart';
import '../../core/telemetry/firestore_activity_metrics.dart';
import '../local/grocery_hive_store.dart';
import '../models/grocery_item.dart';

/// Persists grocery items: Firestore for signed-in users, Hive for guest / no Firebase user.
class GroceryListRepository {
  GroceryListRepository({
    required GroceryHiveStore hiveStore,
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
    FirestoreActivityCallback? onFirestoreActivity,
  })  : _hive = hiveStore,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? FirebaseAuth.instance,
        _onFirestoreActivity = onFirestoreActivity;

  final GroceryHiveStore _hive;
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final FirestoreActivityCallback? _onFirestoreActivity;

  void _logFirestore(FirestoreActivityMetrics metrics) {
    _onFirestoreActivity?.call(metrics);
  }

  CollectionReference<Map<String, dynamic>> _userGroceryCol(String uid) {
    return _firestore
        .collection(FirestorePaths.usersCollection)
        .doc(uid)
        .collection(FirestorePaths.grocerySubcollection);
  }

  Stream<List<GroceryItem>> watchFirestoreList(String uid) {
    final col = _userGroceryCol(uid);
    final stream = col
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      if (_onFirestoreActivity != null) {
        _logFirestore(
          FirestoreActivityMetrics(
            operation: 'listen_snapshot',
            collection: 'users/*/groceryItems',
            docCount: snap.docs.length,
          ),
        );
      }
      return snap.docs
          .map((d) => GroceryItem.fromFirestoreDoc(d.id, d.data()))
          .toList();
    });
    return stream;
  }

  List<GroceryItem> readGuestListSync() => _hive.readListSync();

  Future<void> writeGuestList(List<GroceryItem> items) =>
      _hive.writeList(items);

  Future<void> clearGuestList() => _hive.clear();

  Future<void> upsertFirestore(GroceryItem item) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _logFirestore(
      FirestoreActivityMetrics(
        operation: 'write',
        collection: 'users/*/groceryItems',
        docCount: 1,
      ),
    );
    final col = _userGroceryCol(uid);
    await col.doc(item.id).set(item.toFirestoreMap());
  }

  Future<void> deleteFirestore(String itemId) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    _logFirestore(
      FirestoreActivityMetrics(
        operation: 'delete',
        collection: 'users/*/groceryItems',
        docCount: 1,
      ),
    );
    await _userGroceryCol(uid).doc(itemId).delete();
  }

  /// Uploads guest items after sign-in (caller clears Hive after success).
  Future<void> batchAddToFirestore(String uid, List<GroceryItem> items) async {
    if (items.isEmpty) return;
    _logFirestore(
      FirestoreActivityMetrics(
        operation: 'batch_write',
        collection: 'users/*/groceryItems',
        docCount: items.length,
      ),
    );
    final col = _userGroceryCol(uid);
    final batch = _firestore.batch();
    final now = DateTime.now();
    for (final item in items) {
      final merged = item.copyWith(
        updatedAt: now,
        createdAt: item.createdAt.isBefore(now) ? item.createdAt : now,
      );
      batch.set(col.doc(merged.id), merged.toFirestoreMap());
    }
    await batch.commit();
  }
}
