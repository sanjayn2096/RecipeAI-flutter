/// User fields persisted after GET get_user_profile (and shown on Profile screen).
class SessionProfile {
  const SessionProfile({
    this.userId,
    this.email = '',
    this.firstName = '',
    this.lastName = '',
  });

  final String? userId;
  final String email;
  final String firstName;
  final String lastName;

  String get displayName {
    final parts = [firstName.trim(), lastName.trim()].where((s) => s.isNotEmpty).join(' ');
    return parts.isEmpty ? '—' : parts;
  }

  /// True if any of the user-visible profile fields are present.
  bool get hasDisplayFields =>
      email.isNotEmpty || firstName.isNotEmpty || lastName.isNotEmpty;
}
