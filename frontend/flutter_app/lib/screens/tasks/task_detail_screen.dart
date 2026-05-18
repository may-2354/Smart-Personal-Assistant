import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../config/theme_config.dart';
import 'edit_task_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  final Task task;

  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);
    final isCompleted = task.status == 'completed';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditTaskScreen(task: task),
                ),
              );
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'delete') {
                _confirmDelete(context, taskProvider);
              } else if (value == 'duplicate') {
                _duplicateTask(context, taskProvider);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'duplicate',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20),
                    SizedBox(width: 8),
                    Text('Duplicate'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, size: 20, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: BoxDecoration(
                    color: task.priorityColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    task.title,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          decoration: isCompleted ? TextDecoration.lineThrough : null,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Description
            if (task.description != null && task.description!.isNotEmpty) ...[
              _buildSectionTitle(context, 'Description'),
              const SizedBox(height: 8),
              Text(
                task.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
            ],

            // Details Grid
            _buildSectionTitle(context, 'Details'),
            const SizedBox(height: 12),
            _buildDetailsGrid(context),
            const SizedBox(height: 24),

            // Tags
            if (task.tags.isNotEmpty) ...[
              _buildSectionTitle(context, 'Tags'),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: task.tags.map((tag) => _buildTag(tag)).toList(),
              ),
              const SizedBox(height: 24),
            ],

            // Eisenhower Matrix Position
            if (task.isUrgent || task.isImportant) ...[
              _buildSectionTitle(context, 'Eisenhower Matrix'),
              const SizedBox(height: 12),
              _buildEisenhowerCard(context),
              const SizedBox(height: 24),
            ],

            // Completion Button
            if (!isCompleted)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _completeTask(context, taskProvider),
                  icon: const Icon(Icons.check_circle),
                  label: const Text('Mark as Complete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.successColor,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
    );
  }

  Widget _buildDetailsGrid(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            context,
            icon: Icons.flag_outlined,
            label: 'Priority',
            value: task.priority.toUpperCase(),
            color: task.priorityColor,
          ),
          const Divider(height: 1),
          _buildDetailRow(
            context,
            icon: Icons.info_outline,
            label: 'Status',
            value: task.status.replaceAll('_', ' ').toUpperCase(),
            color: _getStatusColor(task.status),
          ),
          if (task.category != null) ...[
            const Divider(height: 1),
            _buildDetailRow(
              context,
              icon: Icons.folder_outlined,
              label: 'Category',
              value: task.category!,
              color: Colors.blue,
            ),
          ],
          if (task.deadline != null) ...[
            const Divider(height: 1),
            _buildDetailRow(
              context,
              icon: Icons.calendar_today,
              label: 'Deadline',
              value: DateFormat('MMM dd, yyyy • hh:mm a').format(task.deadline!),
              color: _getDeadlineColor(task.deadline!),
            ),
          ],
          if (task.carryoverCount > 0) ...[
            const Divider(height: 1),
            _buildDetailRow(
              context,
              icon: Icons.repeat,
              label: 'Carryover Count',
              value: '${task.carryoverCount}x',
              color: AppTheme.warningColor,
            ),
          ],
          const Divider(height: 1),
          _buildDetailRow(
            context,
            icon: Icons.access_time,
            label: 'Created',
            value: DateFormat('MMM dd, yyyy').format(task.createdAt!),
            color: Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String tag) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Text(
        tag,
        style: const TextStyle(
          color: AppTheme.primaryColor,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildEisenhowerCard(BuildContext context) {
    final quadrant = task.eisenhowerQuadrant;
    final String title;
    final String description;
    final Color color;

    if (task.isUrgent && task.isImportant) {
      title = 'Do First';
      description = 'Urgent & Important';
      color = AppTheme.criticalColor;
    } else if (!task.isUrgent && task.isImportant) {
      title = 'Schedule';
      description = 'Important, Not Urgent';
      color = AppTheme.highColor;
    } else if (task.isUrgent && !task.isImportant) {
      title = 'Delegate';
      description = 'Urgent, Not Important';
      color = AppTheme.mediumColor;
    } else {
      title = 'Eliminate';
      description = 'Not Urgent, Not Important';
      color = AppTheme.lowColor;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Row(
        children: [
          Icon(Icons.star, color: color, size: 32),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'completed':
        return AppTheme.successColor;
      case 'in_progress':
        return AppTheme.warningColor;
      default:
        return AppTheme.mediumColor;
    }
  }

  Color _getDeadlineColor(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    
    if (difference < 0) return AppTheme.errorColor;
    if (difference == 0) return AppTheme.warningColor;
    if (difference <= 2) return Colors.orange;
    return Colors.green;
  }

  Future<void> _completeTask(
    BuildContext context,
    TaskProvider taskProvider,
  ) async {
    final success = await taskProvider.updateTask(
      task.id,
      {'status': 'completed'},
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task completed! 🎉'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TaskProvider taskProvider,
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
      final success = await taskProvider.deleteTask(task.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _duplicateTask(
    BuildContext context,
    TaskProvider taskProvider,
  ) async {
    final taskData = {
      'title': '${task.title} (Copy)',
      'description': task.description,
      'priority': task.priority,
      'category': task.category,
      'deadline': task.deadline?.toIso8601String(),
      'tags': task.tags,
    };

    final success = await taskProvider.createTask(taskData);

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task duplicated')),
      );
    }
  }
}