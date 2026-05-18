import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/carryover_provider.dart';
import '../../config/theme_config.dart';
import '../../models/task_model.dart';
import '../../widgets/task_card.dart';
import '../../widgets/carryover_alert_banner.dart';
import '../../services/storage_service.dart';
import '../tasks/task_list_screen.dart';
import '../auth/login_screen.dart';
import '../chat/chat_screen.dart';
import '../analytics/analytics_screen.dart';
import '../calendar/calendar_screen.dart';
import '../gamification/gamification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final carryoverProvider = Provider.of<CarryoverProvider>(context, listen: false); // ADD THIS
  
  // Get token from storage service
    final token = await StorageService().getToken();
  
    if (token != null) {
      taskProvider.setToken(token);
      await taskProvider.refresh();
    
    // ADD THESE 3 LINES:
      carryoverProvider.setToken(token);
      await carryoverProvider.refreshAll(); // ← This loads overdue tasks & stats
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      drawer: _buildDrawer(context, authProvider),
      
      body: RefreshIndicator(
        onRefresh: () => taskProvider.refresh(),
        child: CustomScrollView(
          slivers: [
            // App Bar
            SliverAppBar(
              expandedHeight: 200,
              floating: false,
              pinned: true,
              flexibleSpace: FlexibleSpaceBar(
                title: Text('Welcome, ${authProvider.user?.username ?? ""}!'),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.primaryColor,
                        AppTheme.secondaryColor,
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ChatScreen()),
                    );
                  },
                    tooltip: 'Chat with AI',
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  onPressed: () async {
                    await authProvider.logout();
                    if (context.mounted) {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => const LoginScreen(),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),

            SliverToBoxAdapter(
              child: CarryoverAlertBanner(), // ← THE BANNER!
            ),

            // Stats Cards
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildStatsCards(taskProvider),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Quick Actions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ),

            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _buildQuickActions(context, taskProvider),
              ),
            ),

            // Today's Tasks
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Today's Tasks",
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TaskListScreen(),
                          ),
                        );
                      },
                      child: const Text('See All'),
                    ),
                  ],
                ),
              ),
            ),

            // Today's Task List
            taskProvider.isLoading
                ? const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                  )
                : taskProvider.todayTasks.isEmpty
                    ? SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 64,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No tasks for today!',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final task = taskProvider.todayTasks[index];
                            return TaskCard(
                              task: task,
                              onTap: () {
                                // Navigate to task detail
                              },
                              onComplete: () async {
                                await taskProvider.updateTask(
                                  task.id,
                                  {'status': 'completed'},
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Task completed! 🎉'),
                                      backgroundColor: AppTheme.successColor,
                                    ),
                                  );
                                }
                              },
                              onDelete: () => _confirmDelete(context, taskProvider, task),
                            );
                          },
                          childCount: taskProvider.todayTasks.length,
                        ),
                      ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const TaskListScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Task'),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context, AuthProvider authProvider) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Drawer Header
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryColor,
                  AppTheme.secondaryColor,
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.person,
                    size: 40,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  authProvider.user?.username ?? 'User',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  authProvider.user?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Home
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),

          // Tasks
          ListTile(
            leading: const Icon(Icons.task_alt),
            title: const Text('All Tasks'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const TaskListScreen()),
              );
            },
          ),

          // Calendar
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Calendar'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.successColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'NEW',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              );
            },
          ),

          // Chat
          ListTile(
            leading: const Icon(Icons.chat_bubble),
            title: const Text('AI Chat'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ChatScreen()),
              );
            },
          ),

          // Analytics
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
              );
            },
          ),

          // ⭐ ADD THIS - Achievements ⭐
          ListTile(
            leading: const Icon(Icons.emoji_events, color: Color(0xFFFFD700)),
            title: const Text('Achievements'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: const Color(0xFFFFD700),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🏆',
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'NEW',
                    style: TextStyle(
                      color: Color(0xFFFFD700),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const GamificationScreen()),
              );
            },
          ),

          const Divider(),

          // Settings
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to settings
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings coming soon!')),
              );
            },
          ),

          // Help
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Help & Support'),
            onTap: () {
              Navigator.pop(context);
              _showHelpDialog(context);
            },
          ),

          const Divider(),

          // Logout
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              Navigator.pop(context);
              final confirmed = await _showLogoutDialog(context);
              if (confirmed == true && context.mounted) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHelpItem('📋', 'Manage tasks with AI assistance'),
            _buildHelpItem('📅', 'Schedule with Calendar & Pomodoro'),
            _buildHelpItem('💬', 'Chat with AI for task creation'),
            _buildHelpItem('📊', 'Track productivity with Analytics'),
            _buildHelpItem('🏆', 'Earn achievements and level up'), // ADD THIS
            const SizedBox(height: 16),
            const Text(
              'Need more help? Contact support@smartassistant.com',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(String emoji, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Future<bool?> _showLogoutDialog(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards(TaskProvider taskProvider) {
    final stats = taskProvider.stats ?? {};
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.task_alt,
            title: 'Total',
            value: '${stats['total'] ?? 0}',
            color: AppTheme.primaryColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            title: 'Completed',
            value: '${stats['completed'] ?? 0}',
            color: AppTheme.successColor,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.pending,
            title: 'Pending',
            value: '${stats['pending'] ?? 0}',
            color: AppTheme.warningColor,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context, TaskProvider taskProvider) {
    return Column(
      children: [
        // First row: All Tasks, Overdue
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.list_alt,
                title: 'All Tasks',
                subtitle: '${taskProvider.tasks.length} total',
                color: AppTheme.primaryColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TaskListScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.warning_amber,
                title: 'Overdue',
                subtitle: '${taskProvider.overdueTasks.length} tasks',
                color: AppTheme.errorColor,
                onTap: () {
                  taskProvider.setFilter('pending');
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TaskListScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Second row: Calendar, Analytics
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.calendar_today,
                title: 'Calendar',
                subtitle: 'Schedule & Timer',
                color: AppTheme.successColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CalendarScreen(),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                icon: Icons.analytics,
                title: 'Analytics',
                subtitle: 'View insights',
                color: AppTheme.accentColor,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AnalyticsScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TaskProvider taskProvider,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await taskProvider.deleteTask(task.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      }
    }
  }
}