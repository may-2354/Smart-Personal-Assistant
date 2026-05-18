import 'package:flutter/material.dart';
import '../models/carryover_models.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

class CarryoverProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  CarryoverStats? _stats;
  List<Task> _overdueTasks = [];
  List<DelayPattern> _delayPatterns = [];
  List<SmartSuggestion> _suggestions = [];
  bool _isLoading = false;
  String? _error;

  CarryoverStats? get stats => _stats;
  List<Task> get overdueTasks => _overdueTasks;
  List<DelayPattern> get delayPatterns => _delayPatterns;
  List<SmartSuggestion> get suggestions => _suggestions;
  bool get isLoading => _isLoading;
  String? get error => _error;

  bool get hasOverdueTasks => _overdueTasks.isNotEmpty;
  int get overdueCount => _overdueTasks.length;

  void setToken(String token) {
    _apiService.setToken(token);
  }

  // Load carryover statistics
  Future<void> loadCarryoverStats() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await _apiService.getCarryoverStats();
      _stats = CarryoverStats.fromJson(data);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load overdue tasks
  Future<void> loadOverdueTasks() async {
    try {
      final tasks = await _apiService.getOverdueTasks();
      _overdueTasks = tasks;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Analyze delay patterns
  Future<void> analyzeDelayPatterns() async {
    try {
      // Generate patterns from overdue tasks
      _delayPatterns = _generateDelayPatterns(_overdueTasks);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<DelayPattern> _generateDelayPatterns(List<Task> tasks) {
    final patterns = <DelayPattern>[];

    // Pattern 1: Category-based delays
    final categoryDelays = <String, int>{};
    for (final task in tasks) {
      if (task.category != null) {
        categoryDelays[task.category!] = 
            (categoryDelays[task.category!] ?? 0) + 1;
      }
    }

    if (categoryDelays.isNotEmpty) {
      final topCategory = categoryDelays.entries
          .reduce((a, b) => a.value > b.value ? a : b);
      
      patterns.add(DelayPattern(
        pattern: 'category_delay',
        description: 'Tasks in "${topCategory.key}" category are frequently delayed',
        frequency: topCategory.value,
        impactScore: (topCategory.value / tasks.length * 100),
        affectedCategories: [topCategory.key],
      ));
    }

    // Pattern 2: Priority mismanagement
    final highPriorityDelayed = tasks.where((t) => 
        t.priority == 'high' || t.priority == 'critical'
    ).length;

    if (highPriorityDelayed > 0) {
      patterns.add(DelayPattern(
        pattern: 'priority_mismanagement',
        description: 'High-priority tasks are being delayed',
        frequency: highPriorityDelayed,
        impactScore: (highPriorityDelayed / tasks.length * 100),
        affectedCategories: [],
      ));
    }

    // Pattern 3: Overcommitment
    if (tasks.length > 10) {
      patterns.add(DelayPattern(
        pattern: 'overcommitment',
        description: 'Too many tasks scheduled, leading to consistent delays',
        frequency: tasks.length,
        impactScore: 90,
        affectedCategories: [],
      ));
    }

    return patterns;
  }

  // Generate smart suggestions
  Future<void> generateSuggestions() async {
    try {
      _suggestions = _generateSmartSuggestions(
        _overdueTasks,
        _delayPatterns,
        _stats,
      );
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  List<SmartSuggestion> _generateSmartSuggestions(
    List<Task> overdueTasks,
    List<DelayPattern> patterns,
    CarryoverStats? stats,
  ) {
    final suggestions = <SmartSuggestion>[];

    // Suggestion 1: Reduce task load
    if (overdueTasks.length > 10) {
      suggestions.add(SmartSuggestion(
        id: 'reduce_load',
        title: 'Reduce Your Task Load',
        description: 'You have ${overdueTasks.length} overdue tasks. Consider delegating or postponing low-priority items.',
        type: SuggestionType.timeManagement,
        priority: 1,
        actionSteps: [
          'Review and delete unnecessary tasks',
          'Delegate 2-3 tasks if possible',
          'Move low-priority tasks to next week',
        ],
        expectedImpact: 'Reduce overdue tasks by 30-40%',
      ));
    }

    // Suggestion 2: Focus on high-priority
    final highPriorityCount = overdueTasks.where((t) => 
        t.priority == 'high' || t.priority == 'critical'
    ).length;

    if (highPriorityCount > 0) {
      suggestions.add(SmartSuggestion(
        id: 'high_priority_first',
        title: 'Tackle High-Priority Tasks First',
        description: 'You have $highPriorityCount high-priority overdue tasks. Address these immediately.',
        type: SuggestionType.priority,
        priority: 1,
        actionSteps: [
          'Block 2 hours tomorrow morning',
          'Focus on critical tasks only',
          'Minimize distractions during this time',
        ],
        expectedImpact: 'Complete critical tasks within 24 hours',
      ));
    }

    // Suggestion 3: Break down large tasks
    final largeTasks = overdueTasks.where((t) => 
        (t.estimated_duration ?? 30) > 60
    ).toList();

    if (largeTasks.isNotEmpty) {
      suggestions.add(SmartSuggestion(
        id: 'break_down_tasks',
        title: 'Break Down Large Tasks',
        description: '${largeTasks.length} tasks are likely too large. Breaking them into smaller steps makes them more manageable.',
        type: SuggestionType.taskBreakdown,
        priority: 2,
        actionSteps: [
          'Identify tasks taking over 1 hour',
          'Split each into 3-4 subtasks',
          'Schedule subtasks across multiple days',
        ],
        expectedImpact: 'Increase completion rate by 50%',
      ));
    }

    // Suggestion 4: Time blocking
    if (overdueTasks.length > 5) {
      suggestions.add(SmartSuggestion(
        id: 'time_blocking',
        title: 'Use Time Blocking',
        description: 'Schedule specific time slots for each task to prevent further delays.',
        type: SuggestionType.schedule,
        priority: 2,
        actionSteps: [
          'Open Calendar → Schedule tab',
          'Create time blocks for top 5 tasks',
          'Set reminders 15 minutes before',
        ],
        expectedImpact: 'Improve on-time completion by 60%',
      ));
    }

    // Suggestion 5: Pomodoro technique
    suggestions.add(SmartSuggestion(
      id: 'pomodoro',
      title: 'Try Pomodoro Technique',
      description: 'Use focused 25-minute work sessions to make progress on overdue tasks.',
      type: SuggestionType.timeManagement,
      priority: 3,
      actionSteps: [
        'Use "Plan My Day" feature',
        'Start with highest priority task',
        'Complete at least 4 Pomodoro sessions today',
      ],
      expectedImpact: 'Complete 2-3 tasks per day consistently',
    ));

    return suggestions;
  }

  // Bulk reschedule all overdue tasks
  Future<RescheduleResult> bulkReschedule() async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.bulkCarryover();
      
      // Reload data after reschedule
      await loadOverdueTasks();
      await loadCarryoverStats();
      
      _isLoading = false;
      notifyListeners();
      
      return RescheduleResult.fromJson(result);
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Reschedule single task
  Future<void> rescheduleSingleTask(int taskId) async {
    try {
      await _apiService.carryoverTask(taskId);
      
      // Reload data
      await loadOverdueTasks();
      await loadCarryoverStats();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // Refresh all carryover data
  Future<void> refreshAll() async {
    await Future.wait([
      loadCarryoverStats(),
      loadOverdueTasks(),
    ]);
    
    await analyzeDelayPatterns();
    await generateSuggestions();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}