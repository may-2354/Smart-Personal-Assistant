class ApiConfig {
  // Base URLs
  static const String baseUrl = 'http://localhost:8000/api';
  
  // Auth endpoints
  static const String login = '$baseUrl/auth/login';
  static const String register = '$baseUrl/auth/register'; // ADD THIS LINE
  static const String currentUser = '$baseUrl/auth/me';
  
  // Task endpoints
  static const String tasks = '$baseUrl/tasks';
  static String taskById(int id) => '$baseUrl/tasks/$id';
  static const String overdueTasks = '$baseUrl/tasks/overdue';
  static const String todayTasks = '$baseUrl/tasks/today';
  static const String taskStats = '$baseUrl/tasks/stats';
  
  // Chat endpoint
  static const String chat = '$baseUrl/chat/';
  
  // Analytics endpoint
  static const String analytics = '$baseUrl/analytics';
  
  // ML endpoints
  static const String mlSuggestions = '$baseUrl/ml/suggestions';
  static const String mlPredictPriority = '$baseUrl/ml/predict-priority';
  static const String mlAnalyzeSentiment = '$baseUrl/ml/analyze-sentiment';
  
  // Gamification endpoints
  static const String gamificationStats = '$baseUrl/analytics/gamification';
  static const String leaderboard = '$baseUrl/analytics/leaderboard';
  
  // Timeout durations
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}