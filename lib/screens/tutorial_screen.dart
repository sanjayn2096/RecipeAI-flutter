import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:recipe_ai/l10n/app_localizations.dart';

import '../core/l10n_context.dart';

/// On-demand walkthrough: tabs overview, creating recipes, pantry, import, favorites.
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key});

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  late final PageController _pageController;
  int _pageIndex = 0;

  static List<({String title, String body})> _pages(AppLocalizations l10n) =>
      [
        (
          title: l10n.tutorialOverviewTitle,
          body: l10n.tutorialOverviewBody,
        ),
        (
          title: l10n.tutorialCreateRecipesTitle,
          body: l10n.tutorialCreateRecipesBody,
        ),
        (
          title: l10n.tutorialPantryTitle,
          body: l10n.tutorialPantryBody,
        ),
        (
          title: l10n.tutorialImportTitle,
          body: l10n.tutorialImportBody,
        ),
        (
          title: l10n.tutorialFavoritesTitle,
          body: l10n.tutorialFavoritesBody,
        ),
      ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext(int pageCount) {
    if (_pageIndex < pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    } else {
      if (mounted) context.pop();
    }
  }

  void _goBack() {
    if (_pageIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final pages = _pages(l10n);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.tutorialScreenTitle),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _pageIndex = i),
                itemBuilder: (_, i) {
                  final p = pages[i];
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          p.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          p.body,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                    height: 1.45,
                                  ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.pop(true),
                    icon: const Icon(Icons.touch_app_outlined),
                    label: Text(l10n.showMeInApp),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(pages.length, (i) {
                      final selected = i == _pageIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: selected ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(4),
                            color: selected
                                ? colorScheme.primary
                                : colorScheme.outlineVariant,
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (_pageIndex > 0)
                        TextButton(
                          onPressed: _goBack,
                          child: Text(l10n.back),
                        )
                      else
                        const SizedBox(width: 64),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => _goNext(pages.length),
                          child: Text(
                            _pageIndex < pages.length - 1
                                ? l10n.next
                                : l10n.ok,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
