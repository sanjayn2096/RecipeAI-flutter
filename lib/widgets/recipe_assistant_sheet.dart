import 'package:flutter/material.dart';

import '../core/l10n_context.dart';
import '../core/monetization_navigation.dart';
import '../core/telemetry/app_telemetry.dart';
import '../core/telemetry/feature_ids.dart';
import '../data/api/api_service.dart';
import '../data/models/recipe.dart';
import '../view_models/recipe_assistant_view_model.dart';
import '../view_models/subscription_view_model.dart';

Future<void> openRecipeAssistant({
  required BuildContext context,
  required Recipe recipe,
  required ApiService apiService,
  required AppTelemetry appTelemetry,
  required SubscriptionViewModel subscriptionViewModel,
}) async {
  if (!subscriptionViewModel.isPremium) {
    await appTelemetry.logFeatureInteraction(
      featureId: FeatureIds.recipeAssistantPremiumCta,
      action: 'view_gate',
    );
    if (!context.mounted) return;
    final openPaywall = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.recipeAssistantPremiumTitle),
        content: Text(ctx.l10n.recipeAssistantPremiumBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(ctx.l10n.recipeAssistantNotNow),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(ctx.l10n.recipeAssistantPremiumCta),
          ),
        ],
      ),
    );
    if (openPaywall == true && context.mounted) {
      openPremiumPaywall(
        context,
        source: 'recipe_assistant',
        appTelemetry: appTelemetry,
      );
      await appTelemetry.logFeatureInteraction(
        featureId: FeatureIds.recipeAssistantPremiumCta,
        action: 'open_paywall',
      );
    }
    return;
  }

  await appTelemetry.logFeatureInteraction(
    featureId: FeatureIds.recipeAssistantOpen,
  );
  if (!context.mounted) return;
  await showRecipeAssistantSheet(
    context: context,
    recipe: recipe,
    apiService: apiService,
    appTelemetry: appTelemetry,
  );
}

Future<void> showRecipeAssistantSheet({
  required BuildContext context,
  required Recipe recipe,
  required ApiService apiService,
  required AppTelemetry appTelemetry,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => RecipeAssistantSheet(
      recipe: recipe,
      apiService: apiService,
      appTelemetry: appTelemetry,
    ),
  );
}

class RecipeAssistantSheet extends StatefulWidget {
  const RecipeAssistantSheet({
    super.key,
    required this.recipe,
    required this.apiService,
    required this.appTelemetry,
  });

  final Recipe recipe;
  final ApiService apiService;
  final AppTelemetry appTelemetry;

  @override
  State<RecipeAssistantSheet> createState() => _RecipeAssistantSheetState();
}

class _RecipeAssistantSheetState extends State<RecipeAssistantSheet> {
  late final RecipeAssistantViewModel _vm;
  final _questionController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _vm = RecipeAssistantViewModel(
      apiService: widget.apiService,
      appTelemetry: widget.appTelemetry,
    )..addListener(_onVmChanged);
  }

  @override
  void dispose() {
    _vm
      ..removeListener(_onVmChanged)
      ..dispose();
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onVmChanged() {
    if (!mounted) return;
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  Future<void> _submit({bool speakAnswer = false}) async {
    final text = _questionController.text.trim();
    if (text.isEmpty) return;
    _questionController.clear();
    await _vm.stopListening();
    await _vm.ask(widget.recipe, text, speakAnswer: speakAnswer);
  }

  Future<void> _startVoice() {
    return _vm.startListening(
      onResult: (text) {
        _questionController.text = text;
        _questionController.selection = TextSelection.collapsed(
          offset: _questionController.text.length,
        );
      },
      onFinalResult: () => _submit(speakAnswer: true),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final height = MediaQuery.sizeOf(context).height * 0.78;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SizedBox(
        height: height,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.recipeAssistantTitle,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          widget.recipe.recipeName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(child: _buildConversation(context)),
            if (_vm.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Text(
                  _voiceErrorCopy(_vm.errorMessage!),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
            if (_vm.suggestedFollowUps.isNotEmpty)
              _SuggestedFollowUps(
                items: _vm.suggestedFollowUps,
                onTap: (text) {
                  _questionController.text = text;
                  _submit();
                },
              ),
            _buildInput(context),
          ],
        ),
      ),
    );
  }

  Widget _buildConversation(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    if (_vm.messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.soup_kitchen_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.recipeAssistantEmptyTitle,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.recipeAssistantEmptyBody,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      itemCount: _vm.messages.length + (_vm.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= _vm.messages.length) {
          return const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        final message = _vm.messages[index];
        return _MessageBubble(
          message: message,
          isSpeaking: _vm.isSpeaking,
          onSpeak: message.role == RecipeAssistantRole.assistant
              ? () => _vm.isSpeaking
                  ? _vm.stopSpeaking()
                  : _vm.speak(message.content)
              : null,
        );
      },
    );
  }

  Widget _buildInput(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final listening = _vm.isListening;
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton.outlined(
              tooltip: listening
                  ? l10n.recipeAssistantStopListening
                  : l10n.recipeAssistantMicTooltip,
              onPressed: _vm.isLoading
                  ? null
                  : listening
                      ? _vm.stopListening
                      : _startVoice,
              icon: Icon(listening ? Icons.stop : Icons.mic_none),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _questionController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                enabled: !_vm.isLoading,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: listening
                      ? l10n.recipeAssistantListening
                      : l10n.recipeAssistantInputHint,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              tooltip: l10n.recipeAssistantSend,
              onPressed: _vm.isLoading ? null : _submit,
              color: theme.colorScheme.onPrimary,
              icon: const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }

  String _voiceErrorCopy(String raw) {
    final lower = raw.toLowerCase();
    if (lower.contains('microphone') || lower.contains('voice input')) {
      return context.l10n.recipeAssistantVoiceUnavailable;
    }
    return raw;
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isSpeaking,
    this.onSpeak,
  });

  final RecipeAssistantMessage message;
  final bool isSpeaking;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isUser = message.role == RecipeAssistantRole.user;
    final bg = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;
    final fg = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                message.content,
                style: theme.textTheme.bodyMedium?.copyWith(color: fg),
              ),
            ),
            if (onSpeak != null) ...[
              const SizedBox(width: 4),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: isSpeaking
                    ? context.l10n.recipeAssistantStopSpeakingTooltip
                    : context.l10n.recipeAssistantSpeakTooltip,
                onPressed: onSpeak,
                icon: Icon(
                  isSpeaking ? Icons.stop_circle_outlined : Icons.volume_up,
                  size: 18,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SuggestedFollowUps extends StatelessWidget {
  const _SuggestedFollowUps({
    required this.items,
    required this.onTap,
  });

  final List<String> items;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: OutlinedButton(
                  onPressed: () => onTap(item),
                  child: Text(item),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
