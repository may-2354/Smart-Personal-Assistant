import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme_config.dart';
import '../../widgets/achievement_card.dart';
import '../../widgets/streak_counter_widget.dart';
import '../../widgets/level_progress_card.dart';
import '../../widgets/leaderboard_widget.dart';
import '../../services/storage_service.dart';

class GamificationScreen extends StatefulWidget {
  const GamificationScreen({super.key});

  @override
  State<GamificationScreen> createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final provider = Provider.of<GamificationProvider>(context, listen: false);
    
    final token = await StorageService().getToken();
    if (token != null) {
      provider.setToken(token);
      await provider.refresh();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Achievements'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final provider = Provider.of<GamificationProvider>(
                context,
                listen: false,
              );
              provider.refresh();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events), text: 'Progress'),
            Tab(icon: Icon(Icons.workspace_premium), text: 'Achievements'),
            Tab(icon: Icon(Icons.leaderboard), text: 'Leaderboard'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _ProgressTab(),
          _AchievementsTab(),
          _LeaderboardTab(),
        ],
      ),
    );
  }
}

class _ProgressTab extends StatelessWidget {
  const _ProgressTab();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GamificationProvider>(context);

    if (provider.isLoading && provider.userLevel == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Level Progress
            if (provider.userLevel != null)
              LevelProgressCard(
                userLevel: provider.userLevel!,
                totalPoints: provider.totalPoints,
              ),
            const SizedBox(height: 16),

            // Streak Counter
            StreakCounter(
              currentStreak: provider.currentStreak,
              bestStreak: provider.bestStreak,
            ),
            const SizedBox(height: 24),

            // Recent Achievements
            if (provider.recentAchievements.isNotEmpty) ...[
              Text(
                'Recent Achievements',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              ...provider.recentAchievements.map((achievement) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AchievementCard(achievement: achievement),
                );
              }),
            ],

            const SizedBox(height: 24),

            // Stats Overview
            Text(
              'Achievement Stats',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildStatsGrid(provider),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(GamificationProvider provider) {
    final stats = [
      {
        'label': 'Common',
        'count': provider.achievementsByRarity['common'] ?? 0,
        'icon': Icons.circle,
        'color': Colors.grey,
      },
      {
        'label': 'Rare',
        'count': provider.achievementsByRarity['rare'] ?? 0,
        'icon': Icons.star_half,
        'color': Colors.blue,
      },
      {
        'label': 'Epic',
        'count': provider.achievementsByRarity['epic'] ?? 0,
        'icon': Icons.star,
        'color': Colors.purple,
      },
      {
        'label': 'Legendary',
        'count': provider.achievementsByRarity['legendary'] ?? 0,
        'icon': Icons.diamond,
        'color': const Color(0xFFFFD700),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  stat['icon'] as IconData,
                  size: 32,
                  color: stat['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  (stat['count'] as int).toString(),
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat['label'] as String,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _AchievementsTab extends StatelessWidget {
  const _AchievementsTab();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GamificationProvider>(context);

    if (provider.isLoading && provider.achievements.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: () => provider.refresh(),
      child: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Earned'),
                Tab(text: 'Locked'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildAchievementGrid(provider.earnedAchievements, true),
                  _buildAchievementGrid(provider.unearnedAchievements, false),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementGrid(List achievements, bool earned) {
    if (achievements.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              earned ? Icons.emoji_events : Icons.lock_outline,
              size: 64,
              color: AppTheme.textSecondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              earned
                  ? 'No achievements earned yet'
                  : 'All achievements unlocked!',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              earned
                  ? 'Complete tasks to earn achievements'
                  : 'Congratulations! 🎉',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: achievements.length,
      itemBuilder: (context, index) {
        return AchievementCard(achievement: achievements[index]);
      },
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<GamificationProvider>(context);
    final authProvider = Provider.of<AuthProvider>(context);

    return RefreshIndicator(
      onRefresh: () => provider.loadLeaderboard(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            LeaderboardWidget(
              leaderboard: provider.leaderboard,
              currentUserId: authProvider.user?.id.toString(),
            ),
          ],
        ),
      ),
    );
  }
}