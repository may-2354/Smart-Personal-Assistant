import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/task_model.dart';
import '../../providers/task_provider.dart';
import '../../config/theme_config.dart';

class EditTaskScreen extends StatefulWidget {
  final Task task;

  const EditTaskScreen({super.key, required this.task});

  @override
  State<EditTaskScreen> createState() => _EditTaskScreenState();
}

class _EditTaskScreenState extends State<EditTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  
  late String _priority;
  late String? _category;
  late DateTime? _deadline;
  late List<String> _tags;
  final _tagController = TextEditingController();
  
  late bool _isUrgent;
  late bool _isImportant;
  late String _status;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description ?? '');
    _priority = widget.task.priority;
    _category = widget.task.category;
    _deadline = widget.task.deadline;
    _tags = List.from(widget.task.tags);
    _isUrgent = widget.task.isUrgent;
    _isImportant = widget.task.isImportant;
    _status = widget.task.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Task'),
        actions: [
          TextButton(
            onPressed: _saveTask,
            child: const Text('SAVE'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Task Title *',
                hintText: 'Enter task title',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Enter task description',
                prefixIcon: Icon(Icons.description),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 24),

            // Status
            Text(
              'Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildStatusSelector(),
            const SizedBox(height: 24),

            // Priority
            Text(
              'Priority',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildPrioritySelector(),
            const SizedBox(height: 24),

            // Category
            Text(
              'Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildCategorySelector(),
            const SizedBox(height: 24),

            // Deadline
            Text(
              'Deadline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildDeadlineSelector(),
            const SizedBox(height: 24),

            // Eisenhower Matrix
            Text(
              'Eisenhower Matrix',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildEisenhowerToggles(),
            const SizedBox(height: 24),

            // Tags
            Text(
              'Tags',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildTagsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildStatusChip('pending', 'Pending', Icons.hourglass_empty, AppTheme.mediumColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatusChip('in_progress', 'In Progress', Icons.play_arrow, AppTheme.warningColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildStatusChip('completed', 'Completed', Icons.check_circle, AppTheme.successColor),
        ),
      ],
    );
  }

  Widget _buildStatusChip(String value, String label, IconData icon, Color color) {
    final isSelected = _status == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _status = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: [
        Expanded(
          child: _buildPriorityChip('critical', 'Critical', AppTheme.criticalColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPriorityChip('high', 'High', AppTheme.highColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPriorityChip('medium', 'Medium', AppTheme.mediumColor),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPriorityChip('low', 'Low', AppTheme.lowColor),
        ),
      ],
    );
  }

  Widget _buildPriorityChip(String value, String label, Color color) {
    final isSelected = _priority == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _priority = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.flag, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySelector() {
    final categories = [
      {'name': 'Work', 'icon': Icons.work_outline, 'color': Colors.blue},
      {'name': 'Personal', 'icon': Icons.person_outline, 'color': Colors.green},
      {'name': 'Shopping', 'icon': Icons.shopping_cart_outlined, 'color': Colors.orange},
      {'name': 'Health', 'icon': Icons.favorite_outline, 'color': Colors.red},
      {'name': 'Other', 'icon': Icons.more_horiz, 'color': Colors.grey},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: categories.map((cat) {
        final isSelected = _category == cat['name'];
        return InkWell(
          onTap: () {
            setState(() {
              _category = _category == cat['name'] ? null : cat['name'] as String?;
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected 
                  ? (cat['color'] as Color).withOpacity(0.2) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected 
                    ? (cat['color'] as Color) 
                    : Colors.grey.shade300,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  size: 18,
                  color: cat['color'] as Color,
                ),
                const SizedBox(width: 6),
                Text(
                  cat['name'] as String,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDeadlineSelector() {
    return InkWell(
      onTap: _selectDeadline,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: _deadline != null ? AppTheme.primaryColor : AppTheme.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _deadline != null
                    ? DateFormat('MMM dd, yyyy • hh:mm a').format(_deadline!)
                    : 'No deadline set',
                style: TextStyle(
                  color: _deadline != null 
                      ? AppTheme.textPrimary 
                      : AppTheme.textSecondary,
                ),
              ),
            ),
            if (_deadline != null)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  setState(() {
                    _deadline = null;
                  });
                },
                color: AppTheme.textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEisenhowerToggles() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Urgent'),
          subtitle: const Text('Requires immediate attention'),
          value: _isUrgent,
          onChanged: (value) {
            setState(() {
              _isUrgent = value;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
        SwitchListTile(
          title: const Text('Important'),
          subtitle: const Text('Significant and meaningful'),
          value: _isImportant,
          onChanged: (value) {
            setState(() {
              _isImportant = value;
            });
          },
          activeColor: AppTheme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  hintText: 'Add a tag',
                  prefixIcon: Icon(Icons.label_outline),
                ),
                onSubmitted: _addTag,
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () => _addTag(_tagController.text),
              color: AppTheme.primaryColor,
            ),
          ],
        ),
        if (_tags.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _tags.map((tag) {
              return Chip(
                label: Text(tag),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  setState(() {
                    _tags.remove(tag);
                  });
                },
                backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  void _addTag(String tag) {
    if (tag.trim().isNotEmpty && !_tags.contains(tag.trim())) {
      setState(() {
        _tags.add(tag.trim());
        _tagController.clear();
      });
    }
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _deadline ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_deadline ?? DateTime.now()),
      );

      if (time != null) {
        setState(() {
          _deadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final taskProvider = Provider.of<TaskProvider>(context, listen: false);

    final updates = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'priority': _priority,
      'status': _status,
      'category': _category,
      'deadline': _deadline?.toIso8601String(),
      'tags': _tags,
      'is_urgent': _isUrgent,
      'is_important': _isImportant,
    };

    final success = await taskProvider.updateTask(widget.task.id, updates);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task updated successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.error ?? 'Failed to update task'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}