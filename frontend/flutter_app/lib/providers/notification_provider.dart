import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../services/api_service.dart';

class NotificationProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<AppNotification> _notifications = [];
  bool _isLoading = false;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  void setToken(String token) {
    _apiService.setToken(token);
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.getNotifications();
      _notifications = (data['notifications'] as List)
          .map((json) => AppNotification.fromJson(json))
          .toList();
    } catch (e) {
      print('Load notifications error: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String id) async {
    try {
      await _apiService.markNotificationRead(id);
      _notifications = _notifications.map((n) {
        return n.id == id ? n.copyWith(isRead: true) : n;
      }).toList();
      notifyListeners();
    } catch (e) {
      print('Mark read error: $e');
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _apiService.markAllNotificationsRead();
      _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
      notifyListeners();
    } catch (e) {
      print('Mark all read error: $e');
    }
  }

  void addLocal(AppNotification notification) {
    _notifications.insert(0, notification);
    notifyListeners();
  }
}