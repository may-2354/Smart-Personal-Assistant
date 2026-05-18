import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../providers/task_provider.dart';
import '../../config/theme_config.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _priority = 'medium';
  String? _category;
  DateTime? _deadline;
  List<String> _tags = [];
  final _tagController = TextEditingController();
  
  bool _isUrgent = false;
  bool _isImportant = false;

  // Voice recognition
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;
  String _currentField = ''; // 'title' or 'description'

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    _speechAvailable = await _speech.initialize(
      onError: (error) => print('Speech recognition error: $error'),
      onStatus: (status) => print('Speech recognition status: $status'),
    );
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    _speech.stop();
    super.dispose();
  }

  void _startListening(String field) async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    setState(() {
      _currentField = field;
      _isListening = true;
    });

    await _speech.listen(
      onResult: (result) {
        setState(() {
          if (_currentField == 'title') {
            _titleController.text = result.recognizedWords;
          } else if (_currentField == 'description') {
            _descriptionController.text = result.recognizedWords;
          }
        });
      },
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
    );
  }

  void _stopListening() async {
    await _speech.stop();
    setState(() {
      _isListening = false;
      _currentField = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Task'),
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
            // Title with Voice Input
            Row(
              children: [
                Expanded(
                  child: TextFormField(
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
                ),
                const SizedBox(width: 8),
                _buildVoiceButton('title'),
              ],
            ),
            const SizedBox(height: 16),

            // Description with Voice Input
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Enter task description',
                      prefixIcon: Icon(Icons.description),
                    ),
                    maxLines: 4,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _buildVoiceButton('description'),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Voice Status Indicator
            if (_isListening) _buildListeningIndicator(),

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

  Widget _buildVoiceButton(String field) {
    final isCurrentField = _isListening && _currentField == field;
    
    return Container(
      decoration: BoxDecoration(
        color: isCurrentField ? AppTheme.primaryColor : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(
          isCurrentField ? Icons.mic : Icons.mic_none,
          color: isCurrentField ? Colors.white : Colors.grey.shade700,
        ),
        onPressed: () {
          if (isCurrentField) {
            _stopListening();
          } else {
            _startListening(field);
          }
        },
        tooltip: isCurrentField ? 'Stop recording' : 'Voice input',
      ),
    );
  }

  Widget _buildListeningIndicator() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 6,
                height: 6,
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Listening... Speak now',
              style: TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          TextButton(
            onPressed: _stopListening,
            child: const Text('Stop'),
          ),
        ],
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
            Icon(
              Icons.flag,
              color: color,
              size: 24,
            ),
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

    final taskData = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      'priority': _priority,
      'category': _category,
      'deadline': _deadline?.toIso8601String(),
      'tags': _tags,
      'is_urgent': _isUrgent,
      'is_important': _isImportant,
    };

    final success = await taskProvider.createTask(taskData);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: AppTheme.successColor,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(taskProvider.error ?? 'Failed to create task'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}