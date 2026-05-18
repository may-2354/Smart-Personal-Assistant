import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/notification_provider.dart';
import '../../config/theme_config.dart';
import '../../widgets/notification_card.dart';
import '../../services/storage_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<NotificationProvider>(context, listen: false);
    final token = await StorageService().getToken();
    if (token != null) {
      provider.setToken(token);
      await provider.loadNotifications();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NotificationProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(text: 'All (${provider.notifications.length})'),
            Tab(text: 'Reminders'),
            Tab(text: 'Suggestions'),
            Tab(text: 'Achievements'),
            Tab(text: 'Deadlines'),
          ],
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: () => provider.markAllAsRead(),
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNotificationList(provider.notifications),
          _buildNotificationList(
              provider.notifications.where((n) => n.type == 'reminder').toList()),
          _buildNotificationList(
              provider.notifications.where((n) => n.type == 'suggestion').toList()),
          _buildNotificationList(
              provider.notifications.where((n) => n.type == 'achievement').toList()),
          _buildNotificationList(
              provider.notifications.where((n) => n.type == 'deadline').toList()),
        ],
      ),
    );
  }

  Widget _buildNotificationList(List notifications) {
    if (notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No notifications',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: notifications.length,
        itemBuilder: (context, index) {
          final notification = notifications[index];
          return NotificationCard(
            notification: notification,
            onTap: () async {
              final provider =
                  Provider.of<NotificationProvider>(context, listen: false);
              await provider.markAsRead(notification.id);
            },
            onAction: () {
              // Handle action button tap
              if (notification.actionType == 'view_task') {
                // Navigate to task detail
              } else if (notification.actionType == 'reschedule') {
                // Open reschedule dialog
              }
            },
            onDismiss: () {
              // Could add delete functionality
            },
          );
        },
      ),
    );
  }
}