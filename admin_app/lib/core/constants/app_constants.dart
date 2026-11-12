/// Global application constants.
class AppConstants {
  AppConstants._();

  /// Default production hosting domain for the student web feedback form.
  static const String studentFormBaseUrl = 'https://alumni-feedback-5b0e1.web.app';

  /// Generates the verified student feedback form URL for a specific lecture session.
  static String getStudentFeedbackUrl(String lectureId) {
    return '$studentFormBaseUrl/?lecture=$lectureId';
  }
}
