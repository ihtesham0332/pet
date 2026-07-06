class ApiEndpoints {
  ApiEndpoints._();

  // Auth
  static const String authRegister = '/auth/register';
  static const String authLogin = '/auth/login';
  static const String authRefresh = '/auth/refresh';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authGoogle = '/auth/google';
  static const String authApple = '/auth/apple';
  static const String googleAuth = '/auth/google';
  // Users
  static const String usersMe = '/users/me';

  // Pets
  static const String pets = '/pets';
  static String petById(String id) => '/pets/$id';
  static String petMedicalHistory(String id) => '/pets/$id/medical-history';
  static String petVaccinations(String id) => '/pets/$id/vaccinations';

  // Symptoms
  static const String symptomAnalyze = '/symptoms/analyze';
  static const String symptomHistory = '/symptoms/history';
  static String symptomById(String id) => '/symptoms/$id';

  // Emergency
  static const String emergencyCheck = '/emergency/check';
  static const String emergencyNearbyVets = '/emergency/nearby-vets';

  // Recommendations
  static const String recommendProducts = '/recommendations/products';

  // Veterinary
  static const String veterinarians = '/veterinarians';
  static const String appointments = '/appointments';
  static String vetById(String id) => '/veterinarians/$id';

  // Reminders
  static const String reminders = '/reminders';
  static String reminderById(String id) => '/reminders/$id';
  static String remindersUpcoming({String? type}) =>
      '/reminders?upcoming=true${type != null ? '&type=$type' : ''}';
  static String remindersByType(String type) => '/reminders?type=$type';

  // Subscriptions
  static const String subscribe = '/subscriptions';
  static const String subscriptionStatus = '/subscriptions/status';
  static const String cancelSubscription = '/subscriptions/cancel';
}
