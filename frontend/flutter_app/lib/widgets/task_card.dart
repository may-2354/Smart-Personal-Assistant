import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../config/theme_config.dart';

class TaskCard extends StatelessWidget {
  final Task task;
  final VoidCallback? onTap;
  final VoidCallback? onComplete;
  final VoidCallback? onDelete;

  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.onComplete,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = task.status == 'completed';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: task.priorityColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Priority Indicator
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: task.priorityColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Title
                  Expanded(
                    child: Text(
                      task.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            decoration: isCompleted 
                                ? TextDecoration.lineThrough 
                                : null,
                            color: isCompleted 
                                ? AppTheme.textSecondary 
                                : AppTheme.textPrimary,
                          ),
                    ),
                  ),
                  
                  // Complete Button
                  if (!isCompleted && onComplete != null)
                    IconButton(
                      icon: const Icon(Icons.check_circle_outline),
                      color: AppTheme.successColor,
                      onPressed: onComplete,
                      iconSize: 28,
                    ),
                  
                  // Delete Button
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      color: AppTheme.errorColor,
                      onPressed: onDelete,
                      iconSize: 24,
                    ),
                ],
              ),
              
              // Description
              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              
              const SizedBox(height: 12),
              
              // Tags & Metadata Row
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  // Category
                  if (task.category != null)
                    _buildChip(
                      context,
                      icon: Icons.folder_outlined,
                      label: task.category!,
                      color: Colors.blue,
                    ),
                  
                  // Priority
                  _buildChip(
                    context,
                    icon: Icons.flag_outlined,
                    label: task.priority,
                    color: task.priorityColor,
                  ),
                  
                  // Deadline
                  if (task.deadline != null)
                    _buildChip(
                      context,
                      icon: Icons.calendar_today_outlined,
                      label: _formatDeadline(task.deadline!),
                      color: _getDeadlineColor(task.deadline!),
                    ),
                  
                  // Carryover indicator
                  if (task.carryoverCount > 0)
                    _buildChip(
                      context,
                      icon: Icons.repeat,
                      label: '${task.carryoverCount}x',
                      color: AppTheme.warningColor,
                    ),
                  
                  // Eisenhower Quadrant
                  if (task.isUrgent || task.isImportant)
                    _buildChip(
                      context,
                      icon: Icons.star_outline,
                      label: task.eisenhowerQuadrant,
                      color: AppTheme.accentColor,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDeadline(DateTime deadline) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(deadline.year, deadline.month, deadline.day);
    
    final difference = deadlineDate.difference(today).inDays;
    
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';
    if (difference < 0) return '${-difference}d overdue';
    if (difference <= 7) return '$difference days';
    
    return DateFormat('MMM dd').format(deadline);
  }

  Color _getDeadlineColor(DateTime deadline) {
    final now = DateTime.now();
    final difference = deadline.difference(now).inDays;
    
    if (difference < 0) return AppTheme.errorColor;
    if (difference == 0) return AppTheme.warningColor;
    if (difference <= 2) return Colors.orange;
    return Colors.green;
  }
}