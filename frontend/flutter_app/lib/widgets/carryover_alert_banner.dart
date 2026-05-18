import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/carryover_provider.dart';
import '../screens/carryover/carryover_dashboard_screen.dart';
import '../config/theme_config.dart';

class CarryoverAlertBanner extends StatelessWidget {
  const CarryoverAlertBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CarryoverProvider>(context);

    // Don't show if no overdue tasks
    if (!provider.hasOverdueTasks) {
      return const SizedBox.shrink();
    }

    final stats = provider.stats;
    final severity = stats?.severityLevel ?? 'medium';
    final color = stats?.severityColor ?? Colors.orange;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const CarryoverDashboardScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Alert icon with animation
                    _buildAlertIcon(severity, color),
                    const SizedBox(width: 12),

                    // Title
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getAlertTitle(severity),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${provider.overdueCount} overdue task${provider.overdueCount > 1 ? 's' : ''} need attention',
                            style: TextStyle(
                              fontSize: 13,
                              color: color.withOpacity(0.8),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Severity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        severity.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Quick stats
                Row(
                  children: [
                    _buildStatChip(
                      Icons.priority_high,
                      '${stats?.highPriorityOverdue ?? 0} Critical',
                      color,
                    ),
                    const SizedBox(width: 8),
                    _buildStatChip(
                      Icons.trending_up,
                      'Avg ${stats?.averageCarryoverCount.toStringAsFixed(1) ?? '0'} carryovers',
                      color,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showBulkRescheduleDialog(context, provider),
                        icon: Icon(Icons.schedule, size: 18, color: color),
                        label: const Text('Reschedule All'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: color,
                          side: BorderSide(color: color),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CarryoverDashboardScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.analytics, size: 18),
                        label: const Text('View Details'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: color,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlertIcon(String severity, Color color) {
    IconData icon;
    switch (severity) {
      case 'critical':
        icon = Icons.error;
        break;
      case 'high':
        icon = Icons.warning;
        break;
      default:
        icon = Icons.info;
    }

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 1000),
      tween: Tween(begin: 0.8, end: 1.0),
      curve: Curves.easeInOut,
      builder: (context, scale, child) {
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        );
      },
      onEnd: () {
        // Loop animation
      },
    );
  }

  Widget _buildStatChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getAlertTitle(String severity) {
    switch (severity) {
      case 'critical':
        return '🚨 CRITICAL: Immediate Action Required';
      case 'high':
        return '⚠️ HIGH ALERT: Multiple Overdue Tasks';
      case 'medium':
        return '⚡ ATTENTION: Tasks Need Rescheduling';
      case 'low':
        return '📌 REMINDER: Some Tasks Overdue';
      default:
        return '📋 Overdue Tasks';
    }
  }

  void _showBulkRescheduleDialog(BuildContext context, CarryoverProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.schedule, color: Colors.blue),
            SizedBox(width: 12),
            Text('Reschedule All Overdue Tasks?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will automatically reschedule all ${provider.overdueCount} overdue tasks using AI.',
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_fix_high, size: 20, color: Colors.blue),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'AI will consider:\n• Task priorities\n• Your schedule\n• Deadline urgency',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              _performBulkReschedule(context, provider);
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Reschedule All'),
          ),
        ],
      ),
    );
  }

  Future<void> _performBulkReschedule(
    BuildContext context,
    CarryoverProvider provider,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Rescheduling tasks...'),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      final result = await provider.bulkReschedule();
      
      // Close loading
      if (context.mounted) Navigator.pop(context);

      // Show success
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '✅ Rescheduled ${result.rescheduledCount} tasks successfully!',
            ),
            backgroundColor: AppTheme.successColor,
            action: SnackBarAction(
              label: 'VIEW',
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CarryoverDashboardScreen(),
                  ),
                );
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Close loading
      if (context.mounted) Navigator.pop(context);

      // Show error
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }
}