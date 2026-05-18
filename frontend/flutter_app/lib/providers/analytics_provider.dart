import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../services/api_service.dart';

class AnalyticsProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  AnalyticsData? _analytics;
  bool _isLoading = false;
  String? _error;
  int _periodDays = 30;

  AnalyticsData? get analytics => _analytics;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get periodDays => _periodDays;

  void setToken(String token) {
    _apiService.setToken(token);
  }

  void setPeriodDays(int days) {
    _periodDays = days;
    notifyListeners();
    loadAnalytics();
  }

  Future<void> loadAnalytics() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Call BOTH endpoints
      final productivityData = await _apiService.getProductivityAnalytics(days: _periodDays);
      final gamificationData = await _apiService.getGamificationStats();

      print('Productivity data: $productivityData');
      print('Gamification data: $gamificationData');
      
      // Combine data from both endpoints
      _analytics = AnalyticsData.fromJson(productivityData, gamificationData);
      print('Parsed streaks - Current: ${_analytics!.currentStreak}, Best: ${_analytics!.bestStreak}');
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('Analytics error: $e');
    }
  }

  Future<void> refresh() async {
    await loadAnalytics();
  }

  List<DailyProductivity> get currentProductivityData {
    if (_analytics == null) return [];
    return _analytics!.productivityData;
  }

  bool get hasData => _analytics != null && _analytics!.totalTasks > 0;
  
  bool get showBurnoutWarning => 
      _analytics?.burnoutWarning?.isWarning ?? false;
}