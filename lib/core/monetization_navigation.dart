import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'telemetry/app_telemetry.dart';

/// Opens the premium paywall and logs CTA analytics.
void openPremiumPaywall(
  BuildContext context, {
  required String source,
  required AppTelemetry appTelemetry,
}) {
  appTelemetry.logPremiumCtaTap(source: source);
  context.push('/premium', extra: source);
}
