import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/scheduling_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/calendar_provider.dart';
import '../../models/scheduling_models.dart';
import '../../config/theme_config.dart';
import '../../services/storage_service.dart';

class PlanMyDayScreen extends StatefulWidget {
  const PlanMyDayScreen({super.key});

  @override
  State<PlanMyDayScreen> createState() => _PlanMyDayScreenState();
}

class _PlanMyDayScreenState extends State<PlanMyDayScreen> {
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final token = await StorageService().getToken();
    if (token != null && mounted) {
      final schedulingProvider = Provider.of<SchedulingProvider>(context, listen: false);
      // Token would be set if needed
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedulingProvider = Provider.of<SchedulingProvider>(context);
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan My Day'),
        actions: [
          if (schedulingProvider.dayPlan != null)
            IconButton(
              icon: const Icon(Icons.close),
              tooltip: 'Clear Plan',
              onPressed: () => _showClearDialog(context, schedulingProvider),
            ),
        ],
      ),
      body: schedulingProvider.dayPlan == null
          ? _buildPlanningView(schedulingProvider, taskProvider)
          : _buildDayPlanView(schedulingProvider),
    );
  }

  Widget _buildPlanningView(
    SchedulingProvider schedulingProvider,
    TaskProvider taskProvider,
  ) {
    // Filter out completed tasks
    final todayTasks = taskProvider.todayTasks
        .where((task) => task.status != 'completed')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text(
            '🎯 Optimize Your Day',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'AI will create a smart Pomodoro schedule based on your tasks',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Today's tasks
          _buildTodayTasksCard(todayTasks),
          const SizedBox(height: 24),

          // Benefits
          _buildBenefitsList(),
          const SizedBox(height: 32),

          // Generate button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: todayTasks.isEmpty || schedulingProvider.isGenerating
                  ? null
                  : () => _generatePlan(schedulingProvider, taskProvider),
              icon: schedulingProvider.isGenerating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Text(
                schedulingProvider.isGenerating
                    ? 'Generating Your Plan...'
                    : 'Generate My Day Plan 🚀',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayPlanView(SchedulingProvider provider) {
    final plan = provider.dayPlan!;

    return Column(
      children: [
        // Summary header
        _buildPlanSummary(plan),

        // Sessions list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plan.sessions.length,
            itemBuilder: (context, index) {
              final session = plan.sessions[index];
              return _buildSessionCard(context, session, provider);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTodayTasksCard(List todayTasks) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.today, color: AppTheme.primaryColor),
                const SizedBox(width: 12),
                Text(
                  'Tasks for Today',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${todayTasks.length}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (todayTasks.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.event_available,
                        size: 48,
                        color: AppTheme.textSecondary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'No tasks scheduled for today',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...todayTasks.take(5).map((task) => _buildTaskItem(task)),
            if (todayTasks.length > 5) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '+${todayTasks.length - 5} more tasks',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaskItem(task) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: task.priorityColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 12,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${task.estimated_duration ?? 30} min',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: task.priorityColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        task.priority.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: task.priorityColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitsList() {
    return Column(
      children: [
        _buildBenefitCard(
          Icons.psychology,
          'AI-Optimized',
          'Tasks arranged by priority and deadline for maximum productivity',
        ),
        const SizedBox(height: 12),
        _buildBenefitCard(
          Icons.timer,
          'Pomodoro Method',
          'Work in focused 25-minute intervals with smart breaks',
        ),
        const SizedBox(height: 12),
        _buildBenefitCard(
          Icons.track_changes,
          'Track Progress',
          'Click sessions to start timer and track completion',
        ),
      ],
    );
  }

  Widget _buildBenefitCard(IconData icon, String title, String description) {
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
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
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

  Widget _buildPlanSummary(DayPlan plan) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor.withOpacity(0.1),
            AppTheme.accentColor.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today, size: 20),
              const SizedBox(width: 8),
              Text(
                DateFormat('EEEE, MMM d').format(plan.date),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSummaryItem(
                Icons.task_alt,
                '${plan.tasksIncluded}',
                'Tasks',
              ),
              _buildSummaryItem(
                Icons.timer,
                '${plan.sessions.where((s) => s.type == PomodoroSessionType.work).length}',
                'Sessions',
              ),
              _buildSummaryItem(
                Icons.schedule,
                '${(plan.totalDuration.inMinutes / 60).toStringAsFixed(1)}h',
                'Total Time',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppTheme.successColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: AppTheme.successColor,
                ),
                const SizedBox(width: 6),
                Text(
                  'Finish by ${DateFormat('h:mm a').format(plan.estimatedEndTime)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppTheme.primaryColor),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    PomodoroSession session,
    SchedulingProvider provider,
  ) {
    final isBreak = session.type != PomodoroSessionType.work;
    final color = isBreak ? AppTheme.successColor : AppTheme.primaryColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: session.isCompleted ? 0 : 2,
      child: Opacity(
        opacity: session.isCompleted ? 0.6 : 1.0,
        child: InkWell(
          onTap: session.isCompleted
              ? null
              : () => _startSession(context, session, provider),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Time
                Container(
                  width: 60,
                  child: Text(
                    DateFormat('h:mm a').format(session.scheduledStart),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ),

                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: session.isCompleted
                        ? AppTheme.successColor.withOpacity(0.2)
                        : color.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Icon(
                      session.isCompleted
                          ? Icons.check_circle
                          : (isBreak ? Icons.coffee : Icons.timer),
                      color: session.isCompleted ? AppTheme.successColor : color,
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: session.isCompleted
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${session.duration.inMinutes} minutes',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // Play icon
                if (!session.isCompleted)
                  Icon(
                    Icons.play_circle_filled,
                    color: color,
                    size: 32,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _generatePlan(
    SchedulingProvider schedulingProvider,
    TaskProvider taskProvider,
  ) async {
    // Filter out completed tasks before planning
    final incompleteTasks = taskProvider.todayTasks
        .where((task) => task.status != 'completed')
        .toList();
    
    await schedulingProvider.planMyDay(incompleteTasks);

    if (schedulingProvider.dayPlan != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✨ Plan generated with ${schedulingProvider.dayPlan!.sessions.length} sessions!',
          ),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  void _startSession(
    BuildContext context,
    PomodoroSession session,
    SchedulingProvider provider,
  ) {
    // Start Pomodoro timer with this session
    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);
    calendarProvider.startPomodoro(
      workMinutes: session.duration.inMinutes,
      breakMinutes: session.type == PomodoroSessionType.work ? 5 : 0,
    );

    // Mark as completed
    provider.completeSession(session.id);

    // Navigate to calendar/pomodoro tab
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('⏱️ Started: ${session.title}'),
        backgroundColor: AppTheme.primaryColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showClearDialog(BuildContext context, SchedulingProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Day Plan?'),
        content: const Text(
          'This will remove all planned Pomodoro sessions. You can generate a new plan anytime.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.clearDayPlan();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}