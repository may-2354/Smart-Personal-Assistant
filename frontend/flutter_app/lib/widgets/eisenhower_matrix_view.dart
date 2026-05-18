import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../config/theme_config.dart';

class EisenhowerMatrixView extends StatelessWidget {
  final Map<String, List<Task>> matrix;
  final Function(Task) onTaskTap;

  const EisenhowerMatrixView({
    super.key,
    required this.matrix,
    required this.onTaskTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildQuadrant(
                context,
                title: 'Do First',
                subtitle: 'Urgent & Important',
                color: AppTheme.criticalColor,
                tasks: matrix['urgent_important'] ?? [],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuadrant(
                context,
                title: 'Schedule',
                subtitle: 'Important, Not Urgent',
                color: AppTheme.highColor,
                tasks: matrix['not_urgent_important'] ?? [],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildQuadrant(
                context,
                title: 'Delegate',
                subtitle: 'Urgent, Not Important',
                color: AppTheme.mediumColor,
                tasks: matrix['urgent_not_important'] ?? [],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildQuadrant(
                context,
                title: 'Eliminate',
                subtitle: 'Not Urgent, Not Important',
                color: AppTheme.lowColor,
                tasks: matrix['not_urgent_not_important'] ?? [],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuadrant(
    BuildContext context, {
    required String title,
    required String subtitle,
    required Color color,
    required List<Task> tasks,
  }) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final task = tasks[index];
                      return InkWell(
                        onTap: () => onTaskTap(task),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            task.title,
                            style: const TextStyle(fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}