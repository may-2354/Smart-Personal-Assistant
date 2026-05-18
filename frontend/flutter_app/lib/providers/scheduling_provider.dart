import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/scheduling_models.dart';
import '../models/task_model.dart';
import '../models/calendar_models.dart' show TimeBlock, CalendarEvent;

class SchedulingProvider with ChangeNotifier {
  List<ScheduleConflict> _conflicts = [];
  DayPlan? _dayPlan;
  bool _isGenerating = false;
  String? _error;

  List<ScheduleConflict> get conflicts => _conflicts;
  DayPlan? get dayPlan => _dayPlan;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  bool get hasConflicts => _conflicts.isNotEmpty;

  // Detect conflicts between tasks and time blocks
  Future<void> detectConflicts(List<Task> tasks, List<TimeBlock> timeBlocks) async {
    _conflicts.clear();

    // Filter tasks with deadlines AND not completed
    final scheduledTasks = tasks.where((t) => 
      t.deadline != null && 
      t.status != 'completed'
    ).toList();

    print('\n=== Conflict Detection ===');
    print('Checking ${scheduledTasks.length} scheduled tasks');

    // Check Task vs Task conflicts
    for (int i = 0; i < scheduledTasks.length; i++) {
      for (int j = i + 1; j < scheduledTasks.length; j++) {
        final conflict = _checkTaskVsTask(scheduledTasks[i], scheduledTasks[j]);
        if (conflict != null) {
          print('✗ Conflict found: ${scheduledTasks[i].title} vs ${scheduledTasks[j].title}');
          _conflicts.add(conflict);
        }
      }
    }

    print('Total conflicts found: ${_conflicts.length}\n');

    // Check Task vs TimeBlock conflicts
    for (final task in scheduledTasks) {
      for (final block in timeBlocks) {
        final conflict = _checkTaskVsTimeBlock(task, block);
        if (conflict != null) _conflicts.add(conflict);
      }
    }

    // Check TimeBlock vs TimeBlock conflicts
    for (int i = 0; i < timeBlocks.length; i++) {
      for (int j = i + 1; j < timeBlocks.length; j++) {
        final conflict = _checkTimeBlockVsTimeBlock(timeBlocks[i], timeBlocks[j]);
        if (conflict != null) _conflicts.add(conflict);
      }
    }

    notifyListeners();
  }

  ScheduleConflict? _checkTaskVsTask(Task task1, Task task2) {
    if (task1.deadline == null || task2.deadline == null) return null;

    // Get durations - check both field names for compatibility
    final duration1 = task1.estimated_duration ?? _estimateDuration(task1);
    final duration2 = task2.estimated_duration ?? _estimateDuration(task2);

    // Task end time is the deadline
    final end1 = task1.deadline!;
    final end2 = task2.deadline!;
    
    // Task start time is deadline minus duration
    final start1 = end1.subtract(Duration(minutes: duration1));
    final start2 = end2.subtract(Duration(minutes: duration2));

    print('  Task: ${task1.title}');
    print('    Duration: $duration1 min');
    print('    Time: ${DateFormat('HH:mm').format(start1)} - ${DateFormat('HH:mm').format(end1)}');
    print('  Task: ${task2.title}');
    print('    Duration: $duration2 min');
    print('    Time: ${DateFormat('HH:mm').format(start2)} - ${DateFormat('HH:mm').format(end2)}');

    return _createConflictIfOverlap(
      ConflictType.taskVsTask,
      task1,
      task2,
      start1,
      end1,
      start2,
      end2,
    );
  }

  ScheduleConflict? _checkTaskVsTimeBlock(Task task, TimeBlock block) {
    if (task.deadline == null) return null;

    final duration = task.estimated_duration ?? _estimateDuration(task);
    final taskStart = task.deadline!.subtract(Duration(minutes: duration));
    final taskEnd = task.deadline!;

    return _createConflictIfOverlap(
      ConflictType.taskVsTimeBlock,
      task,
      block,
      taskStart,
      taskEnd,
      block.startTime,
      block.endTime,
    );
  }

  ScheduleConflict? _checkTimeBlockVsTimeBlock(TimeBlock block1, TimeBlock block2) {
    return _createConflictIfOverlap(
      ConflictType.timeBlockVsTimeBlock,
      block1,
      block2,
      block1.startTime,
      block1.endTime,
      block2.startTime,
      block2.endTime,
    );
  }

  ScheduleConflict? _createConflictIfOverlap(
    ConflictType type,
    dynamic item1,
    dynamic item2,
    DateTime start1,
    DateTime end1,
    DateTime start2,
    DateTime end2,
  ) {
    // Check if they overlap
    if (start1.isBefore(end2) && end1.isAfter(start2)) {
      final conflictStart = start1.isAfter(start2) ? start1 : start2;
      final conflictEnd = end1.isBefore(end2) ? end1 : end2;
      final overlapDuration = conflictEnd.difference(conflictStart);

      final overlapMinutes = overlapDuration.inMinutes;
      print('    → Overlap: $overlapMinutes minutes');

      // Determine severity
      ConflictSeverity severity;
      if (overlapMinutes < 15) {
        severity = ConflictSeverity.low;
      } else if (overlapMinutes < 30) {
        severity = ConflictSeverity.medium;
      } else if (overlapMinutes < 60) {
        severity = ConflictSeverity.high;
      } else {
        severity = ConflictSeverity.critical;
      }

      // High priority tasks get elevated severity
      if (item1 is Task && (item1.priority == 'critical' || item1.priority == 'high')) {
        if (severity.index < ConflictSeverity.high.index) {
          severity = ConflictSeverity.high;
        }
      }

      return ScheduleConflict(
        id: '${DateTime.now().millisecondsSinceEpoch}',
        type: type,
        item1: item1,
        item2: item2,
        conflictStart: conflictStart,
        conflictEnd: conflictEnd,
        overlapDuration: overlapDuration,
        severity: severity,
      );
    }

    return null;
  }

  // Plan My Day - Generate Pomodoro sessions
  Future<void> planMyDay(List<Task> todayTasks) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      final sessions = <PomodoroSession>[];
      
      // Filter incomplete tasks with deadlines
      final tasksToSchedule = todayTasks
          .where((t) => t.status != 'completed' && t.deadline != null)
          .toList();

      // Sort by priority then deadline
      tasksToSchedule.sort((a, b) {
        final priorityOrder = {'critical': 0, 'high': 1, 'medium': 2, 'low': 3};
        final aPriority = priorityOrder[a.priority.toLowerCase()] ?? 2;
        final bPriority = priorityOrder[b.priority.toLowerCase()] ?? 2;
        
        if (aPriority != bPriority) {
          return aPriority.compareTo(bPriority);
        }
        return a.deadline!.compareTo(b.deadline!);
      });

      // Start scheduling from now or 8 AM if it's earlier
      DateTime currentTime = DateTime.now();
      if (currentTime.hour < 8) {
        currentTime = DateTime(
          currentTime.year,
          currentTime.month,
          currentTime.day,
          8,
          0,
        );
      }

      int globalSessionCount = 0;
      int totalWorkMinutes = 0;
      int totalBreakMinutes = 0;

      // Generate sessions for each task
      for (final task in tasksToSchedule) {
        final duration = task.estimated_duration ?? _estimateDuration(task);
        final pomodoroCount = (duration / 25).ceil();

        for (int i = 0; i < pomodoroCount; i++) {
          globalSessionCount++;

          // Work session
          sessions.add(PomodoroSession(
            id: 'work_${task.id}_$i',
            task: task,
            sessionNumber: i + 1,
            totalSessions: pomodoroCount,
            scheduledStart: currentTime,
            duration: const Duration(minutes: 25),
            type: PomodoroSessionType.work,
          ));
          currentTime = currentTime.add(const Duration(minutes: 25));
          totalWorkMinutes += 25;

          // Add break if not the last session of the task
          if (i < pomodoroCount - 1 || task != tasksToSchedule.last) {
            if (globalSessionCount % 4 == 0) {
              // Long break after every 4 work sessions
              sessions.add(PomodoroSession(
                id: 'long_break_$i',
                task: task,
                sessionNumber: 0,
                totalSessions: 0,
                scheduledStart: currentTime,
                duration: const Duration(minutes: 15),
                type: PomodoroSessionType.longBreak,
              ));
              currentTime = currentTime.add(const Duration(minutes: 15));
              totalBreakMinutes += 15;
            } else {
              // Short break
              sessions.add(PomodoroSession(
                id: 'short_break_$i',
                task: task,
                sessionNumber: 0,
                totalSessions: 0,
                scheduledStart: currentTime,
                duration: const Duration(minutes: 5),
                type: PomodoroSessionType.shortBreak,
              ));
              currentTime = currentTime.add(const Duration(minutes: 5));
              totalBreakMinutes += 5;
            }
          }
        }
      }

      _dayPlan = DayPlan(
        date: DateTime.now(),
        sessions: sessions,
        conflicts: _conflicts,
        totalWorkMinutes: totalWorkMinutes,
        totalBreakMinutes: totalBreakMinutes,
        tasksIncluded: tasksToSchedule.length,
      );

      _isGenerating = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isGenerating = false;
      notifyListeners();
    }
  }

  void completeSession(String sessionId) {
    if (_dayPlan == null) return;

    final updatedSessions = _dayPlan!.sessions.map((session) {
      if (session.id == sessionId) {
        return session.copyWith(isCompleted: true);
      }
      return session;
    }).toList();

    _dayPlan = DayPlan(
      date: _dayPlan!.date,
      sessions: updatedSessions,
      conflicts: _dayPlan!.conflicts,
      totalWorkMinutes: _dayPlan!.totalWorkMinutes,
      totalBreakMinutes: _dayPlan!.totalBreakMinutes,
      tasksIncluded: _dayPlan!.tasksIncluded,
    );

    notifyListeners();
  }

  void clearDayPlan() {
    _dayPlan = null;
    notifyListeners();
  }

  void clearConflicts() {
    _conflicts.clear();
    notifyListeners();
  }

  // Generate AI reschedule suggestions
  List<RescheduleOption> generateRescheduleOptions(ScheduleConflict conflict) {
    final options = <RescheduleOption>[];

    // Store the conflict for later use
    final task1 = conflict.item1 as Task;
    final task2 = conflict.item2 as Task;

    // Calculate durations
    final duration1 = task1.estimated_duration ?? _estimateDuration(task1);
    final duration2 = task2.estimated_duration ?? _estimateDuration(task2);

    // Option 1: Move first task earlier (1 hour before its current time)
    final newDeadline1 = task1.deadline!.subtract(const Duration(hours: 1));
    options.add(RescheduleOption(
      id: 'move_earlier_${task1.id}',
      title: 'Move "${task1.title}" earlier',
      description: 'Reschedule to ${DateFormat('h:mm a').format(newDeadline1)}',
      newStart: newDeadline1.subtract(Duration(minutes: duration1)),
      newEnd: newDeadline1,
      confidence: 85,
      reasons: [
        'Avoids conflict completely',
        'Maintains task sequence',
        'Creates time buffer',
      ],
      metadata: {'taskId': task1.id.toString()},
    ));

    // Option 2: Move second task later (1 hour after its current time)
    final newDeadline2 = task2.deadline!.add(const Duration(hours: 1));
    options.add(RescheduleOption(
      id: 'move_later_${task2.id}',
      title: 'Move "${task2.title}" later',
      description: 'Reschedule to ${DateFormat('h:mm a').format(newDeadline2)}',
      newStart: newDeadline2.subtract(Duration(minutes: duration2)),
      newEnd: newDeadline2,
      confidence: 80,
      reasons: [
        'Keeps first task on schedule',
        'Creates buffer time',
        'Prevents new conflicts',
      ],
      metadata: {'taskId': task2.id.toString()},
    ));

    // Option 3: Sequential - place task1 after task2 ends
    final task2EndTime = task2.deadline!;
    final newDeadline3 = task2EndTime.add(Duration(minutes: duration1 + 15));
    options.add(RescheduleOption(
      id: 'sequential_${task1.id}',
      title: 'Schedule "${task1.title}" after "${task2.title}"',
      description: 'Start at ${DateFormat('h:mm a').format(task2EndTime.add(const Duration(minutes: 15)))}',
      newStart: task2EndTime.add(const Duration(minutes: 15)),
      newEnd: newDeadline3,
      confidence: 90,
      reasons: [
        'No overlap guaranteed',
        '15-min buffer included',
        'Natural workflow',
      ],
      metadata: {'taskId': task1.id.toString()},
    ));

    return options;
  }

  // Apply reschedule option
  Future<void> applyRescheduleOption(
    RescheduleOption option,
    dynamic taskProvider,
  ) async {
    try {
      // Get task ID from metadata
      final taskIdStr = option.metadata?['taskId'];
      if (taskIdStr == null) {
        print('❌ No task ID in option metadata');
        throw Exception('No task ID found');
      }

      final taskId = int.parse(taskIdStr);
      print('\n=== Applying Reschedule ===');
      print('Task ID: $taskId');
      
      // Find the task
      final tasks = taskProvider.tasks as List;
      dynamic foundTask;
      
      for (var task in tasks) {
        if (task.id == taskId) {
          foundTask = task;
          break;
        }
      }
      
      if (foundTask == null) {
        print('❌ Task not found with id: $taskId');
        throw Exception('Task not found');
      }
      
      print('✓ Found task: ${foundTask.title}');
      print('  Old deadline: ${DateFormat('HH:mm').format(foundTask.deadline!)}');
      print('  New deadline: ${DateFormat('HH:mm').format(option.newEnd)}');

      // Update task deadline using TaskProvider's method
      await taskProvider.updateTaskDeadline(foundTask.id, option.newEnd);
      
      print('✓ Task updated successfully\n');

      notifyListeners();
    } catch (e) {
      print('❌ Error applying reschedule: $e');
      rethrow;
    }
  }

  int _estimateDuration(Task task) {
    // Fallback estimation
    final priorityDurations = {
      'critical': 90,
      'high': 60,
      'medium': 30,
      'low': 15,
    };
    return priorityDurations[task.priority.toLowerCase()] ?? 30;
  }
}