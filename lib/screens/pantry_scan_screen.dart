import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import 'pantry/pantry_captured_photo.dart';
import 'pantry/pantry_pick_photo.dart';
import 'pantry/pantry_scan_review.dart';
import '../core/l10n_context.dart';
import '../core/monetization_navigation.dart';
import '../core/recipe_generation_entry_point.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/api/api_service.dart';
import '../services/pantry/pantry_image_analyzer.dart';
import '../services/session_manager.dart';
import '../view_models/subscription_view_model.dart';
import '../widgets/guest_signup_prompt.dart';

/// Photo of pantry/fridge → cloud scan → review → user's Home pantry staples.
class PantryScanScreen extends StatefulWidget {
  const PantryScanScreen({
    super.key,
    required this.apiService,
    required this.sessionManager,
    required this.subscriptionViewModel,
    required this.appTelemetry,
  });

  final ApiService apiService;
  final SessionManager sessionManager;
  final SubscriptionViewModel subscriptionViewModel;
  final AppTelemetry appTelemetry;

  @override
  State<PantryScanScreen> createState() => _PantryScanScreenState();
}

class _PantryScanScreenState extends State<PantryScanScreen> {
  late final PantryImageAnalyzer _analyzer =
      createPantryImageAnalyzer(widget.apiService);

  bool _busy = false;
  String? _error;
  PantryCapturedPhoto? _photo;
  List<PantrySuggestionSelection> _selections = [];

  bool get _showReview => _photo != null && _selections.isNotEmpty && !_busy;

  @override
  void initState() {
    super.initState();
    widget.subscriptionViewModel.addListener(_onSubscriptionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _guardPremiumAccess());
  }

  @override
  void dispose() {
    widget.subscriptionViewModel.removeListener(_onSubscriptionChanged);
    super.dispose();
  }

  void _onSubscriptionChanged() {
    if (!widget.subscriptionViewModel.isPremium && mounted) {
      _guardPremiumAccess();
    }
  }

  void _guardPremiumAccess() {
    if (!mounted || widget.subscriptionViewModel.isPremium) return;
    openPremiumPaywall(
      context,
      source: 'pantry_scan',
      appTelemetry: widget.appTelemetry,
    );
    context.pop();
  }

  Future<void> _pick(ImageSource source) async {
    if (!widget.subscriptionViewModel.isPremium) {
      _guardPremiumAccess();
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _error = context.l10n.groceryPantryScanSignInRequired);
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _photo = null;
      _selections = [];
    });

    try {
      final captured = await pickPantryPhoto(source);
      if (captured == null || captured.bytes.isEmpty) {
        setState(() => _busy = false);
        return;
      }

      final mime = captured.mimeType;
      final token = await user.getIdToken();

      final suggestions = await _analyzer.analyze(
        bytes: captured.bytes,
        mimeType: mime,
        idToken: token,
      );

      final selections = suggestions
          .map((s) => PantrySuggestionSelection(suggestion: s))
          .toList();

      setState(() {
        _photo = captured;
        _selections = selections;
        _busy = false;
        _error = selections.isEmpty
            ? context.l10n.groceryPantryScanNoItemsDetected
            : null;
      });

      if (selections.isNotEmpty) {
        await widget.appTelemetry.logFeatureInteraction(
          featureId: FeatureIds.groceryPantryScanAnalyze,
        );
      }
    } catch (e) {
      setState(() {
        _busy = false;
        _error = e.toString();
      });
    }
  }

  void _scanAgain() {
    setState(() {
      _photo = null;
      _selections = [];
      _error = null;
    });
  }

  void _onSelectedNameChanged(int groupIndex, String name) {
    setState(() => _selections[groupIndex].selectedName = name);
  }

  List<String> _selectedIngredientNames() {
    return _selections
        .map((s) => s.selectedName.trim())
        .where((name) => name.isNotEmpty)
        .toList();
  }

  int _mergeSelectedIntoPantry() {
    final names = _selectedIngredientNames();
    if (names.isEmpty) return 0;

    final list = List<String>.from(widget.sessionManager.getIngredients());
    var added = 0;
    for (final name in names) {
      if (!list.contains(name)) {
        list.add(name);
        added++;
      }
    }
    if (added > 0) {
      widget.sessionManager.saveIngredientsSync(list);
    }
    return added;
  }

  Future<void> _addAllToPantry() async {
    final names = _selectedIngredientNames();
    if (names.isEmpty) return;

    final added = _mergeSelectedIntoPantry();

    widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.groceryPantryScanAddAllToPantry,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added > 0
              ? context.l10n.groceryPantryScanAdded(added)
              : context.l10n.groceryPantryScanAlreadyInPantry,
        ),
      ),
    );
    context.pop();
  }

  Future<void> _generateRecipesFromScan() async {
    final names = _selectedIngredientNames();
    if (names.isEmpty) return;

    _mergeSelectedIntoPantry();

    if (widget.sessionManager.isGuestMode() &&
        !widget.subscriptionViewModel.isPremium) {
      final exceeded =
          await widget.sessionManager.isGuestRecipeQuotaExceededForToday();
      if (!mounted) return;
      if (exceeded) {
        final action = await showGuestRecipeLimitReachedDialog(
          context,
          appTelemetry: widget.appTelemetry,
        );
        if (!mounted) return;
        if (action == GuestLimitAction.signUp) {
          goToSignup(context);
        } else if (action == GuestLimitAction.premium) {
          openPremiumPaywall(
            context,
            source: 'guest_quota',
            appTelemetry: widget.appTelemetry,
          );
        }
        return;
      }
    }

    widget.appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.groceryPantryScanGenerateRecipes,
    );

    if (!mounted) return;
    context.pushReplacement('/recipe-flow', extra: {
      'generationEntryPoint': RecipeGenerationEntryPoint.home.name,
    });
  }

  void _dismissItem(int index) {
    setState(() {
      _selections = List.of(_selections)..removeAt(index);
      if (_selections.isEmpty) {
        _photo = null;
        _error = context.l10n.groceryPantryScanNoItemsDetected;
      }
    });
  }

  Future<void> _editItem(int index) async {
    final sel = _selections[index];
    final controller = TextEditingController(text: sel.selectedName);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.groceryPantryScanEditItem),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop(controller.text.trim());
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (!mounted || result == null) return;
    if (result.isEmpty) {
      _dismissItem(index);
      return;
    }
    setState(() => _selections[index].selectedName = result);
  }

  @override
  Widget build(BuildContext context) {
    final workingLabel = context.l10n.groceryPantryScanWorking;
    final subtitle = context.l10n.groceryPantryScanSubtitle;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.groceryPantryScanTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!_showReview) ...[
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pick(ImageSource.camera),
                      icon: const Icon(Icons.photo_camera_outlined),
                      label: Text(context.l10n.groceryPantryScanTakePhoto),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _pick(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(context.l10n.groceryPantryScanChoosePhoto),
                    ),
                  ),
                ],
              ),
            ],
            if (_busy) ...[
              const SizedBox(height: 24),
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 12),
                    Text(workingLabel),
                  ],
                ),
              ),
            ],
            if (_error != null && !_busy) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
            if (_showReview) ...[
              Expanded(
                child: PantryScanReview(
                  photo: _photo!,
                  selections: _selections,
                  onSelectedNameChanged: _onSelectedNameChanged,
                  onEditItem: _editItem,
                  onDismissItem: _dismissItem,
                  onGenerateRecipes: _generateRecipesFromScan,
                  onAddAllToPantry: _addAllToPantry,
                  onScanAgain: _scanAgain,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
