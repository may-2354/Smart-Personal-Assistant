class AppConstants {
  // App Info
  static const String appName = 'Smart Assistant';
  static const String appVersion = '1.0.0';
  
  // Storage Keys
  static const String tokenKey = 'auth_token';
  static const String userKey = 'user_data';
  static const String themeKey = 'theme_mode';
  
  // Pagination
  static const int defaultPageSize = 20;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 400);
  static const Duration longAnimation = Duration(milliseconds: 600);
  
  // Task Priorities
  static const List<String> priorities = ['low', 'medium', 'high', 'critical'];
  static const List<String> statuses = ['pending', 'in_progress', 'completed'];
  
  // Categories
  static const List<String> categories = [
    'Work',
    'Personal',
    'Health',
    'Education',
    'Shopping',
    'Other',
  ];
}