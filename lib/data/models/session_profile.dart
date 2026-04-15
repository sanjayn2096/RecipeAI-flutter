import '../../core/person_name_format.dart';

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

  /// Title-cased for UI (e.g. "JOHN" → "John").
  String get firstNameForDisplay => formatPersonNamePart(firstName);

  /// Title-cased for UI.
  String get lastNameForDisplay => formatPersonNamePart(lastName);

  String get displayName {
    final parts = [
      firstNameForDisplay.trim(),
      lastNameForDisplay.trim(),
    ].where((s) => s.isNotEmpty).join(' ');
    return parts.isEmpty ? '—' : parts;
  }

  /// True if any of the user-visible profile fields are present.
  bool get hasDisplayFields =>
      email.isNotEmpty || firstName.isNotEmpty || lastName.isNotEmpty;
}
