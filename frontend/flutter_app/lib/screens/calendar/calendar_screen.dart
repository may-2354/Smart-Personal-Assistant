import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/calendar_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/scheduling_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme_config.dart';
import '../../widgets/task_calendar.dart';
import '../../widgets/time_blocking_view.dart';
import '../../widgets/pomodoro_timer.dart';
import '../../widgets/conflict_detection_widget.dart';
import '../../screens/scheduling/plan_my_day_screen.dart';
import '../../services/storage_service.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageStorageBucket _bucket = PageStorageBucket();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initCalendar();
  }

  Future<void> _initCalendar() async {
    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final schedulingProvider = Provider.of<SchedulingProvider>(context, listen: false);
    
    // Set token
    final token = await StorageService().getToken();
    if (token != null) {
      calendarProvider.setToken(token);
      await calendarProvider.loadEventsForDate(DateTime.now());
      
      // Detect conflicts after loading
      await schedulingProvider.detectConflicts(
        taskProvider.tasks,
        calendarProvider.timeBlocks,
      );
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          // Plan My Day button - THIS IS NEW! ✨
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            tooltip: 'Plan My Day',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PlanMyDayScreen(),
                ),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              icon: Icon(Icons.calendar_month),
              text: 'Calendar',
            ),
            Tab(
              icon: Icon(Icons.view_timeline),
              text: 'Schedule',
            ),
            Tab(
              icon: Icon(Icons.timer),
              text: 'Pomodoro',
            ),
          ],
        ),
      ),
      body: PageStorage(
        bucket: _bucket,
        child: TabBarView(
          controller: _tabController,
          children: const [
            // Calendar Tab
            _CalendarTab(),
            
            // Schedule Tab
            _ScheduleTab(),
            
            // Pomodoro Tab
            _PomodoroTab(),
          ],
        ),
      ),
    );
  }
}

class _CalendarTab extends StatelessWidget {
  const _CalendarTab();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarProvider>(context);

    return RefreshIndicator(
      onRefresh: () async {
        await provider.loadEventsForDate(provider.selectedDate);
        
        // Also refresh conflicts when pulling to refresh
        final schedulingProvider = Provider.of<SchedulingProvider>(context, listen: false);
        final taskProvider = Provider.of<TaskProvider>(context, listen: false);
        await taskProvider.loadTasks();
        await schedulingProvider.detectConflicts(
          taskProvider.tasks,
          provider.timeBlocks,
        );
      },
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Conflict Detection Widget - THIS IS NEW! ✨
            const ConflictDetectionWidget(),
            const SizedBox(height: 16),

            // Calendar widget
            const TaskCalendar(),
            const SizedBox(height: 24),

            // Selected date events
            Text(
              'Tasks & Events',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            // Events list
            _buildEventsList(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildEventsList(CalendarProvider provider) {
    final events = provider.getEventsForDay(provider.selectedDate);

    if (provider.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (events.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.event_available,
                  size: 48,
                  color: AppTheme.textSecondary.withOpacity(0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No tasks for this day',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: events.map((event) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            title: Text(
              event.title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '${event.startTime.hour}:${event.startTime.minute.toString().padLeft(2, '0')} - ${event.endTime.hour}:${event.endTime.minute.toString().padLeft(2, '0')}',
            ),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: event.color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                event.metadata?['priority'] ?? 'medium',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: event.color,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ScheduleTab extends StatelessWidget {
  const _ScheduleTab();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: TimeBlockingView(),
    );
  }
}

class _PomodoroTab extends StatelessWidget {
  const _PomodoroTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const PageStorageKey('pomodoro_scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Pomodoro timer with key to preserve state
          const PomodoroTimer(key: PageStorageKey('pomodoro_timer')),
          const SizedBox(height: 24),

          // Pomodoro info
          Text(
            'About Pomodoro Technique',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          _buildInfoCard(
            icon: Icons.schedule,
            title: 'Work Sessions',
            description: 'Focus on a single task for 25 minutes without interruptions.',
          ),
          const SizedBox(height: 8),

          _buildInfoCard(
            icon: Icons.coffee,
            title: 'Short Breaks',
            description: 'Take a 5-minute break after each work session to recharge.',
          ),
          const SizedBox(height: 8),

          _buildInfoCard(
            icon: Icons.spa,
            title: 'Long Breaks',
            description: 'After 4 cycles, take a longer 15-30 minute break.',
          ),
          const SizedBox(height: 8),

          _buildInfoCard(
            icon: Icons.trending_up,
            title: 'Boost Productivity',
            description: 'Regular breaks improve focus and prevent burnout.',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppTheme.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}