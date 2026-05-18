import 'package:flutter/material.dart';

class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final EventType type;
  final String? taskId;
  final Map<String, dynamic>? metadata;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    required this.color,
    required this.type,
    this.taskId,
    this.metadata,
  });

  Duration get duration => endTime.difference(startTime);

  bool isOnDate(DateTime date) {
    return startTime.year == date.year &&
        startTime.month == date.month &&
        startTime.day == date.day;
  }

  bool overlaps(CalendarEvent other) {
    return (startTime.isBefore(other.endTime) && endTime.isAfter(other.startTime));
  }
}

enum EventType {
  task,
  timeBlock,
  pomodoroSession,
  breakTime,
}

class TimeBlock {
  final String id;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final Color color;
  final List<String>? taskIds;
  final bool isSynced; // Track if synced to backend

  TimeBlock({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.color,
    this.taskIds,
    this.isSynced = false, // Default to not synced
  });

  factory TimeBlock.fromJson(Map<String, dynamic> json) {
    return TimeBlock(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? '',
      startTime: DateTime.parse(json['start_time']),
      endTime: DateTime.parse(json['end_time']),
      color: Color(json['color'] ?? 0xFF2196F3),
      taskIds: json['task_ids'] != null 
          ? List<String>.from(json['task_ids'])
          : null,
      isSynced: true, // From backend = synced
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'color': color.value,
      'task_ids': taskIds,
    };
  }

  TimeBlock copyWith({
    String? id,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    Color? color,
    List<String>? taskIds,
    bool? isSynced,
  }) {
    return TimeBlock(
      id: id ?? this.id,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      color: color ?? this.color,
      taskIds: taskIds ?? this.taskIds,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Duration get duration => endTime.difference(startTime);
}

class PomodoroSession {
  final String id;
  final DateTime startTime;
  final int workMinutes;
  final int breakMinutes;
  final int completedCycles;
  final int totalCycles;
  final PomodoroPhase currentPhase;
  final bool isActive;

  PomodoroSession({
    required this.id,
    required this.startTime,
    this.workMinutes = 25,
    this.breakMinutes = 5,
    this.completedCycles = 0,
    this.totalCycles = 4,
    this.currentPhase = PomodoroPhase.work,
    this.isActive = false,
  });

  PomodoroSession copyWith({
    String? id,
    DateTime? startTime,
    int? workMinutes,
    int? breakMinutes,
    int? completedCycles,
    int? totalCycles,
    PomodoroPhase? currentPhase,
    bool? isActive,
  }) {
    return PomodoroSession(
      id: id ?? this.id,
      startTime: startTime ?? this.startTime,
      workMinutes: workMinutes ?? this.workMinutes,
      breakMinutes: breakMinutes ?? this.breakMinutes,
      completedCycles: completedCycles ?? this.completedCycles,
      totalCycles: totalCycles ?? this.totalCycles,
      currentPhase: currentPhase ?? this.currentPhase,
      isActive: isActive ?? this.isActive,
    );
  }

  int get currentMinutes {
    return currentPhase == PomodoroPhase.work ? workMinutes : breakMinutes;
  }
}

enum PomodoroPhase {
  work,
  shortBreak,
  longBreak,
}