class ApiConstants {
  static const String baseUrl = 'https://api.learnoo.app';
  static const String register = '/v1/auth/register';
  static const String login = '/v1/auth/login';
  static const String emailVerificationNotification = '/v1/auth/email/verification-notification';
  static const String phoneVerificationNotification = '/v1/auth/phone/verification-notification';
  static const String verifyEmail = '/v1/auth/email/verify';
  static const String verifyPhone = '/v1/auth/phone/verify';
  static const String universities = '/v1/university';
  static const String centers = '/v1/center';
  static const String faculties = '/v1/faculty';
  static const String departments = '/v1/department';
  static const String courses = '/v1/course';
  static const String updateProfile = '/v1/auth/update';
  static const String me = '/v1/auth/me';
  static const String lectures = '/v1/lecture';
  static const String chapters = '/v1/chapter';
  static const String codeActivate = '/v1/code/activate';
  static const String discussion = '/v1/discussion';

  // Quiz/Exam endpoints
  static const String quiz = '/v1/quiz';
  static const String quizQuestion = '/v1/quiz-question';
  static const String quizAnswer = '/v1/quiz-answer';
  static const String quizAttempt = '/v1/quiz-attempt';

  // Notes endpoints
  static const String notes = '/v1/note';

  // Library endpoints
  static const String libraries = '/v1/library';
}
