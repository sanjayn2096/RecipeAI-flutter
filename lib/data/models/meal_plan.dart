import 'recipe.dart';

/// One planned meal slot with a full recipe.
class MealPlanSlotEntry {
  const MealPlanSlotEntry({
    required this.meal,
    required this.recipe,
  });

  final String meal;
  final Recipe recipe;

  factory MealPlanSlotEntry.fromJson(Map<String, dynamic> json) {
    final recipeJson = json['recipe'];
    return MealPlanSlotEntry(
      meal: json['meal']?.toString() ?? 'dinner',
      recipe: recipeJson is Map<String, dynamic>
          ? Recipe.fromJson(recipeJson)
          : Recipe.fromJson(const {}),
    );
  }
}

class MealPlanDay {
  const MealPlanDay({
    required this.date,
    required this.slots,
  });

  final String date;
  final List<MealPlanSlotEntry> slots;

  factory MealPlanDay.fromJson(Map<String, dynamic> json) {
    final raw = json['slots'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => MealPlanSlotEntry.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <MealPlanSlotEntry>[];
    return MealPlanDay(
      date: json['date']?.toString() ?? '',
      slots: list,
    );
  }
}

class MissingIngredientLine {
  const MissingIngredientLine({
    required this.name,
    this.quantity,
    this.unit,
    this.estimatedUsd = 0,
    this.usedByRecipes = const [],
    this.selected = true,
  });

  final String name;
  final String? quantity;
  final String? unit;
  final double estimatedUsd;
  final List<String> usedByRecipes;
  final bool selected;

  MissingIngredientLine copyWith({
    String? name,
    String? quantity,
    String? unit,
    double? estimatedUsd,
    List<String>? usedByRecipes,
    bool? selected,
  }) {
    return MissingIngredientLine(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      estimatedUsd: estimatedUsd ?? this.estimatedUsd,
      usedByRecipes: usedByRecipes ?? this.usedByRecipes,
      selected: selected ?? this.selected,
    );
  }

  factory MissingIngredientLine.fromJson(Map<String, dynamic> json) {
    final used = json['usedByRecipes'];
    return MissingIngredientLine(
      name: json['name']?.toString() ?? '',
      quantity: json['quantity']?.toString(),
      unit: json['unit']?.toString(),
      estimatedUsd: _asDouble(json['estimatedUsd']),
      usedByRecipes: used is List
          ? used.map((e) => e.toString()).toList()
          : const [],
    );
  }

  String toGroceryLine() {
    final parts = <String>[name.trim()];
    if (quantity != null && quantity!.trim().isNotEmpty) {
      parts.insert(0, quantity!.trim());
    }
    if (unit != null && unit!.trim().isNotEmpty) {
      if (parts.length > 1) {
        parts[1] = '${parts[1]} ${unit!.trim()}';
      } else {
        parts.add(unit!.trim());
      }
    }
    return parts.join(' ').trim();
  }
}

class MealPlanCostSummary {
  const MealPlanCostSummary({
    required this.estimatedTotalUsd,
    this.budgetUsd,
    this.withinBudget = true,
  });

  final double estimatedTotalUsd;
  final double? budgetUsd;
  final bool withinBudget;

  factory MealPlanCostSummary.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MealPlanCostSummary(estimatedTotalUsd: 0);
    }
    return MealPlanCostSummary(
      estimatedTotalUsd: _asDouble(json['estimatedTotalUsd']),
      budgetUsd: json['budgetUsd'] != null ? _asDouble(json['budgetUsd']) : null,
      withinBudget: json['withinBudget'] as bool? ?? true,
    );
  }
}

class MealPlanInstacartInfo {
  const MealPlanInstacartInfo({
    required this.status,
    this.listUrl,
  });

  final String status;
  final String? listUrl;

  factory MealPlanInstacartInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const MealPlanInstacartInfo(status: 'coming_soon');
    }
    return MealPlanInstacartInfo(
      status: json['status']?.toString() ?? 'coming_soon',
      listUrl: json['listUrl']?.toString(),
    );
  }
}

class MealPlanResult {
  const MealPlanResult({
    this.assistantMessage,
    required this.planId,
    required this.days,
    required this.missingIngredients,
    required this.costSummary,
    required this.instacart,
  });

  final String? assistantMessage;
  final String planId;
  final List<MealPlanDay> days;
  final List<MissingIngredientLine> missingIngredients;
  final MealPlanCostSummary costSummary;
  final MealPlanInstacartInfo instacart;

  factory MealPlanResult.fromJson(Map<String, dynamic> json) {
    final daysRaw = json['days'];
    final missingRaw = json['missingIngredients'];
    return MealPlanResult(
      assistantMessage: json['assistantMessage']?.toString(),
      planId: json['planId']?.toString() ?? '',
      days: daysRaw is List
          ? daysRaw
              .whereType<Map>()
              .map((e) => MealPlanDay.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      missingIngredients: missingRaw is List
          ? missingRaw
              .whereType<Map>()
              .map((e) =>
                  MissingIngredientLine.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const [],
      costSummary: MealPlanCostSummary.fromJson(
        json['costSummary'] is Map
            ? Map<String, dynamic>.from(json['costSummary'] as Map)
            : null,
      ),
      instacart: MealPlanInstacartInfo.fromJson(
        json['instacart'] is Map
            ? Map<String, dynamic>.from(json['instacart'] as Map)
            : null,
      ),
    );
  }
}

class GenerateMealPlanRequest {
  GenerateMealPlanRequest({
    this.dietGoals = const [],
    this.cuisines = const [],
    this.mealSlots = const ['dinner'],
    this.weekdays = const [1, 2, 3],
    this.ingredients = const [],
    this.weeklyBudgetUsd,
    this.postalCode,
    this.anonymousId,
    this.excludeRecipeNames = const [],
  });

  final List<String> dietGoals;
  final List<String> cuisines;
  final List<String> mealSlots;
  final List<int> weekdays;
  final List<String> ingredients;
  final double? weeklyBudgetUsd;
  final String? postalCode;
  final String? anonymousId;
  final List<String> excludeRecipeNames;

  Map<String, dynamic> toJson() => {
        'dietGoals': dietGoals,
        'cuisines': cuisines,
        'mealSlots': mealSlots,
        'weekdays': weekdays,
        'ingredients': ingredients,
        if (weeklyBudgetUsd != null) 'weeklyBudgetUsd': weeklyBudgetUsd,
        if (postalCode != null && postalCode!.trim().isNotEmpty)
          'postalCode': postalCode!.trim(),
        if (anonymousId != null) 'anonymousId': anonymousId,
        if (excludeRecipeNames.isNotEmpty)
          'excludeRecipeNames': excludeRecipeNames,
      };
}

class RegenerateMealPlanSlotRequest {
  RegenerateMealPlanSlotRequest({
    required this.planId,
    required this.date,
    required this.meal,
    this.ingredients = const [],
    this.excludeRecipeNames = const [],
  });

  final String planId;
  final String date;
  final String meal;
  final List<String> ingredients;
  final List<String> excludeRecipeNames;

  Map<String, dynamic> toJson() => {
        'planId': planId,
        'date': date,
        'meal': meal,
        'ingredients': ingredients,
        if (excludeRecipeNames.isNotEmpty)
          'excludeRecipeNames': excludeRecipeNames,
      };
}

double _asDouble(dynamic v) {
  if (v is num) return v.toDouble();
  return double.tryParse('$v') ?? 0;
}
