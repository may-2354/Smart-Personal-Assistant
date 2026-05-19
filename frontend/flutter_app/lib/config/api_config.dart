class ApiConfig {
  // Base URL
  static const String baseUrl =
      'https://smart-personal-assistant.onrender.com';

  // ================= AUTH ENDPOINTS =================
  static const String login =
      '$baseUrl/api/auth/login';

  static const String register =
      '$baseUrl/api/auth/register';

  static const String currentUser =
      '$baseUrl/api/auth/me';

  static const String logout =
      '$baseUrl/api/auth/logout';

  // ================= TASK ENDPOINTS =================
  static const String tasks =
      '$baseUrl/api/tasks';

  static String taskById(int id) =>
      '$baseUrl/api/tasks/$id';

  static const String overdueTasks =
      '$baseUrl/api/tasks/overdue';

  static const String todayTasks =
      '$baseUrl/api/tasks/today';

  static const String taskStats =
      '$baseUrl/api/tasks/stats';

  // ================= CHAT ENDPOINT =================
  static const String chat =
      '$baseUrl/api/chat/';

  // ================= ANALYTICS ENDPOINT =================
  static const String analytics =
      '$baseUrl/api/analytics';

  // ================= ML ENDPOINTS =================
  static const String mlSuggestions =
      '$baseUrl/api/ml/suggestions';

  static const String mlPredictPriority =
      '$baseUrl/api/ml/predict-priority';

  static const String mlAnalyzeSentiment =
      '$baseUrl/api/ml/analyze-sentiment';

  // ================= GAMIFICATION ENDPOINTS =================
  static const String gamificationStats =
      '$baseUrl/api/analytics/gamification';

  static const String leaderboard =
      '$baseUrl/api/analytics/leaderboard';

  // ================= TIMEOUT SETTINGS =================
  static const Duration connectionTimeout =
      Duration(seconds: 30);

  static const Duration receiveTimeout =
      Duration(seconds: 30);
}