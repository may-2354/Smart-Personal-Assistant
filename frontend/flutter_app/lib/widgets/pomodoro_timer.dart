import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/calendar_provider.dart';
import '../models/calendar_models.dart';
import '../config/theme_config.dart';

class PomodoroTimer extends StatefulWidget {
  const PomodoroTimer({super.key});

  @override
  State<PomodoroTimer> createState() => _PomodoroTimerState();
}

class _PomodoroTimerState extends State<PomodoroTimer> {
  Timer? _timer;
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final provider = Provider.of<CalendarProvider>(context, listen: false);
      final pomodoro = provider.currentPomodoro;

      if (pomodoro == null || !pomodoro.isActive) {
        return;
      }

      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          // Time's up!
          _handleTimerComplete();
        }
      });
    });
  }

  void _handleTimerComplete() {
    final provider = Provider.of<CalendarProvider>(context, listen: false);
    provider.nextPomodoroPhase();
    
    // Show notification
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.currentPomodoro?.currentPhase == PomodoroPhase.work
              ? '🎯 Work session complete! Time for a break.'
              : '☕ Break over! Ready to focus?',
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarProvider>(context);
    final pomodoro = provider.currentPomodoro;

    if (pomodoro == null) {
      return _buildStartView(provider);
    }

    // Initialize remaining seconds if needed
    if (_remainingSeconds == 0 && pomodoro.isActive) {
      _remainingSeconds = pomodoro.currentMinutes * 60;
    }

    return Card(
      elevation: 4,
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
              _getPhaseColor(pomodoro.currentPhase).withOpacity(0.1),
              _getPhaseColor(pomodoro.currentPhase).withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Phase indicator
            _buildPhaseIndicator(pomodoro),
            const SizedBox(height: 24),

            // Circular timer
            _buildCircularTimer(pomodoro),
            const SizedBox(height: 32),

            // Controls
            _buildControls(provider, pomodoro),
            const SizedBox(height: 16),

            // Cycle indicator
            _buildCycleIndicator(pomodoro),
          ],
        ),
      ),
    );
  }

  Widget _buildStartView(CalendarProvider provider) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.timer,
              size: 80,
              color: AppTheme.primaryColor,
            ),
            const SizedBox(height: 24),
            Text(
              'Pomodoro Timer',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Stay focused with the Pomodoro Technique',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _showSettingsDialog(provider),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Session'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseIndicator(PomodoroSession pomodoro) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: _getPhaseColor(pomodoro.currentPhase).withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getPhaseIcon(pomodoro.currentPhase),
            size: 20,
            color: _getPhaseColor(pomodoro.currentPhase),
          ),
          const SizedBox(width: 8),
          Text(
            _getPhaseName(pomodoro.currentPhase),
            style: TextStyle(
              color: _getPhaseColor(pomodoro.currentPhase),
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularTimer(PomodoroSession pomodoro) {
    final totalSeconds = pomodoro.currentMinutes * 60;
    final progress = _remainingSeconds / totalSeconds;
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;

    return SizedBox(
      width: 200,
      height: 200,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: 1.0,
              strokeWidth: 12,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.grey.shade200,
              ),
            ),
          ),
          // Progress circle
          SizedBox(
            width: 200,
            height: 200,
            child: CircularProgressIndicator(
              value: progress,
              strokeWidth: 12,
              backgroundColor: Colors.transparent,
              valueColor: AlwaysStoppedAnimation<Color>(
                _getPhaseColor(pomodoro.currentPhase),
              ),
            ),
          ),
          // Time display
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: _getPhaseColor(pomodoro.currentPhase),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                pomodoro.isActive ? 'In Progress' : 'Paused',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControls(CalendarProvider provider, PomodoroSession pomodoro) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Play/Pause button
        IconButton.filled(
          onPressed: () {
            if (pomodoro.isActive) {
              provider.pausePomodoro();
            } else {
              provider.resumePomodoro();
            }
          },
          icon: Icon(pomodoro.isActive ? Icons.pause : Icons.play_arrow),
          iconSize: 32,
          style: IconButton.styleFrom(
            backgroundColor: _getPhaseColor(pomodoro.currentPhase),
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(width: 16),
        // Stop button
        IconButton.outlined(
          onPressed: () => _showStopDialog(provider),
          icon: const Icon(Icons.stop),
          iconSize: 32,
          style: IconButton.styleFrom(
            side: BorderSide(color: AppTheme.errorColor),
            foregroundColor: AppTheme.errorColor,
            padding: const EdgeInsets.all(16),
          ),
        ),
        const SizedBox(width: 16),
        // Skip button
        IconButton.outlined(
          onPressed: () {
            provider.nextPomodoroPhase();
            setState(() {
              _remainingSeconds = 0;
            });
          },
          icon: const Icon(Icons.skip_next),
          iconSize: 32,
          style: IconButton.styleFrom(
            padding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildCycleIndicator(PomodoroSession pomodoro) {
    return Column(
      children: [
        Text(
          'Cycle ${pomodoro.completedCycles + 1} of ${pomodoro.totalCycles}',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(pomodoro.totalCycles, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 40,
              height: 6,
              decoration: BoxDecoration(
                color: index < pomodoro.completedCycles
                    ? AppTheme.successColor
                    : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          }),
        ),
      ],
    );
  }

  void _showSettingsDialog(CalendarProvider provider) {
    int workMinutes = 25;
    int breakMinutes = 5;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pomodoro Settings'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Work Duration'),
                subtitle: Text('$workMinutes minutes'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (workMinutes > 5) {
                          setState(() => workMinutes -= 5);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (workMinutes < 60) {
                          setState(() => workMinutes += 5);
                        }
                      },
                    ),
                  ],
                ),
              ),
              ListTile(
                title: const Text('Break Duration'),
                subtitle: Text('$breakMinutes minutes'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () {
                        if (breakMinutes > 5) {
                          setState(() => breakMinutes -= 5);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () {
                        if (breakMinutes < 30) {
                          setState(() => breakMinutes += 5);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.startPomodoro(
                workMinutes: workMinutes,
                breakMinutes: breakMinutes,
              );
              setState(() {
                _remainingSeconds = workMinutes * 60;
              });
              Navigator.pop(context);
            },
            child: const Text('Start'),
          ),
        ],
      ),
    );
  }

  void _showStopDialog(CalendarProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Stop Session?'),
        content: const Text('Are you sure you want to stop the current Pomodoro session?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.stopPomodoro();
              setState(() {
                _remainingSeconds = 0;
              });
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Stop'),
          ),
        ],
      ),
    );
  }

  Color _getPhaseColor(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.work:
        return AppTheme.primaryColor;
      case PomodoroPhase.shortBreak:
        return AppTheme.successColor;
      case PomodoroPhase.longBreak:
        return AppTheme.accentColor;
    }
  }

  IconData _getPhaseIcon(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.work:
        return Icons.work;
      case PomodoroPhase.shortBreak:
        return Icons.coffee;
      case PomodoroPhase.longBreak:
        return Icons.spa;
    }
  }

  String _getPhaseName(PomodoroPhase phase) {
    switch (phase) {
      case PomodoroPhase.work:
        return 'Focus Time';
      case PomodoroPhase.shortBreak:
        return 'Short Break';
      case PomodoroPhase.longBreak:
        return 'Long Break';
    }
  }
}