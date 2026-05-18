import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/task_provider.dart';
import '../../widgets/task_card.dart';
import '../../widgets/eisenhower_matrix_view.dart';
import '../../config/theme_config.dart';
import '../../models/task_model.dart';
import 'task_detail_screen.dart';
import 'create_task_screen.dart';

class TaskListScreen extends StatefulWidget {
  const TaskListScreen({super.key});

  @override
  State<TaskListScreen> createState() => _TaskListScreenState();
}

class _TaskListScreenState extends State<TaskListScreen> {
  bool _showMatrix = false;

  @override
  Widget build(BuildContext context) {
    final taskProvider = Provider.of<TaskProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(
            icon: Icon(_showMatrix ? Icons.list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _showMatrix = !_showMatrix;
              });
            },
            tooltip: _showMatrix ? 'List View' : 'Matrix View',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              if (value == 'clear') {
                taskProvider.clearFilters();
              } else {
                taskProvider.setFilter(value);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All Tasks')),
              const PopupMenuItem(value: 'pending', child: Text('Pending')),
              const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
              const PopupMenuItem(value: 'completed', child: Text('Completed')),
              const PopupMenuDivider(),
              const PopupMenuItem(value: 'clear', child: Text('Clear Filters')),
            ],
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            tooltip: 'Sort by',
            onSelected: (value) => _sortTasks(taskProvider, value),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'priority', child: Text('Priority')),
              const PopupMenuItem(value: 'deadline', child: Text('Deadline')),
              const PopupMenuItem(value: 'created', child: Text('Date Created')),
              const PopupMenuItem(value: 'title', child: Text('Title (A-Z)')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => taskProvider.refresh(),
        child: Column(
          children: [
            // Filter Chips
            _buildFilterChips(taskProvider),
            
            // Content
            Expanded(
              child: _showMatrix
                  ? _buildMatrixView(taskProvider)
                  : _buildListView(taskProvider),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToCreateTask(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildFilterChips(TaskProvider taskProvider) {
    // Get current filters using reflection on filteredTasks to determine active filters
    // Since we can't access private variables, we'll track selections locally
    return Container(
      padding: const EdgeInsets.all(16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            // Priority Filters
            _buildFilterChip(
              label: 'Critical',
              selected: false, // Will be managed by provider internally
              color: AppTheme.criticalColor,
              onTap: () {
                taskProvider.setPriorityFilter('critical');
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'High',
              selected: false,
              color: AppTheme.highColor,
              onTap: () {
                taskProvider.setPriorityFilter('high');
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Medium',
              selected: false,
              color: AppTheme.mediumColor,
              onTap: () {
                taskProvider.setPriorityFilter('medium');
              },
            ),
            const SizedBox(width: 8),
            _buildFilterChip(
              label: 'Low',
              selected: false,
              color: AppTheme.lowColor,
              onTap: () {
                taskProvider.setPriorityFilter('low');
              },
            ),
            const SizedBox(width: 16),
            
            // Clear Filters
            ActionChip(
              label: const Text('Clear Filters'),
              avatar: const Icon(Icons.clear, size: 18),
              onPressed: () => taskProvider.clearFilters(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      selectedColor: color.withOpacity(0.3),
      checkmarkColor: color,
      onSelected: (_) => onTap(),
      side: BorderSide(color: color.withOpacity(0.5)),
    );
  }

  Widget _buildMatrixView(TaskProvider taskProvider) {
    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: EisenhowerMatrixView(
        matrix: taskProvider.eisenhowerMatrix,
        onTaskTap: (task) => _navigateToTaskDetail(context, task),
      ),
    );
  }

  Widget _buildListView(TaskProvider taskProvider) {
    if (taskProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final filteredTasks = taskProvider.filteredTasks;

    if (filteredTasks.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.task_alt,
              size: 80,
              color: AppTheme.textSecondary,
            ),
            const SizedBox(height: 16),
            Text(
              'No tasks found',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              taskProvider.currentFilter != 'all'
                  ? 'Try changing your filters'
                  : 'Create your first task!',
              style: TextStyle(
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: filteredTasks.length,
      itemBuilder: (context, index) {
        final task = filteredTasks[index];
        return TaskCard(
          task: task,
          onTap: () => _navigateToTaskDetail(context, task),
          onComplete: () => _completeTask(context, taskProvider, task),
          onDelete: () => _confirmDelete(context, taskProvider, task),
        );
      },
    );
  }

  void _sortTasks(TaskProvider taskProvider, String sortBy) {
    // This would be implemented in TaskProvider
    // For now, just show a message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Sorting by $sortBy')),
    );
  }

  void _navigateToCreateTask(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CreateTaskScreen(),
      ),
    );
  }

  void _navigateToTaskDetail(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TaskDetailScreen(task: task),
      ),
    );
  }

  Future<void> _completeTask(
    BuildContext context,
    TaskProvider taskProvider,
    Task task,
  ) async {
    final success = await taskProvider.updateTask(
      task.id,
      {'status': 'completed'},
    );

    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task completed! 🎉'),
          backgroundColor: AppTheme.successColor,
        ),
      );
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TaskProvider taskProvider,
    Task task,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Are you sure you want to delete "${task.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final success = await taskProvider.deleteTask(task.id);
      if (success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted')),
        );
      }
    }
  }
}