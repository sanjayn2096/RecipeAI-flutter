/// Thrown when Firebase auth succeeds but the email is not yet verified.
class EmailNotVerifiedException implements Exception {
  EmailNotVerifiedException([this.message = 'Verify your email to continue']);

  final String message;

  @override
  String toString() => message;
}
