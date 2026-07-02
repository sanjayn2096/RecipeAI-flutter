import 'package:flutter/foundation.dart';

import '../core/preference_options.dart';

/// State for the six-step onboarding funnel.
class OnboardingController extends ChangeNotifier {
  static const int stepCount = 6;
  static const int maxCuisines = 3;

  int _stepIndex = 0;
  int get stepIndex => _stepIndex;

  final Set<String> _dietProfiles = {};
  final Set<String> _allergensAvoid = {};
  String _allergyNotes = '';
  final Set<String> _usualCuisines = {};

  Set<String> get dietProfiles => Set.unmodifiable(_dietProfiles);
  Set<String> get allergensAvoid => Set.unmodifiable(_allergensAvoid);
  String get allergyNotes => _allergyNotes;
  Set<String> get usualCuisines => Set.unmodifiable(_usualCuisines);

  bool get isFirstStep => _stepIndex == 0;
  bool get isPaywallStep => _stepIndex == stepCount - 1;

  bool get canContinue {
    switch (_stepIndex) {
      case 0:
        return true;
      case 1:
        return _dietProfiles.isNotEmpty;
      case 2:
        return true;
      case 3:
        return _usualCuisines.isNotEmpty;
      case 4:
        return true;
      case 5:
        return false;
      default:
        return false;
    }
  }

  void toggleDiet(String key) {
    if (key == PreferenceOptions.dietNoRestrictions) {
      _dietProfiles
        ..clear()
        ..add(PreferenceOptions.dietNoRestrictions);
    } else {
      _dietProfiles.remove(PreferenceOptions.dietNoRestrictions);
      if (_dietProfiles.contains(key)) {
        _dietProfiles.remove(key);
      } else {
        _dietProfiles.add(key);
      }
    }
    notifyListeners();
  }

  void toggleAllergen(String key) {
    if (_allergensAvoid.contains(key)) {
      _allergensAvoid.remove(key);
    } else {
      _allergensAvoid.add(key);
    }
    notifyListeners();
  }

  void clearAllergens() {
    _allergensAvoid.clear();
    notifyListeners();
  }

  void setAllergyNotes(String value) {
    _allergyNotes = value;
    notifyListeners();
  }

  void toggleCuisine(String key) {
    if (_usualCuisines.contains(key)) {
      _usualCuisines.remove(key);
    } else if (_usualCuisines.length < maxCuisines) {
      _usualCuisines.add(key);
    }
    notifyListeners();
  }

  bool cuisineAtLimit(String key) {
    return !_usualCuisines.contains(key) &&
        _usualCuisines.length >= maxCuisines;
  }

  void nextStep() {
    if (_stepIndex >= stepCount - 1 || !canContinue) return;
    _stepIndex++;
    notifyListeners();
  }

  void previousStep() {
    if (_stepIndex <= 0 || isPaywallStep) return;
    _stepIndex--;
    notifyListeners();
  }
}
