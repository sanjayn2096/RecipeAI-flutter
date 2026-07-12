import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// IAP funnel logs for debug and TestFlight (USB Console.app + Crashlytics).
void subscriptionLog(String message) {
  final line = '[Subscription] $message';
  // Intentional: debugPrint is stripped in release; print shows in device console.
  // ignore: avoid_print
  print(line);
  if (!kIsWeb) {
    FirebaseCrashlytics.instance.log(line);
  }
}
