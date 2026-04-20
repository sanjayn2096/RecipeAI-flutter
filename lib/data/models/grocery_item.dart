import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

/// One row on the grocery list (device-local for guests; Firestore for signed-in users).
class GroceryItem {
  const GroceryItem({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.note,
    this.sourceRecipeId,
    this.sourceRecipeName,
    this.isChecked = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? quantity;
  final String? unit;
  final String? note;
  final String? sourceRecipeId;
  final String? sourceRecipeName;
  final bool isChecked;
  final DateTime createdAt;
  final DateTime updatedAt;

  static const _uuid = Uuid();

  static String newId() => _uuid.v4();

  GroceryItem copyWith({
    String? id,
    String? name,
    String? quantity,
    String? unit,
    String? note,
    String? sourceRecipeId,
    String? sourceRecipeName,
    bool? isChecked,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool clearQuantity = false,
    bool clearUnit = false,
    bool clearNote = false,
    bool clearSourceRecipe = false,
  }) {
    return GroceryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: clearQuantity ? null : (quantity ?? this.quantity),
      unit: clearUnit ? null : (unit ?? this.unit),
      note: clearNote ? null : (note ?? this.note),
      sourceRecipeId:
          clearSourceRecipe ? null : (sourceRecipeId ?? this.sourceRecipeId),
      sourceRecipeName:
          clearSourceRecipe ? null : (sourceRecipeName ?? this.sourceRecipeName),
      isChecked: isChecked ?? this.isChecked,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory GroceryItem.fromJson(Map<String, dynamic> json) {
    DateTime parseTime(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return GroceryItem(
      id: json['id'] as String? ?? newId(),
      name: json['name'] as String? ?? '',
      quantity: json['quantity'] as String?,
      unit: json['unit'] as String?,
      note: json['note'] as String?,
      sourceRecipeId: json['sourceRecipeId'] as String?,
      sourceRecipeName: json['sourceRecipeName'] as String?,
      isChecked: json['isChecked'] as bool? ?? false,
      createdAt: parseTime(json['createdAt']),
      updatedAt: parseTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'note': note,
        'sourceRecipeId': sourceRecipeId,
        'sourceRecipeName': sourceRecipeName,
        'isChecked': isChecked,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  /// Firestore document fields (id is the document id, not stored inside).
  Map<String, dynamic> toFirestoreMap() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'note': note,
      'sourceRecipeId': sourceRecipeId,
      'sourceRecipeName': sourceRecipeName,
      'isChecked': isChecked,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory GroceryItem.fromFirestoreDoc(
    String docId,
    Map<String, dynamic> data,
  ) {
    DateTime parseTime(dynamic v) {
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v) ?? DateTime.now();
      return DateTime.now();
    }

    return GroceryItem(
      id: docId,
      name: data['name'] as String? ?? '',
      quantity: data['quantity'] as String?,
      unit: data['unit'] as String?,
      note: data['note'] as String?,
      sourceRecipeId: data['sourceRecipeId'] as String?,
      sourceRecipeName: data['sourceRecipeName'] as String?,
      isChecked: data['isChecked'] as bool? ?? false,
      createdAt: parseTime(data['createdAt']),
      updatedAt: parseTime(data['updatedAt']),
    );
  }

  static String normalizeName(String name) => name.toLowerCase().trim();
}
