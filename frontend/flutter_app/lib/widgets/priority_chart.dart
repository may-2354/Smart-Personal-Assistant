import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../config/theme_config.dart';

class PriorityDistributionChart extends StatelessWidget {
  final Map<String, int> distribution;

  const PriorityDistributionChart({
    super.key,
    required this.distribution,
  });

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty || distribution.values.every((v) => v == 0)) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tasks by Priority',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                // Pie chart
                Expanded(
                  flex: 2,
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: PieChart(
                      PieChartData(
                        sections: _buildSections(),
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        startDegreeOffset: -90,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Legend
                Expanded(
                  flex: 3,
                  child: _buildLegend(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildSections() {
    final total = distribution.values.fold(0, (sum, val) => sum + val);
    if (total == 0) return [];

    final priorities = ['critical', 'high', 'medium', 'low'];
    final colors = [
      AppTheme.criticalColor,
      AppTheme.highColor,
      AppTheme.mediumColor,
      AppTheme.lowColor,
    ];

    return priorities.asMap().entries.map((entry) {
      final index = entry.key;
      final priority = entry.value;
      final count = distribution[priority] ?? 0;
      final percentage = (count / total * 100).toStringAsFixed(1);

      return PieChartSectionData(
        color: colors[index],
        value: count.toDouble(),
        title: count > 0 ? '$percentage%' : '',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).where((section) => section.value > 0).toList();
  }

  Widget _buildLegend() {
    final priorities = [
      {'name': 'Critical', 'key': 'critical', 'color': AppTheme.criticalColor},
      {'name': 'High', 'key': 'high', 'color': AppTheme.highColor},
      {'name': 'Medium', 'key': 'medium', 'color': AppTheme.mediumColor},
      {'name': 'Low', 'key': 'low', 'color': AppTheme.lowColor},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: priorities.map((priority) {
        final count = distribution[priority['key']] ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: priority['color'] as Color,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  priority['name'] as String,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: priority['color'] as Color,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 200,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.pie_chart_outline,
                size: 48,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No priority data',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}