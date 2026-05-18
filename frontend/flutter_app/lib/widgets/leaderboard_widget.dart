import 'package:flutter/material.dart';
import '../models/gamification_models.dart';
import '../config/theme_config.dart';

class LeaderboardWidget extends StatelessWidget {
  final List<LeaderboardEntry> leaderboard;
  final String? currentUserId;

  const LeaderboardWidget({
    super.key,
    required this.leaderboard,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (leaderboard.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  Icons.leaderboard,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Leaderboard',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: leaderboard.length,
            separatorBuilder: (context, index) => const Divider(height: 1, indent: 76),
            itemBuilder: (context, index) {
              final entry = leaderboard[index];
              final isCurrentUser = entry.userId == currentUserId;
              return _buildLeaderboardItem(entry, isCurrentUser);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLeaderboardItem(LeaderboardEntry entry, bool isCurrentUser) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppTheme.primaryColor.withOpacity(0.1)
            : Colors.transparent,
      ),
      child: Row(
        children: [
          // Rank badge
          _buildRankBadge(entry.rank),
          const SizedBox(width: 16),

          // Avatar
          CircleAvatar(
            radius: 24,
            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
            child: Text(
              entry.username[0].toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Username and level
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        entry.username,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isCurrentUser ? FontWeight.bold : FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Level ${entry.level}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Points
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                entry.points.toString(),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'points',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color color;
    IconData? icon;

    if (rank == 1) {
      color = const Color(0xFFFFD700); // Gold
      icon = Icons.emoji_events;
    } else if (rank == 2) {
      color = const Color(0xFFC0C0C0); // Silver
      icon = Icons.emoji_events;
    } else if (rank == 3) {
      color = const Color(0xFFCD7F32); // Bronze
      icon = Icons.emoji_events;
    } else {
      color = Colors.grey.shade400;
    }

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 2),
      ),
      child: Center(
        child: rank <= 3 && icon != null
            ? Icon(icon, color: color, size: 20)
            : Text(
                rank.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.leaderboard,
                size: 64,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No leaderboard data yet',
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