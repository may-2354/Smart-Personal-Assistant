import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class StreakDisplay extends StatelessWidget {
  final int currentStreak;
  final int bestStreak;

  const StreakDisplay({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
  });

  @override
  Widget build(BuildContext context) {
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
              AppTheme.warningColor.withOpacity(0.1),
              AppTheme.warningColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Title
            Row(
              children: [
                Icon(
                  Icons.local_fire_department,
                  color: AppTheme.warningColor,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Streak',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Current streak
            Row(
              children: [
                Expanded(
                  child: _buildStreakItem(
                    context,
                    'Current Streak',
                    currentStreak,
                    Icons.whatshot,
                    AppTheme.warningColor,
                    isActive: true,
                  ),
                ),
                Container(
                  width: 1,
                  height: 60,
                  color: Colors.grey.shade300,
                ),
                Expanded(
                  child: _buildStreakItem(
                    context,
                    'Best Streak',
                    bestStreak,
                    Icons.emoji_events,
                    AppTheme.accentColor,
                  ),
                ),
              ],
            ),

            if (currentStreak > 0) ...[
              const SizedBox(height: 20),
              _buildStreakMotivation(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem(
    BuildContext context,
    String label,
    int value,
    IconData icon,
    Color color, {
    bool isActive = false,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: isActive ? 36 : 32,
          color: color,
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: isActive ? 32 : 28,
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
    );
  }

  Widget _buildStreakMotivation(BuildContext context) {
    String message;
    IconData icon;
    Color color;

    if (currentStreak >= 30) {
      message = "🎉 Amazing! You're on fire!";
      icon = Icons.stars;
      color = AppTheme.accentColor;
    } else if (currentStreak >= 14) {
      message = "🔥 Keep it up! You're doing great!";
      icon = Icons.local_fire_department;
      color = AppTheme.warningColor;
    } else if (currentStreak >= 7) {
      message = "💪 Great job! One week down!";
      icon = Icons.trending_up;
      color = AppTheme.successColor;
    } else if (currentStreak >= 3) {
      message = "👍 Nice! Building momentum!";
      icon = Icons.thumb_up;
      color = AppTheme.primaryColor;
    } else {
      message = "🌟 Good start! Keep going!";
      icon = Icons.star;
      color = AppTheme.mediumColor;
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}