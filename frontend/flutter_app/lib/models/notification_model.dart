import 'package:flutter/material.dart';

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String type; // 'reminder', 'suggestion', 'achievement', 'deadline', 'system'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final String? actionLabel;
  final String? actionType;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.actionLabel,
    this.actionType,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'system',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      isRead: json['is_read'] ?? false,
      data: json['data'],
      actionLabel: json['action_label'],
      actionType: json['action_type'],
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      data: data,
      actionLabel: actionLabel,
      actionType: actionType,
    );
  }

  IconData get icon {
    switch (type) {
      case 'reminder':
        return Icons.notifications_active;
      case 'suggestion':
        return Icons.lightbulb;
      case 'achievement':
        return Icons.emoji_events;
      case 'deadline':
        return Icons.warning_amber;
      default:
        return Icons.notifications;
    }
  }

  Color get color {
    switch (type) {
      case 'reminder':
        return Colors.blue;
      case 'suggestion':
        return Colors.purple;
      case 'achievement':
        return Colors.amber;
      case 'deadline':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}