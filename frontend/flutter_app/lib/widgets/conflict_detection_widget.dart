import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/scheduling_provider.dart';
import '../providers/task_provider.dart';
import '../providers/calendar_provider.dart';
import '../models/scheduling_models.dart';
import '../config/theme_config.dart';

class ConflictDetectionWidget extends StatelessWidget {
  final VoidCallback? onRefresh;

  const ConflictDetectionWidget({super.key, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<SchedulingProvider>(context);

    if (!provider.hasConflicts) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.check_circle,
                size: 64,
                color: AppTheme.successColor,
              ),
              const SizedBox(height: 16),
              Text(
                'No Conflicts Detected',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.successColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your schedule is optimized!',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: onRefresh ?? () => _refreshConflicts(context),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Card(
          color: Colors.red.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: Colors.red.shade700,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${provider.conflicts.length} Conflict${provider.conflicts.length > 1 ? 's' : ''} Found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Overlapping items in your schedule',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.red.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: onRefresh ?? () => _refreshConflicts(context),
                  tooltip: 'Refresh conflicts',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Conflicts list
        ...provider.conflicts.map((conflict) {
          return _buildConflictCard(context, conflict, provider);
        }),
      ],
    );
  }

  Widget _buildConflictCard(
    BuildContext context,
    ScheduleConflict conflict,
    SchedulingProvider provider,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Conflict header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: conflict.severity.color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  conflict.severity.icon,
                  color: conflict.severity.color,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${conflict.severity.label} Conflict',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: conflict.severity.color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conflict.description,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Conflict details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${DateFormat('h:mm a').format(conflict.conflictStart)} - ${DateFormat('h:mm a').format(conflict.conflictEnd)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.timelapse,
                      size: 16,
                      color: AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${conflict.overlapDuration.inMinutes} min overlap',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: conflict.severity.color,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Resolve button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showResolutionDialog(context, conflict, provider),
                    icon: const Icon(Icons.auto_fix_high, size: 18),
                    label: const Text('AI Suggestions'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showResolutionDialog(
    BuildContext context,
    ScheduleConflict conflict,
    SchedulingProvider provider,
  ) {
    final options = provider.generateRescheduleOptions(conflict);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.psychology,
                      color: AppTheme.primaryColor,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'AI Reschedule Suggestions',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),

              // Options list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: options.length,
                  itemBuilder: (context, index) {
                    return _buildOptionCard(context, options[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOptionCard(BuildContext context, RescheduleOption option) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () async {
          Navigator.pop(context);
          await _applyReschedule(context, option);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      option.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  _buildConfidenceBadge(option.confidence),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                option.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${DateFormat('h:mm a').format(option.newStart)} - ${DateFormat('h:mm a').format(option.newEnd)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Reasons
              ...option.reasons.map((reason) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: AppTheme.successColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          reason,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConfidenceBadge(double confidence) {
    Color color;
    if (confidence >= 85) {
      color = AppTheme.successColor;
    } else if (confidence >= 70) {
      color = AppTheme.primaryColor;
    } else {
      color = AppTheme.warningColor;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.psychology, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${confidence.toInt()}%',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _applyReschedule(BuildContext context, RescheduleOption option) async {
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            SizedBox(width: 12),
            Text('Applying reschedule...'),
          ],
        ),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final schedulingProvider = Provider.of<SchedulingProvider>(context, listen: false);
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);

      // Apply the reschedule
      await schedulingProvider.applyRescheduleOption(option, taskProvider);

      // Refresh data
      await taskProvider.loadTasks();
      await calendarProvider.loadEventsForDate(calendarProvider.selectedDate);
      
      // Re-detect conflicts
      await schedulingProvider.detectConflicts(
        taskProvider.tasks,
        calendarProvider.timeBlocks,
      );

      if (context.mounted) {
        // Dismiss loading snackbar
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '✅ Changes Applied Successfully!',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        option.title,
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.successColor,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                // User can tap to see the updated schedule
              },
            ),
          ),
        );

        // Show a dialog with summary
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: AppTheme.successColor),
                const SizedBox(width: 12),
                const Text('Reschedule Applied'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  option.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.successColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppTheme.successColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'New time: ${DateFormat('h:mm a').format(option.newStart)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Your schedule has been updated and conflicts have been resolved.',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('GOT IT'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        // Dismiss loading
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        
        // Show error
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Failed to Apply Changes',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.toString(),
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.errorColor,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _refreshConflicts(BuildContext context) async {
    final schedulingProvider = Provider.of<SchedulingProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    final calendarProvider = Provider.of<CalendarProvider>(context, listen: false);

    // Just re-detect conflicts with current data, don't reload tasks
    await schedulingProvider.detectConflicts(
      taskProvider.tasks,
      calendarProvider.timeBlocks,
    );
  }
}