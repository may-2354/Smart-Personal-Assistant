import 'package:flutter/material.dart';
import '../models/gamification_models.dart';
import '../services/api_service.dart';

class GamificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Achievement> _achievements = [];
  List<LeaderboardEntry> _leaderboard = [];
  UserLevel? _userLevel;
  int _totalPoints = 0;
  int _currentStreak = 0;
  int _bestStreak = 0;
  Map<String, int> _achievementsByRarity = {};
  bool _isLoading = false;
  String? _error;

  List<Achievement> get achievements => _achievements;
  List<LeaderboardEntry> get leaderboard => _leaderboard;
  UserLevel? get userLevel => _userLevel;
  int get totalPoints => _totalPoints;
  int get currentStreak => _currentStreak;
  int get bestStreak => _bestStreak;
  Map<String, int> get achievementsByRarity => _achievementsByRarity;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setToken(String token) {
    _apiService.setToken(token);
  }

  List<Achievement> get earnedAchievements {
    return _achievements.where((a) => a.isEarned).toList()
      ..sort((a, b) => b.earnedAt!.compareTo(a.earnedAt!));
  }

  List<Achievement> get unearnedAchievements {
    return _achievements.where((a) => !a.isEarned).toList()
      ..sort((a, b) => b.progressPercentage.compareTo(a.progressPercentage));
  }

  List<Achievement> get recentAchievements {
    return earnedAchievements.take(3).toList();
  }

  Future<void> loadGamificationData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getGamificationAnalytics();
      
      _totalPoints = data['total_points'] ?? 0;
      _userLevel = UserLevel.fromGamificationData(data);
      _achievementsByRarity = Map<String, int>.from(
        data['achievements_by_rarity'] ?? {}
      );
      
      // Streak data
      final streaks = data['streaks']?['daily_completion'] ?? {};
      _currentStreak = streaks['current'] ?? 0;
      _bestStreak = streaks['best'] ?? 0;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAchievements() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getAllAchievements();
      
      _achievements = (data['achievements'] as List<dynamic>?)
              ?.map((a) => Achievement.fromJson(a))
              .toList() ??
          [];
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadLeaderboard({int limit = 10}) async {
    try {
      final data = await _apiService.getLeaderboard(limit: limit);
      
      _leaderboard = (data['leaderboard'] as List<dynamic>?)
              ?.map((entry) => LeaderboardEntry.fromJson(entry))
              .toList() ??
          [];
      
      notifyListeners();
    } catch (e) {
      print('Leaderboard error: $e');
    }
  }

  Future<void> checkNewAchievements() async {
    try {
      final data = await _apiService.checkNewAchievements();
      
      final newAchievements = (data['achievements'] as List<dynamic>?)
              ?.map((a) => Achievement.fromJson(a))
              .toList() ??
          [];
      
      if (newAchievements.isNotEmpty) {
        // Reload all data to update
        await loadGamificationData();
        await loadAchievements();
        
        // Notify about new achievements
        _showAchievementNotification(newAchievements);
      }
    } catch (e) {
      print('Check achievements error: $e');
    }
  }

  void _showAchievementNotification(List<Achievement> achievements) {
    // This will be handled by the UI
    notifyListeners();
  }

  Future<void> refresh() async {
    await loadGamificationData();
    await loadAchievements();
    await loadLeaderboard();
  }
}