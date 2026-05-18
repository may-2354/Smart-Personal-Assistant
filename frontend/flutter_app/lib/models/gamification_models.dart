import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final String badgeIcon;
  final AchievementRarity rarity;
  final int points;
  final bool isEarned;
  final DateTime? earnedAt;
  final double progress;
  final int target;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.badgeIcon,
    required this.rarity,
    required this.points,
    this.isEarned = false,
    this.earnedAt,
    this.progress = 0,
    this.target = 1,
  });

  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      badgeIcon: json['badge_icon'] ?? '🏆',
      rarity: _rarityFromString(json['rarity'] ?? 'common'),
      points: json['points'] ?? 0,
      isEarned: json['is_earned'] ?? false,
      earnedAt: json['earned_at'] != null 
          ? DateTime.parse(json['earned_at'])
          : null,
      progress: (json['progress'] ?? 0).toDouble(),
      target: json['target'] ?? 1,
    );
  }

  static AchievementRarity _rarityFromString(String rarity) {
    switch (rarity.toLowerCase()) {
      case 'legendary':
        return AchievementRarity.legendary;
      case 'epic':
        return AchievementRarity.epic;
      case 'rare':
        return AchievementRarity.rare;
      default:
        return AchievementRarity.common;
    }
  }

  double get progressPercentage => (progress / target * 100).clamp(0, 100);
}

enum AchievementRarity {
  common,
  rare,
  epic,
  legendary,
}

extension AchievementRarityExtension on AchievementRarity {
  Color get color {
    switch (this) {
      case AchievementRarity.legendary:
        return const Color(0xFFFFD700); // Gold
      case AchievementRarity.epic:
        return const Color(0xFF9C27B0); // Purple
      case AchievementRarity.rare:
        return const Color(0xFF2196F3); // Blue
      case AchievementRarity.common:
        return const Color(0xFF9E9E9E); // Gray
    }
  }

  String get name {
    switch (this) {
      case AchievementRarity.legendary:
        return 'Legendary';
      case AchievementRarity.epic:
        return 'Epic';
      case AchievementRarity.rare:
        return 'Rare';
      case AchievementRarity.common:
        return 'Common';
    }
  }

  IconData get icon {
    switch (this) {
      case AchievementRarity.legendary:
        return Icons.diamond;
      case AchievementRarity.epic:
        return Icons.star;
      case AchievementRarity.rare:
        return Icons.star_half;
      case AchievementRarity.common:
        return Icons.circle;
    }
  }
}

class LeaderboardEntry {
  final String userId;
  final String username;
  final String? avatar;
  final int points;
  final int level;
  final int rank;

  LeaderboardEntry({
    required this.userId,
    required this.username,
    this.avatar,
    required this.points,
    required this.level,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id']?.toString() ?? '',
      username: json['username'] ?? 'Unknown',
      avatar: json['avatar'],
      points: json['points'] ?? 0,
      level: json['level'] ?? 1,
      rank: json['rank'] ?? 0,
    );
  }
}

class UserLevel {
  final int level;
  final int currentXP;
  final int xpToNextLevel;
  final String title;

  UserLevel({
    required this.level,
    required this.currentXP,
    required this.xpToNextLevel,
    required this.title,
  });

  factory UserLevel.fromGamificationData(Map<String, dynamic> data) {
    final level = data['level'] ?? 1;
    final currentPoints = data['total_points'] ?? 0;
    final pointsToNext = data['points_to_next_level'] ?? 100;
    
    return UserLevel(
      level: level,
      currentXP: currentPoints,
      xpToNextLevel: pointsToNext,
      title: _getTitleForLevel(level),
    );
  }

  static String _getTitleForLevel(int level) {
    if (level >= 50) return 'Grandmaster';
    if (level >= 40) return 'Master';
    if (level >= 30) return 'Expert';
    if (level >= 20) return 'Professional';
    if (level >= 10) return 'Intermediate';
    if (level >= 5) return 'Apprentice';
    return 'Novice';
  }

  double get progressPercentage {
    if (xpToNextLevel == 0) return 100;
    return (currentXP / (currentXP + xpToNextLevel) * 100).clamp(0, 100);
  }
}