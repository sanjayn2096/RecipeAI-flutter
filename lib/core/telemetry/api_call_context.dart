/// Identity attached to API telemetry (Firebase Auth uid or guest anonymous id).
enum ApiActorType {
  firebaseUser,
  anonymous,
}

class ApiCallContext {
  const ApiCallContext({
    required this.actorId,
    required this.actorType,
  });

  final String actorId;
  final ApiActorType actorType;
}

class ApiCallMetrics {
  ApiCallMetrics({
    required this.path,
    required this.method,
    required this.statusCode,
    required this.durationMs,
    required this.actorId,
    required this.actorType,
    this.errorMessage,
  });

  final String path;
  final String method;
  final int statusCode;
  final int durationMs;
  final String actorId;
  final ApiActorType actorType;
  final String? errorMessage;
}
