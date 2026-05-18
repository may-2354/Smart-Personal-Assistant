import 'package:flutter/material.dart';
import '../models/calendar_models.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

class CalendarProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();
  List<CalendarEvent> _events = [];
  List<TimeBlock> _timeBlocks = [];
  PomodoroSession? _currentPomodoro;
  bool _isLoading = false;
  String? _error;

  DateTime get selectedDate => _selectedDate;
  DateTime get focusedDate => _focusedDate;
  List<CalendarEvent> get events => _events;
  List<TimeBlock> get timeBlocks => _timeBlocks;
  PomodoroSession? get currentPomodoro => _currentPomodoro;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void setToken(String token) {
    _apiService.setToken(token);
  }

  void setSelectedDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
    loadEventsForDate(date);
  }

  void setFocusedDate(DateTime date) {
    _focusedDate = date;
    notifyListeners();
  }

  List<CalendarEvent> getEventsForDay(DateTime day) {
    return _events.where((event) => event.isOnDate(day)).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  List<TimeBlock> getTimeBlocksForDay(DateTime day) {
    return _timeBlocks.where((block) {
      return block.startTime.year == day.year &&
          block.startTime.month == day.month &&
          block.startTime.day == day.day;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  Future<void> loadEventsForDate(DateTime date) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
    // Load tasks for the ENTIRE MONTH, not just one day
      final firstDayOfMonth = DateTime(date.year, date.month, 1);
      final lastDayOfMonth = DateTime(date.year, date.month + 1, 0);
    
    // Get all tasks for the month
      final tasks = await _apiService.getTasksForDateRange(
        firstDayOfMonth,
        lastDayOfMonth,
      );
    
    // Convert tasks to calendar events
      _events = tasks.map((task) => _taskToEvent(task)).toList();
    
    // Load time blocks for the month
      final blocks = await _apiService.getTimeBlocksForRange(
        firstDayOfMonth,
        lastDayOfMonth,
      );
      _timeBlocks = blocks.map((b) => TimeBlock.fromJson(b)).toList();
    
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      print('Error loading calendar events: $e');
    }
  }

  CalendarEvent _taskToEvent(Task task) {
    final deadline = task.deadline ?? DateTime.now();
    
    return CalendarEvent(
      id: task.id.toString(),
      title: task.title,
      description: task.description,
      startTime: deadline.subtract(const Duration(hours: 1)),
      endTime: deadline,
      color: task.priorityColor,
      type: EventType.task,
      taskId: task.id.toString(),
      metadata: {'priority': task.priority, 'status': task.status},
    );
  }

  Future<void> createTimeBlock(TimeBlock block) async {
    // Add to local list immediately for instant UI update (not synced yet)
    _timeBlocks.add(block);
    notifyListeners();

    // Then try to sync with backend
    try {
      final response = await _apiService.createTimeBlock(block.toJson());
      
      // Mark as synced and update with backend ID if different
      final index = _timeBlocks.indexWhere((b) => b.id == block.id);
      if (index != -1) {
        _timeBlocks[index] = block.copyWith(
          id: response['id']?.toString() ?? block.id,
          isSynced: true,
        );
        notifyListeners();
      }
      
      print('✅ Time block synced to backend');
    } catch (e) {
      // If backend fails, keep it local anyway
      print('⚠️ Time block created locally only (backend not available): $e');
      _error = null; // Don't show error to user
    }
  }

  Future<void> deleteTimeBlock(String id) async {
    try {
      await _apiService.deleteTimeBlock(id);
      _timeBlocks.removeWhere((b) => b.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // Pomodoro Timer Methods
  void startPomodoro({int workMinutes = 25, int breakMinutes = 5}) {
    _currentPomodoro = PomodoroSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      startTime: DateTime.now(),
      workMinutes: workMinutes,
      breakMinutes: breakMinutes,
      isActive: true,
    );
    notifyListeners();
  }

  void pausePomodoro() {
    if (_currentPomodoro != null) {
      _currentPomodoro = _currentPomodoro!.copyWith(isActive: false);
      notifyListeners();
    }
  }

  void resumePomodoro() {
    if (_currentPomodoro != null) {
      _currentPomodoro = _currentPomodoro!.copyWith(isActive: true);
      notifyListeners();
    }
  }

  void stopPomodoro() {
    _currentPomodoro = null;
    notifyListeners();
  }

  void completePomodoroCycle() {
    if (_currentPomodoro != null) {
      final completed = _currentPomodoro!.completedCycles + 1;
      final isLongBreak = completed % 4 == 0;
      
      _currentPomodoro = _currentPomodoro!.copyWith(
        completedCycles: completed,
        currentPhase: completed >= _currentPomodoro!.totalCycles
            ? PomodoroPhase.work
            : (isLongBreak ? PomodoroPhase.longBreak : PomodoroPhase.shortBreak),
      );
      notifyListeners();
    }
  }

  void nextPomodoroPhase() {
    if (_currentPomodoro != null) {
      final nextPhase = _currentPomodoro!.currentPhase == PomodoroPhase.work
          ? PomodoroPhase.shortBreak
          : PomodoroPhase.work;
      
      _currentPomodoro = _currentPomodoro!.copyWith(
        currentPhase: nextPhase,
        startTime: DateTime.now(),
      );
      notifyListeners();
    }
  }
}