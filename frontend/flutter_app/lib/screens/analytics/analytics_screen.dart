import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/analytics_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme_config.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/productivity_chart.dart';
import '../../widgets/priority_chart.dart';
import '../../widgets/streak_display.dart';
import '../../widgets/burnout_warning.dart';
import '../../services/storage_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final analyticsProvider = Provider.of<AnalyticsProvider>(context, listen: false);
    
    // Set token
    final token = await StorageService().getToken();
    if (token != null) {
      analyticsProvider.setToken(token);
      await analyticsProvider.loadAnalytics();

      print('Analytics loaded: ${analyticsProvider.analytics?.currentStreak}');
      print('Best streak: ${analyticsProvider.analytics?.bestStreak}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsProvider = Provider.of<AnalyticsProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          // Period selector
          PopupMenuButton<int>(
            icon: const Icon(Icons.calendar_today),
            tooltip: 'Time Period',
            onSelected: (value) {
              analyticsProvider.setPeriodDays(value);
            },
            itemBuilder: (context) => [
              _buildPeriodMenuItem(context, analyticsProvider, 7, 'Last 7 days'),
              _buildPeriodMenuItem(context, analyticsProvider, 14, 'Last 14 days'),
              _buildPeriodMenuItem(context, analyticsProvider, 30, 'Last 30 days'),
              _buildPeriodMenuItem(context, analyticsProvider, 90, 'Last 90 days'),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () => analyticsProvider.refresh(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => analyticsProvider.refresh(),
        child: analyticsProvider.isLoading && analyticsProvider.analytics == null
            ? const Center(child: CircularProgressIndicator())
            : analyticsProvider.hasData
                ? _buildDashboard(analyticsProvider)
                : _buildEmptyState(),
      ),
    );
  }

  PopupMenuItem<int> _buildPeriodMenuItem(
    BuildContext context,
    AnalyticsProvider provider,
    int days,
    String label,
  ) {
    return PopupMenuItem(
      value: days,
      child: Row(
        children: [
          Icon(
            Icons.check,
            size: 18,
            color: provider.periodDays == days
                ? AppTheme.primaryColor
                : Colors.transparent,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }

  Widget _buildDashboard(AnalyticsProvider provider) {
    final analytics = provider.analytics!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Burnout Warning (if applicable)
          if (provider.showBurnoutWarning) ...[
            BurnoutWarning(indicator: analytics.burnoutWarning!),
            const SizedBox(height: 16),
          ],

          // Overview Stats
          Text(
            'Overview',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Total Tasks',
                  value: analytics.totalTasks.toString(),
                  icon: Icons.task_alt,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Completed',
                  value: analytics.completedTasks.toString(),
                  subtitle: '${analytics.completionRate.toStringAsFixed(1)}% rate',
                  icon: Icons.check_circle,
                  color: AppTheme.successColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: StatCard(
                  title: 'Pending',
                  value: analytics.pendingTasks.toString(),
                  icon: Icons.pending,
                  color: AppTheme.mediumColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatCard(
                  title: 'Overdue',
                  value: analytics.overdueTasks.toString(),
                  icon: Icons.warning_amber,
                  color: AppTheme.errorColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Streak Display
          StreakDisplay(
            currentStreak: analytics.currentStreak,
            bestStreak: analytics.bestStreak,
          ),
          const SizedBox(height: 24),

          // Productivity Chart
          Text(
            'Trends',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          ProductivityChart(
            data: provider.currentProductivityData,
            periodDays: provider.periodDays,
          ),
          const SizedBox(height: 16),

          // Priority Distribution
          PriorityDistributionChart(
            distribution: analytics.tasksByPriority,
          ),
          const SizedBox(height: 16),

          // Category Distribution (if you want to add it)
          if (analytics.tasksByCategory.isNotEmpty) ...[
            _buildCategoryList(analytics.tasksByCategory),
            const SizedBox(height: 16),
          ],

          // Productivity Score
          _buildProductivityScore(analytics.productivityScore),
        ],
      ),
    );
  }

  Widget _buildCategoryList(Map<String, int> categories) {
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
              'Tasks by Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            ...categories.entries.map((entry) {
              final total = categories.values.fold(0, (sum, val) => sum + val);
              final percentage = (entry.value / total * 100).toStringAsFixed(0);
              
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
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${entry.value} ($percentage%)',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.value / total,
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductivityScore(double score) {
    Color scoreColor;
    String scoreLabel;
    IconData scoreIcon;

    if (score >= 80) {
      scoreColor = AppTheme.successColor;
      scoreLabel = 'Excellent';
      scoreIcon = Icons.emoji_events;
    } else if (score >= 60) {
      scoreColor = AppTheme.primaryColor;
      scoreLabel = 'Good';
      scoreIcon = Icons.thumb_up;
    } else if (score >= 40) {
      scoreColor = AppTheme.warningColor;
      scoreLabel = 'Fair';
      scoreIcon = Icons.trending_up;
    } else {
      scoreColor = AppTheme.errorColor;
      scoreLabel = 'Needs Improvement';
      scoreIcon = Icons.trending_down;
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scoreColor.withOpacity(0.1),
              scoreColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(scoreIcon, color: scoreColor, size: 32),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Productivity Score',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      scoreLabel,
                      style: TextStyle(
                        fontSize: 12,
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '${score.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: scoreColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: score / 100,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.analytics_outlined,
            size: 80,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 24),
          Text(
            'No Analytics Available',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Start creating and completing tasks to see your productivity insights!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}