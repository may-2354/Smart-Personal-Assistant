import 'package:flutter/material.dart';

class Task {
  final int id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final String? category;
  final DateTime? deadline;
  final int carryoverCount;
  final bool isUrgent;
  final bool isImportant;
  final List<String> tags;
  final DateTime createdAt;
    final DateTime updatedAt;
  final int? estimated_duration;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.category,
    this.deadline,
    this.carryoverCount = 0,
    this.isUrgent = false,
    this.isImportant = false,
    this.tags = const [],
    required this.createdAt,
    required this.updatedAt,
    this.estimated_duration, 
  });

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      priority: json['priority'],
      category: json['category'],
      deadline: json['deadline'] != null 
          ? DateTime.parse(json['deadline']) 
          : null,
      carryoverCount: json['carryover_count'] ?? 0,
      isUrgent: json['is_urgent'] ?? false,
      isImportant: json['is_important'] ?? false,
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
      estimated_duration: json['estimated_duration'],
    );
  }

  Color get priorityColor {
    switch (priority.toLowerCase()) {
      case 'critical':
        return const Color(0xFFFF5252);
      case 'high':
        return const Color(0xFFFF9800);
      case 'medium':
        return const Color(0xFF2196F3);
      case 'low':
        return const Color(0xFF4CAF50);
      default:
        return Colors.grey;
    }
  }

  String get eisenhowerQuadrant {
    if (isUrgent && isImportant) return 'Do First';
    if (!isUrgent && isImportant) return 'Schedule';
    if (isUrgent && !isImportant) return 'Delegate';
    return 'Eliminate';
  }
}