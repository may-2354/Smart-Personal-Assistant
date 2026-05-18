class AnalyticsData {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int overdueTasks;
  final double completionRate;
  final int currentStreak;
  final int bestStreak;
  final Map<String, int> tasksByPriority;
  final Map<String, int> tasksByCategory;
  final List<DailyProductivity> productivityData;
  final BurnoutIndicator? burnoutWarning;

  AnalyticsData({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.overdueTasks,
    required this.completionRate,
    required this.currentStreak,
    required this.bestStreak,
    required this.tasksByPriority,
    required this.tasksByCategory,
    required this.productivityData,
    this.burnoutWarning,
  });

  factory AnalyticsData.fromJson(Map<String, dynamic> productivity, Map<String, dynamic> gamification) {
    // Parse productivity data
    final totalTasks = productivity['total_tasks'] ?? 0;
    final completed = productivity['completed'] ?? 0;
    final pending = productivity['pending'] ?? 0;
    final overdue = productivity['overdue_tasks'] ?? 0;
    final completionRate = (productivity['completion_rate'] ?? 0.0).toDouble();
    
    // Parse gamification data for streaks
    final streaks = gamification['streaks'] ?? {};
    final dailyStreak = streaks['daily_completion'] ?? {};
    final currentStreak = dailyStreak['current'] ?? 0;
    final bestStreak = dailyStreak['best'] ?? 0;
    
    // Parse priority breakdown - FIX TYPE CASTING
    final priorityBreakdown = productivity['priority_breakdown'] ?? {};
    final tasksByPriority = <String, int>{
      'critical': (priorityBreakdown['critical'] ?? 0).toInt(),
      'high': (priorityBreakdown['high'] ?? 0).toInt(),
      'medium': (priorityBreakdown['medium'] ?? 0).toInt(),
      'low': (priorityBreakdown['low'] ?? 0).toInt(),
    };
    
    // Parse category data
    final topCategories = productivity['top_categories'] ?? {};
    final tasksByCategory = <String, int>{};
    topCategories.forEach((key, value) {
      tasksByCategory[key.toString()] = (value ?? 0).toInt();
    });
    
    // Parse daily trends
    final dailyTrend = productivity['daily_completion_trend'] ?? [];
    final productivityData = (dailyTrend as List)
        .map((item) => DailyProductivity.fromJson(item))
        .toList();
    
    // Smart burnout detection - multiple factors
    BurnoutIndicator? burnoutWarning;
    final overdueRate = (productivity['overdue_rate'] ?? 0.0).toDouble();
    
    // Calculate burnout score based on multiple factors
    double burnoutScore = 0;
    List<String> indicators = [];
    
    // Factor 1: Low completion rate (0-30 points)
    if (completionRate < 20) {
      burnoutScore += 30;
      indicators.add('⚠️ Very low completion rate: ${completionRate.toStringAsFixed(1)}%');
    } else if (completionRate < 50) {
      burnoutScore += 20;
      indicators.add('⚠️ Low completion rate: ${completionRate.toStringAsFixed(1)}%');
    } else if (completionRate < 70) {
      burnoutScore += 10;
      indicators.add('⚠️ Below average completion: ${completionRate.toStringAsFixed(1)}%');
    }
    
    // Factor 2: High task volume (0-25 points)
    if (totalTasks > 50) {
      burnoutScore += 25;
      indicators.add('⚠️ Very high task volume: $totalTasks tasks');
    } else if (totalTasks > 30) {
      burnoutScore += 15;
      indicators.add('⚠️ High task volume: $totalTasks tasks');
    }
    
    // Factor 3: Overdue tasks (0-25 points)
    if (overdue > 15) {
      burnoutScore += 25;
      indicators.add('⚠️ Many overdue tasks: $overdue tasks');
    } else if (overdue > 10) {
      burnoutScore += 15;
      indicators.add('⚠️ Several overdue tasks: $overdue tasks');
    } else if (overdue > 5) {
      burnoutScore += 10;
      indicators.add('⚠️ Some overdue tasks: $overdue tasks');
    }
    
    // Factor 4: Pending task backlog (0-20 points)
    if (pending > 40) {
      burnoutScore += 20;
      indicators.add('⚠️ Large pending backlog: $pending tasks');
    } else if (pending > 25) {
      burnoutScore += 10;
      indicators.add('⚠️ Pending backlog growing: $pending tasks');
    }
    
    // Determine burnout level and show recommendations if score > 25
    if (burnoutScore >= 25) {
      String level;
      String message;
      
      if (burnoutScore >= 70) {
        level = 'critical';
        message = '🚨 Critical burnout risk detected! Immediate action needed.';
      } else if (burnoutScore >= 50) {
        level = 'high';
        message = '😰 High burnout risk. Take steps to reduce workload.';
      } else if (burnoutScore >= 35) {
        level = 'medium';
        message = '😓 Moderate burnout risk. Consider taking breaks.';
      } else {
        level = 'low';
        message = '😊 Slight warning signs. Monitor your workload.';
      }
      
      // Generate smart recommendations based on detected issues
      List<String> recommendations = [];
      
      if (completionRate < 50) {
        recommendations.add('⚠️ Focus on completing existing tasks before adding new ones');
      }
      
      if (totalTasks > 30) {
        recommendations.add('📊 Monitor your workload closely');
        recommendations.add('🎯 Break large tasks into smaller, manageable subtasks');
      }
      
      if (overdue > 5) {
        recommendations.add('⏰ Prioritize overdue tasks - tackle them first');
        recommendations.add('📅 Consider rescheduling unrealistic deadlines');
      }
      
      if (pending > 25) {
        recommendations.add('🔄 Reduce daily task creation by 30%');
        recommendations.add('✅ Complete at least 3 tasks before creating new ones');
      }
      
      if (burnoutScore >= 70) {
        recommendations.add('🚨 Take a break! Your burnout risk is critical');
        recommendations.add('💡 Delegate or postpone low-priority tasks');
      }
      
      // Fallback recommendation if none were added
      if (recommendations.isEmpty) {
        recommendations.add('📈 Keep monitoring your progress and adjust as needed');
      }
      
      burnoutWarning = BurnoutIndicator(
        level: level,
        score: burnoutScore,
        message: message,
        indicators: indicators.isEmpty 
            ? ['📊 Your workload seems manageable, but stay vigilant!']
            : indicators,
        recommendations: recommendations,
      );
    }
    
    return AnalyticsData(
      totalTasks: totalTasks,
      completedTasks: completed,
      pendingTasks: pending,
      overdueTasks: overdue,
      completionRate: completionRate,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      tasksByPriority: tasksByPriority,
      tasksByCategory: tasksByCategory,
      productivityData: productivityData,
      burnoutWarning: burnoutWarning,
    );
  }

  double get productivityScore {
    if (totalTasks == 0) return 0;
    return (completedTasks / totalTasks) * 100;
  }
}

class DailyProductivity {
  final String date;
  final int completed;
  final int created;

  DailyProductivity({
    required this.date,
    required this.completed,
    required this.created,
  });

  factory DailyProductivity.fromJson(Map<String, dynamic> json) {
    return DailyProductivity(
      date: json['date'] ?? '',
      completed: json['completed'] ?? 0,
      created: json['created'] ?? 0,
    );
  }

  DateTime get dateTime => DateTime.parse(date);
}

class BurnoutIndicator {
  final String level;
  final double score;
  final String message;
  final List<String> indicators; // Warning signs
  final List<String> recommendations; // Action items

  BurnoutIndicator({
    required this.level,
    required this.score,
    required this.message,
    required this.indicators,
    required this.recommendations,
  });

  bool get isWarning => level == 'medium' || level == 'high' || level == 'critical';
  bool get isCritical => level == 'critical';
}