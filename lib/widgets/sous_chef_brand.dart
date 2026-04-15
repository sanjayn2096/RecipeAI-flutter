import 'package:flutter/material.dart';

import '../core/app_strings.dart';

/// Asset path for the Sous Chef logo (square PNG: mark + wordmark + tagline).
const String kSousChefLogoAsset = 'assets/sous_chef_logo.png';

/// Fraction of [kSousChefLogoAsset] height used for the icon-only mark (top portion).
const double _kLogoMarkHeightFactor = 0.56;

/// Chef hat + utensils only — top slice of the square logo, for inline headers.
class SousChefLogoMark extends StatelessWidget {
  const SousChefLogoMark({super.key, this.size = 45});

  final double size;

  @override
  Widget build(BuildContext context) {
    // Width-only box: [Align.heightFactor] sizes height to the visible slice only
    // (avoids a tall empty band under the clipped graphic).
    return SizedBox(
      width: size,
      child: ClipRect(
        child: Align(
          alignment: Alignment.topCenter,
          heightFactor: _kLogoMarkHeightFactor,
          child: Image.asset(
            kSousChefLogoAsset,
            width: size * 1.15,
            fit: BoxFit.fitWidth,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}

/// Chef mark centered above the app name (e.g. login / sign-up).
class SousChefLoginHeader extends StatelessWidget {
  const SousChefLoginHeader({super.key, this.markSize = 140});

  final double markSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Center(
          child: SousChefLogoMark(size: markSize),
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.appName,
          style: theme.textTheme.headlineMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Mark + "Sous Chef" in a row for [AppBar.title] (avoids duplicating text in the full logo PNG).
class SousChefInlineTitle extends StatelessWidget {
  const SousChefInlineTitle({super.key, this.markSize = 43});

  final double markSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
    );
    // One inline line so the mark and title share the same vertical metrics (avoids Row cross-axis drift).
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SousChefLogoMark(size: markSize),
          ),
          const WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SizedBox(width: 2),
          ),
          const TextSpan(text: AppStrings.appName),
        ],
      ),
    );
  }
}

/// Centered splash: full stacked logo (includes tagline in artwork) + loading.
class SousChefSplashContent extends StatelessWidget {
  const SousChefSplashContent({super.key});

  @override
  Widget build(BuildContext context) {
    final maxW = MediaQuery.sizeOf(context).width - 48;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          kSousChefLogoAsset,
          width: maxW.clamp(250, 400),
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
        ),
        const SizedBox(height: 48),
        const SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(strokeWidth: 2.5),
        ),
      ],
    );
  }
}
