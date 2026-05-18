import 'package:flutter/material.dart';
import '../config/theme_config.dart';

class StreakCounter extends StatefulWidget {
  final int currentStreak;
  final int bestStreak;
  final bool showAnimation;

  const StreakCounter({
    super.key,
    required this.currentStreak,
    required this.bestStreak,
    this.showAnimation = true,
  });

  @override
  State<StreakCounter> createState() => _StreakCounterState();
}

class _StreakCounterState extends State<StreakCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _flameAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _flameAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.warningColor.withOpacity(0.2),
              Colors.orange.withOpacity(0.1),
            ],
          ),
        ),
        child: Column(
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '🔥',
                  style: TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  'Daily Streak',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Main streak display
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStreakDisplay(
                  'Current',
                  widget.currentStreak,
                  true,
                ),
                Container(
                  width: 2,
                  height: 80,
                  color: Colors.grey.shade300,
                ),
                _buildStreakDisplay(
                  'Best',
                  widget.bestStreak,
                  false,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Motivation message
            _buildMotivationMessage(),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakDisplay(String label, int count, bool isCurrent) {
    return Column(
      children: [
        // Animated fire emoji (only for current streak)
        if (isCurrent && widget.showAnimation && count > 0)
          AnimatedBuilder(
            animation: _flameAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _flameAnimation.value,
                child: Text(
                  _getFireEmoji(count),
                  style: const TextStyle(fontSize: 48),
                ),
              );
            },
          )
        else
          Text(
            isCurrent ? _getFireEmoji(count) : '🏆',
            style: TextStyle(
              fontSize: 48,
              color: count == 0 ? Colors.grey.shade400 : null,
            ),
          ),
        const SizedBox(height: 8),

        // Count with animation
        AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: isCurrent && widget.showAnimation ? _scaleAnimation.value : 1.0,
              child: Text(
                count.toString(),
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: isCurrent
                      ? AppTheme.warningColor
                      : AppTheme.accentColor,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),

        // Label
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildMotivationMessage() {
    String message;
    Color color;
    IconData icon;

    if (widget.currentStreak == 0) {
      message = "Start your streak today! 💪";
      color = AppTheme.textSecondary;
      icon = Icons.info_outline;
    } else if (widget.currentStreak < 3) {
      message = "Great start! Keep it going! 🌱";
      color = AppTheme.successColor;
      icon = Icons.check_circle_outline;
    } else if (widget.currentStreak < 7) {
      message = "You're building momentum! 🚀";
      color = AppTheme.primaryColor;
      icon = Icons.trending_up;
    } else if (widget.currentStreak < 14) {
      message = "One week strong! Incredible! 🎉";
      color = AppTheme.accentColor;
      icon = Icons.celebration;
    } else if (widget.currentStreak < 30) {
      message = "You're unstoppable! 🔥";
      color = AppTheme.warningColor;
      icon = Icons.whatshot;
    } else if (widget.currentStreak < 100) {
      message = "Legendary dedication! 👑";
      color = const Color(0xFFFFD700);
      icon = Icons.stars;
    } else {
      message = "MYTHICAL STATUS ACHIEVED! 💎";
      color = Colors.purple;
      icon = Icons.diamond;
    }

    // Check if new record
    if (widget.currentStreak > widget.bestStreak && widget.currentStreak > 0) {
      message = "🎊 NEW RECORD! $message";
      color = const Color(0xFFFFD700);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getFireEmoji(int streak) {
    if (streak == 0) return '🌑'; // Moon (no fire)
    if (streak < 3) return '🔥'; // Single fire
    if (streak < 7) return '🔥🔥'; // Double fire
    if (streak < 14) return '🔥🔥🔥'; // Triple fire
    if (streak < 30) return '🔥🔥🔥🔥'; // Quad fire
    return '🔥🔥🔥🔥🔥'; // Max fire!
  }
}