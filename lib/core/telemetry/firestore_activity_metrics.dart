/// One client-side Firestore operation for usage attribution.
class FirestoreActivityMetrics {
  FirestoreActivityMetrics({
    required this.operation,
    required this.collection,
    this.docCount = 0,
  });

  /// `listen_snapshot`, `write`, `batch_write`, or `delete`.
  final String operation;

  /// Redacted path, e.g. `users/*/groceryItems`.
  final String collection;

  /// Documents in a snapshot, or writes in a batch.
  final int docCount;
}

typedef FirestoreActivityCallback = void Function(FirestoreActivityMetrics metrics);
