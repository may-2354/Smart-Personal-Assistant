import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../providers/carryover_provider.dart';
import '../../config/theme_config.dart';
import '../../services/storage_service.dart';

class CarryoverDashboardScreen extends StatefulWidget {
  const CarryoverDashboardScreen({super.key});

  @override
  State<CarryoverDashboardScreen> createState() => _CarryoverDashboardScreenState();
}

class _CarryoverDashboardScreenState extends State<CarryoverDashboardScreen> {
  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    final provider = Provider.of<CarryoverProvider>(context, listen: false);
    final token = await StorageService().getToken();
    if (token != null) {
      provider.setToken(token);
      await provider.refreshAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CarryoverProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Carryover Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => provider.refreshAll(),
          ),
        ],
      ),
      body: provider.isLoading && provider.stats == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () => provider.refreshAll(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Overview cards
                    _buildOverviewCards(provider),
                    const SizedBox(height: 24),

                    // Charts
                    _buildChartsSection(provider),
                    const SizedBox(height: 24),

                    // Delay patterns
                    _buildDelayPatternsSection(provider),
                    const SizedBox(height: 24),

                    // Smart suggestions
                    _buildSmartSuggestionsSection(provider),
                    const SizedBox(height: 24),

                    // Overdue tasks list
                    _buildOverdueTasksList(provider),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildOverviewCards(CarryoverProvider provider) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Carryovers',
                stats.totalCarryovers.toString(),
                Icons.repeat,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Overdue Now',
                stats.activeOverdueTasks.toString(),
                Icons.warning,
                Colors.orange,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'High Priority',
                stats.highPriorityOverdue.toString(),
                Icons.priority_high,
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Avg Carryovers',
                stats.averageCarryoverCount.toStringAsFixed(1),
                Icons.analytics,
                Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(CarryoverProvider provider) {
    final stats = provider.stats;
    if (stats == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Breakdown Analysis',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),

        // Priority chart
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Carryovers by Priority',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 200,
                  child: _buildPriorityChart(stats.carryoversByPriority),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Category chart
        if (stats.carryoversByCategory.isNotEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Carryovers by Category',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...stats.carryoversByCategory.entries.map((entry) {
                    final total = stats.carryoversByCategory.values.fold<int>(
                      0,
                      (sum, val) => sum + val,
                    );
                    final percentage = (entry.value / total * 100).toInt();
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                entry.key,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '${entry.value} ($percentage%)',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: percentage / 100,
                              minHeight: 8,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.primaryColor,
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
      ],
    );
  }

  Widget _buildPriorityChart(Map<String, int> data) {
    if (data.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final colors = {
      'critical': Colors.red,
      'high': Colors.orange,
      'medium': Colors.blue,
      'low': Colors.green,
    };

    return BarChart(
      BarChartData(
        barGroups: data.entries.map((entry) {
          final index = ['critical', 'high', 'medium', 'low'].indexOf(entry.key);
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: entry.value.toDouble(),
                color: colors[entry.key] ?? Colors.grey,
                width: 40,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
              ),
            ],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 12),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final labels = ['Critical', 'High', 'Medium', 'Low'];
                if (value.toInt() >= 0 && value.toInt() < labels.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labels[value.toInt()],
                      style: const TextStyle(fontSize: 11),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(show: false),
      ),
    );
  }

  Widget _buildDelayPatternsSection(CarryoverProvider provider) {
    if (provider.delayPatterns.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delay Patterns Detected',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...provider.delayPatterns.map((pattern) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.trending_down,
                        color: Colors.orange.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          pattern.description,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildPatternChip(
                        'Frequency: ${pattern.frequency}',
                        Colors.blue,
                      ),
                      const SizedBox(width: 8),
                      _buildPatternChip(
                        'Impact: ${pattern.impactScore.toInt()}%',
                        Colors.orange,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPatternChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildSmartSuggestionsSection(CarryoverProvider provider) {
    if (provider.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Suggestions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...provider.suggestions.map((suggestion) {
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: suggestion.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(suggestion.icon, color: suggestion.color, size: 22),
              ),
              title: Text(
                suggestion.title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                suggestion.description,
                style: const TextStyle(fontSize: 13),
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Action Steps:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      ...suggestion.actionSteps.asMap().entries.map((entry) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.only(top: 2),
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: suggestion.color.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${entry.key + 1}',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: suggestion.color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  entry.value,
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
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
                              Icons.check_circle,
                              size: 18,
                              color: AppTheme.successColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Expected Impact: ${suggestion.expectedImpact}',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.successColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOverdueTasksList(CarryoverProvider provider) {
    if (provider.overdueTasks.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Column(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 64,
                  color: AppTheme.successColor,
                ),
                const SizedBox(height: 16),
                Text(
                  'No Overdue Tasks!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.successColor,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Great job staying on track! 🎉',
                  style: TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overdue Tasks (${provider.overdueTasks.length})',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...provider.overdueTasks.take(10).map((task) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: task.priorityColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              title: Text(
                task.title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Overdue • ${task.carryoverCount} carryovers',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.schedule),
                onPressed: () => _rescheduleSingleTask(task.id, provider),
              ),
            ),
          );
        }),
        if (provider.overdueTasks.length > 10) ...[
          const SizedBox(height: 8),
          Center(
            child: Text(
              '+${provider.overdueTasks.length - 10} more tasks',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _rescheduleSingleTask(int taskId, CarryoverProvider provider) async {
    try {
      await provider.rescheduleSingleTask(taskId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Task rescheduled successfully!'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
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