import 'package:flutter/material.dart';
import '../models/gamification_models.dart';
import '../config/theme_config.dart';

class LevelProgressCard extends StatelessWidget {
  final UserLevel userLevel;
  final int totalPoints;

  const LevelProgressCard({
    super.key,
    required this.userLevel,
    required this.totalPoints,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.1),
              AppTheme.accentColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Level badge and title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userLevel.title,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.stars,
                            size: 16,
                            color: AppTheme.warningColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalPoints Total Points',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildLevelBadge(),
              ],
            ),
            const SizedBox(height: 20),

            // Progress bar
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Level ${userLevel.level}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Level ${userLevel.level + 1}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Container(
                        height: 20,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 800),
                            curve: Curves.easeOut,
                            height: 20,
                            width: constraints.maxWidth * (userLevel.progressPercentage / 100),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppTheme.primaryColor,
                                  AppTheme.accentColor,
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${userLevel.currentXP} XP',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                    Text(
                      '${userLevel.xpToNextLevel} XP to go',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLevelBadge() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getLevelColor(),
            _getLevelColor().withOpacity(0.6),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: _getLevelColor().withOpacity(0.4),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Level number
          Text(
            userLevel.level.toString(),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          // Border ring
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getLevelColor() {
    if (userLevel.level >= 50) return Colors.purple;
    if (userLevel.level >= 40) return const Color(0xFFFFD700); // Gold
    if (userLevel.level >= 30) return Colors.orange;
    if (userLevel.level >= 20) return AppTheme.accentColor;
    if (userLevel.level >= 10) return AppTheme.primaryColor;
    return AppTheme.successColor;
  }
}