import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../models/calendar_models.dart';

enum ConflictType {
  taskVsTask,
  taskVsTimeBlock,
  timeBlockVsTimeBlock,
}

class ScheduleConflict {
  final String id;
  final ConflictType type;
  final dynamic item1; // Task or TimeBlock
  final dynamic item2; // Task or TimeBlock
  final DateTime conflictStart;
  final DateTime conflictEnd;
  final Duration overlapDuration;
  final ConflictSeverity severity;

  ScheduleConflict({
    required this.id,
    required this.type,
    required this.item1,
    required this.item2,
    required this.conflictStart,
    required this.conflictEnd,
    required this.overlapDuration,
    required this.severity,
  });

  String get description {
    final item1Title = _getItemTitle(item1);
    final item2Title = _getItemTitle(item2);
    final minutes = overlapDuration.inMinutes;
    
    switch (type) {
      case ConflictType.taskVsTask:
        return 'Tasks "$item1Title" and "$item2Title" overlap by $minutes min';
      case ConflictType.taskVsTimeBlock:
        return 'Task "$item1Title" conflicts with "$item2Title" ($minutes min)';
      case ConflictType.timeBlockVsTimeBlock:
        return 'Time blocks "$item1Title" and "$item2Title" overlap by $minutes min';
    }
  }

  String _getItemTitle(dynamic item) {
    if (item is Task) return item.title;
    if (item is TimeBlock) return item.title;
    if (item is CalendarEvent) return item.title;
    return 'Unknown';
  }
}

enum ConflictSeverity {
  low,    // < 15 min overlap
  medium, // 15-30 min overlap
  high,   // 30-60 min overlap
  critical, // > 60 min overlap
}

extension ConflictSeverityExtension on ConflictSeverity {
  Color get color {
    switch (this) {
      case ConflictSeverity.low:
        return Colors.yellow.shade700;
      case ConflictSeverity.medium:
        return Colors.orange.shade700;
      case ConflictSeverity.high:
        return const Color(0xFFFF6B6B);
      case ConflictSeverity.critical:
        return Colors.red.shade700;
    }
  }

  IconData get icon {
    switch (this) {
      case ConflictSeverity.low:
        return Icons.warning_amber;
      case ConflictSeverity.medium:
        return Icons.error_outline;
      case ConflictSeverity.high:
        return Icons.error;
      case ConflictSeverity.critical:
        return Icons.dangerous;
    }
  }

  String get label {
    switch (this) {
      case ConflictSeverity.low:
        return 'Minor';
      case ConflictSeverity.medium:
        return 'Moderate';
      case ConflictSeverity.high:
        return 'Serious';
      case ConflictSeverity.critical:
        return 'Critical';
    }
  }
}

class RescheduleOption {
  final String id;
  final String title;
  final String description;
  final DateTime newStart;
  final DateTime newEnd;
  final double confidence; // AI confidence score 0-100
  final List<String> reasons;
  Map<String, dynamic>? metadata; // Store task ID here

  RescheduleOption({
    required this.id,
    required this.title,
    required this.description,
    required this.newStart,
    required this.newEnd,
    required this.confidence,
    required this.reasons,
    this.metadata,
  });
}

class PomodoroSession {
  final String id;
  final Task task;
  final int sessionNumber;
  final int totalSessions;
  final DateTime scheduledStart;
  final Duration duration;
  final PomodoroSessionType type;
  final bool isCompleted;

  PomodoroSession({
    required this.id,
    required this.task,
    required this.sessionNumber,
    required this.totalSessions,
    required this.scheduledStart,
    required this.duration,
    required this.type,
    this.isCompleted = false,
  });

  DateTime get scheduledEnd => scheduledStart.add(duration);

  String get title {
    if (type == PomodoroSessionType.work) {
      return '${task.title} (Session $sessionNumber/$totalSessions)';
    } else if (type == PomodoroSessionType.shortBreak) {
      return 'Short Break';
    } else {
      return 'Long Break';
    }
  }

  PomodoroSession copyWith({
    bool? isCompleted,
  }) {
    return PomodoroSession(
      id: id,
      task: task,
      sessionNumber: sessionNumber,
      totalSessions: totalSessions,
      scheduledStart: scheduledStart,
      duration: duration,
      type: type,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

enum PomodoroSessionType {
  work,
  shortBreak,
  longBreak,
}

class DayPlan {
  final DateTime date;
  final List<PomodoroSession> sessions;
  final List<ScheduleConflict> conflicts;
  final int totalWorkMinutes;
  final int totalBreakMinutes;
  final int tasksIncluded;

  DayPlan({
    required this.date,
    required this.sessions,
    required this.conflicts,
    required this.totalWorkMinutes,
    required this.totalBreakMinutes,
    required this.tasksIncluded,
  });

  Duration get totalDuration => Duration(minutes: totalWorkMinutes + totalBreakMinutes);
  
  int get completedSessions => sessions.where((s) => s.isCompleted).length;
  
  double get completionPercentage {
    if (sessions.isEmpty) return 0;
    return (completedSessions / sessions.length * 100).clamp(0, 100);
  }

  DateTime get estimatedEndTime {
    if (sessions.isEmpty) return date;
    return sessions.last.scheduledEnd;
  }
}