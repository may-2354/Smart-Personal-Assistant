import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';

class TaskProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<Task> _tasks = [];
  Map<String, dynamic>? _stats;
  bool _isLoading = false;
  String? _error;
  
  String _currentFilter = 'all'; // all, pending, completed
  String? _currentPriority;
  String? _currentCategory;

  List<Task> get tasks => _tasks;
  Map<String, dynamic>? get stats => _stats;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentFilter => _currentFilter;

  List<Task> get filteredTasks {
    var filtered = _tasks;
    
    if (_currentFilter != 'all') {
      filtered = filtered.where((t) => t.status == _currentFilter).toList();
    }
    
    if (_currentPriority != null) {
      filtered = filtered.where((t) => t.priority == _currentPriority).toList();
    }
    
    if (_currentCategory != null) {
      filtered = filtered.where((t) => t.category == _currentCategory).toList();
    }
    
    return filtered;
  }

  List<Task> get todayTasks {
    final now = DateTime.now();
    return _tasks.where((task) {
      if (task.deadline == null) return false;
      return task.deadline!.year == now.year &&
             task.deadline!.month == now.month &&
             task.deadline!.day == now.day;
    }).toList();
  }

  List<Task> get overdueTasks {
    final now = DateTime.now();
    return _tasks.where((task) {
      if (task.deadline == null) return false;
      return task.deadline!.isBefore(now) && task.status != 'completed';
    }).toList();
  }

  // Eisenhower Matrix
  Map<String, List<Task>> get eisenhowerMatrix {
    return {
      'urgent_important': _tasks.where((t) => t.isUrgent && t.isImportant).toList(),
      'not_urgent_important': _tasks.where((t) => !t.isUrgent && t.isImportant).toList(),
      'urgent_not_important': _tasks.where((t) => t.isUrgent && !t.isImportant).toList(),
      'not_urgent_not_important': _tasks.where((t) => !t.isUrgent && !t.isImportant).toList(),
    };
  }

  void setToken(String token) {
    _apiService.setToken(token);
  }

  void setFilter(String filter) {
    _currentFilter = filter;
    notifyListeners();
  }

  void setPriorityFilter(String? priority) {
    _currentPriority = priority;
    notifyListeners();
  }

  void setCategoryFilter(String? category) {
    _currentCategory = category;
    notifyListeners();
  }

  void clearFilters() {
    _currentFilter = 'all';
    _currentPriority = null;
    _currentCategory = null;
    notifyListeners();
  }

  Future<void> loadTasks() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _tasks = await _apiService.getTasks();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadStats() async {
    try {
      _stats = await _apiService.getTaskStats();
      notifyListeners();
    } catch (e) {
      print('Error loading stats: $e');
    }
  }

  Future<bool> createTask(Map<String, dynamic> taskData) async {
    try {
      final newTask = await _apiService.createTask(taskData);
      _tasks.insert(0, newTask);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTask(int taskId, Map<String, dynamic> updates) async {
    try {
      final updatedTask = await _apiService.updateTask(taskId, updates);
      final index = _tasks.indexWhere((t) => t.id == taskId);
      if (index != -1) {
        _tasks[index] = updatedTask;
        notifyListeners();
      }
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTask(int taskId) async {
    try {
      await _apiService.deleteTask(taskId);
      _tasks.removeWhere((t) => t.id == taskId);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Add this to task_provider.dart

  Future<void> updateTaskDeadline(int taskId, DateTime newDeadline) async {
    try {
      final response = await _apiService.updateTask(taskId, {
        'deadline': newDeadline.toIso8601String(),
      });
    
    // Reload tasks to get updated data
      await loadTasks();
    
      notifyListeners();
    } catch (e) {
      print('Error updating task deadline: $e');
      rethrow;
    }
  }

  Future<void> refresh() async {
    await loadTasks();
    await loadStats();
  }
}