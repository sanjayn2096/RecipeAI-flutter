/// Mirrors Firestore `users/{uid}.subscription` from get_user_profile.
class SubscriptionStatus {
  const SubscriptionStatus({
    this.tier,
    this.status,
    this.expiresAtMs,
    this.platform,
    this.productId,
  });

  final String? tier;
  final String? status;
  final int? expiresAtMs;
  final String? platform;
  final String? productId;

  bool get isPremium {
    if (status != 'active' && status != 'grace') return false;
    final exp = expiresAtMs;
    if (exp == null) return false;
    return exp > DateTime.now().millisecondsSinceEpoch;
  }

  factory SubscriptionStatus.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const SubscriptionStatus();
    int? expiresMs;
    final raw = json['expiresAt'];
    if (raw is int) {
      expiresMs = raw;
    } else if (raw is num) {
      expiresMs = raw.toInt();
    } else if (raw is String) {
      expiresMs = DateTime.tryParse(raw)?.millisecondsSinceEpoch;
    } else if (raw is Map) {
      final sec = raw['_seconds'] ?? raw['seconds'];
      if (sec is num) {
        expiresMs = (sec * 1000).round();
      }
    }
    return SubscriptionStatus(
      tier: json['tier'] as String?,
      status: json['status'] as String?,
      expiresAtMs: expiresMs,
      platform: json['platform'] as String?,
      productId: json['productId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (tier != null) 'tier': tier,
        if (status != null) 'status': status,
        if (expiresAtMs != null) 'expiresAt': expiresAtMs,
        if (platform != null) 'platform': platform,
        if (productId != null) 'productId': productId,
      };
}
