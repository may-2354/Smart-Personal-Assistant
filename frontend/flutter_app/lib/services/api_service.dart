import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/user_model.dart';
import '../models/task_model.dart';
import 'package:intl/intl.dart';

class ApiService {
  String? _token;

  void setToken(String token) {
    _token = token;
  }

  String? getToken() => _token;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // Auth Methods
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse(ApiConfig.login),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'username': email,
        'password': password,
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> register(
    String email,
    String username,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse(ApiConfig.register),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'username': username,
        'password': password,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse(ApiConfig.currentUser),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return User.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to get user: ${response.body}');
    }
  }

  // Task Methods
  Future<List<Task>> getTasks({String? status, String? priority}) async {
    var url = ApiConfig.tasks;
    final params = <String, String>{};
    if (status != null) params['status'] = status;
    if (priority != null) params['priority'] = priority;
    
    if (params.isNotEmpty) {
      url += '?${params.entries.map((e) => '${e.key}=${e.value}').join('&')}';
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load tasks');
    }
  }

  Future<Task> createTask(Map<String, dynamic> taskData) async {
    final response = await http.post(
      Uri.parse(ApiConfig.tasks),
      headers: _headers,
      body: json.encode(taskData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Task.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to create task');
    }
  }

  Future<Task> updateTask(int taskId, Map<String, dynamic> updates) async {
    final response = await http.put(
      Uri.parse(ApiConfig.taskById(taskId)),
      headers: _headers,
      body: json.encode(updates),
    );

    if (response.statusCode == 200) {
      return Task.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to update task');
    }
  }

  Future<void> deleteTask(int taskId) async {
    final response = await http.delete(
      Uri.parse(ApiConfig.taskById(taskId)),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete task');
    }
  }

  Future<Map<String, dynamic>> getTaskStats() async {
    final response = await http.get(
      Uri.parse(ApiConfig.taskStats),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get stats');
    }
  }

  // Chat Method
  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/chat/'),
      headers: _headers,
      body: json.encode({'message': message}),
    );
    if (response.statusCode == 200) {
      return json.decode(response.body); // ✅ Returns full object
    } else {
      throw Exception('Chat failed');
    }
  }

  Future<Map<String, dynamic>> getBurnoutAnalytics() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/analytics/burnout'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load burnout analytics');
    }
  }

  Future<Map<String, dynamic>> getGamificationAnalytics() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/analytics/gamification'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load gamification analytics');
    }
  }

// Calendar Endpoints
  Future<List<Task>> getTasksForDate(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/tasks?date=$dateStr'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((task) => Task.fromJson(task)).toList();
    } else {
      throw Exception('Failed to load tasks for date');
    }
  }

  Future<List<Map<String, dynamic>>> getTimeBlocks(DateTime date) async {
    final dateStr = DateFormat('yyyy-MM-dd').format(date);
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/calendar/time-blocks?date=$dateStr'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
    // Return empty list if endpoint doesn't exist yet
      return [];
    }
  }

  Future<Map<String, dynamic>> createTimeBlock(Map<String, dynamic> blockData) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/calendar/time-blocks'),
      headers: _headers,
      body: json.encode(blockData),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to create time block');
    }
  }

  Future<void> deleteTimeBlock(String blockId) async {
    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/calendar/time-blocks/$blockId'),
      headers: _headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to delete time block');
    }
  }

  Future<Map<String, dynamic>> getAllAchievements() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/achievements'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load achievements');
    }
  }

  Future<Map<String, dynamic>> getLeaderboard({int limit = 10}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/analytics/leaderboard?limit=$limit'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return {'leaderboard': json.decode(response.body)};
    } else {
      throw Exception('Failed to load leaderboard');
    }
  }

  Future<Map<String, dynamic>> checkNewAchievements() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/analytics/achievements/check'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to check achievements');
    }
  }

// Get carryover statistics
  Future<Map<String, dynamic>> getCarryoverStats() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/tasks/carryover/stats'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load carryover stats');
    }
  }

// Bulk reschedule all overdue tasks
  Future<Map<String, dynamic>> bulkCarryover() async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/tasks/carryover/bulk'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to bulk reschedule tasks');
    }
  }

// Reschedule single task
  Future<Map<String, dynamic>> carryoverTask(int taskId) async {
    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/tasks/$taskId/carryover'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to reschedule task');
    }
  }

// Get overdue tasks (if not already have this)
  Future<List<Task>> getOverdueTasks() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/tasks/overdue'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((json) => Task.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load overdue tasks');
    }
  }

  Future<Map<String, dynamic>> getNotifications() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/notifications'),
      headers: _headers,
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load notifications');
    }
  }

  Future<void> markNotificationRead(String id) async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/notifications/$id/read'),
      headers: _headers,
    );
  }

  Future<void> markAllNotificationsRead() async {
    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/notifications/read-all'),
      headers: _headers,
    );
  }

  Future<void> deleteNotification(String id) async {
    await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/notifications/$id'),
      headers: _headers,
    );
  }
  Future<Map<String, dynamic>> getProductivityAnalytics({int days = 30}) async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/analytics/productivity?period_days=$days'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load productivity analytics');
    }
  }

  Future<Map<String, dynamic>> getGamificationStats() async {
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/analytics/gamification'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load gamification stats');
    }
  }
  Future<List<Task>> getTasksForDateRange(DateTime start, DateTime end) async {
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/tasks?start_date=$startStr&end_date=$endStr'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return data.map((task) => Task.fromJson(task)).toList();
    } else {
      return getTasks();
    }
  }

  Future<List<Map<String, dynamic>>> getTimeBlocksForRange(DateTime start, DateTime end) async {
    final startStr = DateFormat('yyyy-MM-dd').format(start);
    final endStr = DateFormat('yyyy-MM-dd').format(end);
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/calendar/time-blocks?start_date=$startStr&end_date=$endStr'),
      headers: _headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body);
      return List<Map<String, dynamic>>.from(data);
    } else {
      return [];
    }
  }
}