import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'monetization_platform.dart';
import 'telemetry/app_telemetry.dart';

/// Opens the premium paywall and logs CTA analytics.
/// No-op on iOS while paid monetization is disabled.
void openPremiumPaywall(
  BuildContext context, {
  required String source,
  required AppTelemetry appTelemetry,
}) {
  if (isIosPaidMonetizationDisabled) return;
  appTelemetry.logPremiumCtaTap(source: source);
  context.push('/premium', extra: source);
}
