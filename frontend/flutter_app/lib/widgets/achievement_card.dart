import 'package:flutter/material.dart';
import '../models/gamification_models.dart';
import '../config/theme_config.dart';

class AchievementCard extends StatefulWidget {
  final Achievement achievement;
  final VoidCallback? onTap;

  const AchievementCard({
    super.key,
    required this.achievement,
    this.onTap,
  });

  @override
  State<AchievementCard> createState() => _AchievementCardState();
}

class _AchievementCardState extends State<AchievementCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _rotationAnimation = Tween<double>(begin: -0.1, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.achievement.isEarned) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.achievement.isEarned ? _scaleAnimation.value : 1.0,
          child: Transform.rotate(
            angle: widget.achievement.isEarned ? _rotationAnimation.value : 0.0,
            child: child,
          ),
        );
      },
      child: Card(
        elevation: widget.achievement.isEarned ? 4 : 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: widget.achievement.rarity.color.withOpacity(0.5),
            width: 2,
          ),
        ),
        child: InkWell(
          onTap: widget.onTap ?? () => _showDetailsDialog(context),
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: widget.achievement.isEarned
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.achievement.rarity.color.withOpacity(0.2),
                        widget.achievement.rarity.color.withOpacity(0.05),
                      ],
                    )
                  : null,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Badge icon with glow effect
                Stack(
                  alignment: Alignment.center,
                  children: [
                    if (widget.achievement.isEarned)
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.achievement.rarity.color.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 5,
                            ),
                          ],
                        ),
                      ),
                    _buildBadge(),
                  ],
                ),
                const SizedBox(height: 12),

                // Achievement name
                Text(
                  widget.achievement.name,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: widget.achievement.isEarned
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),

                // Rarity badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.achievement.rarity.color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        widget.achievement.rarity.icon,
                        size: 12,
                        color: widget.achievement.rarity.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        widget.achievement.rarity.name,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: widget.achievement.rarity.color,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),

                // Points
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stars,
                      size: 16,
                      color: widget.achievement.isEarned
                          ? AppTheme.warningColor
                          : AppTheme.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${widget.achievement.points} pts',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: widget.achievement.isEarned
                            ? AppTheme.warningColor
                            : AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),

                // Progress bar (for unearned achievements)
                if (!widget.achievement.isEarned && widget.achievement.target > 1) ...[
                  const SizedBox(height: 8),
                  _buildProgressBar(),
                ],

                // Earned date
                if (widget.achievement.isEarned && widget.achievement.earnedAt != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Earned ${_formatDate(widget.achievement.earnedAt!)}',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.achievement.isEarned
            ? widget.achievement.rarity.color.withOpacity(0.3)
            : Colors.grey.shade300,
        border: Border.all(
          color: widget.achievement.isEarned
              ? widget.achievement.rarity.color
              : Colors.grey.shade400,
          width: 3,
        ),
      ),
      child: Center(
        child: Text(
          widget.achievement.badgeIcon,
          style: TextStyle(
            fontSize: 32,
            color: widget.achievement.isEarned ? null : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${widget.achievement.progress.toInt()}/${widget.achievement.target}',
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              '${widget.achievement.progressPercentage.toInt()}%',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: widget.achievement.progressPercentage / 100,
            minHeight: 6,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              widget.achievement.rarity.color,
            ),
          ),
        ),
      ],
    );
  }

  void _showDetailsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                widget.achievement.rarity.color.withOpacity(0.2),
                widget.achievement.rarity.color.withOpacity(0.05),
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Large badge
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.achievement.rarity.color.withOpacity(0.3),
                  border: Border.all(
                    color: widget.achievement.rarity.color,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: widget.achievement.rarity.color.withOpacity(0.5),
                      blurRadius: 30,
                      spreadRadius: 10,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    widget.achievement.badgeIcon,
                    style: const TextStyle(fontSize: 48),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Name
              Text(
                widget.achievement.name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Rarity
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.achievement.rarity.color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      widget.achievement.rarity.icon,
                      size: 16,
                      color: widget.achievement.rarity.color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.achievement.rarity.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: widget.achievement.rarity.color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                widget.achievement.description,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Points
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stars,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${widget.achievement.points} Points',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.warningColor,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Close button
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'today';
    } else if (difference.inDays == 1) {
      return 'yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}