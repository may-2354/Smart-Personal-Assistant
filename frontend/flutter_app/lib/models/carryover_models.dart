import 'package:flutter/material.dart';

class CarryoverStats {
  final int totalCarryovers;
  final int activeOverdueTasks;
  final int highPriorityOverdue;
  final double averageCarryoverCount;
  final int consecutiveCarryoverDays;
  final Map<String, int> carryoversByCategory;
  final Map<String, int> carryoversByPriority;
  final List<CarryoverTrend> weeklyTrends;

  CarryoverStats({
    required this.totalCarryovers,
    required this.activeOverdueTasks,
    required this.highPriorityOverdue,
    required this.averageCarryoverCount,
    required this.consecutiveCarryoverDays,
    required this.carryoversByCategory,
    required this.carryoversByPriority,
    required this.weeklyTrends,
  });

  factory CarryoverStats.fromJson(Map<String, dynamic> json) {
    return CarryoverStats(
      totalCarryovers: json['total_carryovers'] ?? 0,
      activeOverdueTasks: json['active_overdue_tasks'] ?? 0,
      highPriorityOverdue: json['high_priority_overdue'] ?? 0,
      averageCarryoverCount: (json['average_carryover_count'] ?? 0).toDouble(),
      consecutiveCarryoverDays: json['consecutive_carryover_days'] ?? 0,
      carryoversByCategory: Map<String, int>.from(
        json['carryovers_by_category'] ?? {},
      ),
      carryoversByPriority: Map<String, int>.from(
        json['carryovers_by_priority'] ?? {},
      ),
      weeklyTrends: (json['weekly_trends'] as List<dynamic>?)
              ?.map((t) => CarryoverTrend.fromJson(t))
              .toList() ??
          [],
    );
  }

  bool get hasOverdueTasks => activeOverdueTasks > 0;
  bool get isCritical => highPriorityOverdue > 0 || activeOverdueTasks > 10;
  
  String get severityLevel {
    if (activeOverdueTasks == 0) return 'none';
    if (activeOverdueTasks <= 3) return 'low';
    if (activeOverdueTasks <= 7) return 'medium';
    if (activeOverdueTasks <= 15) return 'high';
    return 'critical';
  }

  Color get severityColor {
    switch (severityLevel) {
      case 'none':
        return Colors.green;
      case 'low':
        return Colors.yellow.shade700;
      case 'medium':
        return Colors.orange.shade700;
      case 'high':
        return Colors.red.shade600;
      case 'critical':
        return Colors.red.shade900;
      default:
        return Colors.grey;
    }
  }
}

class CarryoverTrend {
  final DateTime date;
  final int count;

  CarryoverTrend({
    required this.date,
    required this.count,
  });

  factory CarryoverTrend.fromJson(Map<String, dynamic> json) {
    return CarryoverTrend(
      date: DateTime.parse(json['date']),
      count: json['count'] ?? 0,
    );
  }
}

class DelayPattern {
  final String pattern;
  final String description;
  final int frequency;
  final double impactScore;
  final List<String> affectedCategories;

  DelayPattern({
    required this.pattern,
    required this.description,
    required this.frequency,
    required this.impactScore,
    required this.affectedCategories,
  });

  factory DelayPattern.fromJson(Map<String, dynamic> json) {
    return DelayPattern(
      pattern: json['pattern'] ?? '',
      description: json['description'] ?? '',
      frequency: json['frequency'] ?? 0,
      impactScore: (json['impact_score'] ?? 0).toDouble(),
      affectedCategories: List<String>.from(json['affected_categories'] ?? []),
    );
  }
}

class SmartSuggestion {
  final String id;
  final String title;
  final String description;
  final SuggestionType type;
  final int priority;
  final List<String> actionSteps;
  final String expectedImpact;

  SmartSuggestion({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.priority,
    required this.actionSteps,
    required this.expectedImpact,
  });

  factory SmartSuggestion.fromJson(Map<String, dynamic> json) {
    return SmartSuggestion(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      type: _typeFromString(json['type'] ?? 'general'),
      priority: json['priority'] ?? 0,
      actionSteps: List<String>.from(json['action_steps'] ?? []),
      expectedImpact: json['expected_impact'] ?? '',
    );
  }

  static SuggestionType _typeFromString(String type) {
    switch (type.toLowerCase()) {
      case 'time_management':
        return SuggestionType.timeManagement;
      case 'priority':
        return SuggestionType.priority;
      case 'task_breakdown':
        return SuggestionType.taskBreakdown;
      case 'schedule':
        return SuggestionType.schedule;
      default:
        return SuggestionType.general;
    }
  }

  IconData get icon {
    switch (type) {
      case SuggestionType.timeManagement:
        return Icons.access_time;
      case SuggestionType.priority:
        return Icons.priority_high;
      case SuggestionType.taskBreakdown:
        return Icons.call_split;
      case SuggestionType.schedule:
        return Icons.calendar_today;
      case SuggestionType.general:
        return Icons.lightbulb;
    }
  }

  Color get color {
    switch (type) {
      case SuggestionType.timeManagement:
        return Colors.blue;
      case SuggestionType.priority:
        return Colors.orange;
      case SuggestionType.taskBreakdown:
        return Colors.purple;
      case SuggestionType.schedule:
        return Colors.green;
      case SuggestionType.general:
        return Colors.grey;
    }
  }
}

enum SuggestionType {
  timeManagement,
  priority,
  taskBreakdown,
  schedule,
  general,
}

class RescheduleResult {
  final int rescheduledCount;
  final int failedCount;
  final List<String> rescheduledTaskIds;
  final String message;

  RescheduleResult({
    required this.rescheduledCount,
    required this.failedCount,
    required this.rescheduledTaskIds,
    required this.message,
  });

  factory RescheduleResult.fromJson(Map<String, dynamic> json) {
    return RescheduleResult(
      rescheduledCount: json['rescheduled_count'] ?? 0,
      failedCount: json['failed_count'] ?? 0,
      rescheduledTaskIds: List<String>.from(
        (json['rescheduled_tasks'] ?? []).map((t) => t['id'].toString()),
      ),
      message: json['message'] ?? '',
    );
  }

  bool get isSuccess => failedCount == 0;
}