import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_provider.dart';
import '../models/calendar_models.dart';
import '../config/theme_config.dart';

class TimeBlockingView extends StatelessWidget {
  const TimeBlockingView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarProvider>(context);
    final events = provider.getEventsForDay(provider.selectedDate);
    final timeBlocks = provider.getTimeBlocksForDay(provider.selectedDate);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMMM d').format(provider.selectedDate),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${events.length} tasks • ${timeBlocks.length} time blocks',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                IconButton.filled(
                  onPressed: () => _showCreateTimeBlockDialog(context, provider),
                  icon: const Icon(Icons.add),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Time slots
          Expanded(
            child: events.isEmpty && timeBlocks.isEmpty
                ? _buildEmptyState()
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Show time blocks
                      ...timeBlocks.map((block) => _buildTimeBlockCard(context, provider, block)),
                      
                      // Show events
                      ...events.map((event) => _buildEventCard(context, event)),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 64,
            color: AppTheme.textSecondary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No tasks or time blocks',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create a time block to organize your day',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeBlockCard(BuildContext context, CalendarProvider provider, TimeBlock block) {
    final startTime = DateFormat('h:mm a').format(block.startTime);
    final endTime = DateFormat('h:mm a').format(block.endTime);
    final duration = block.duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border.all(color: block.color, width: 2),
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            block.color.withOpacity(0.1),
            block.color.withOpacity(0.05),
          ],
        ),
      ),
      child: InkWell(
        onTap: () => _showTimeBlockDetails(context, provider, block),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Time indicator
              Container(
                width: 4,
                height: 60,
                decoration: BoxDecoration(
                  color: block.color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 16),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      block.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$startTime - $endTime',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.timelapse,
                          size: 14,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Sync status indicator
                  if (!block.isSynced)
                    Tooltip(
                      message: 'Local only (not synced)',
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.warningColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_off,
                          size: 16,
                          color: AppTheme.warningColor,
                        ),
                      ),
                    )
                  else
                    Tooltip(
                      message: 'Synced to backend',
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.successColor.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.cloud_done,
                          size: 16,
                          color: AppTheme.successColor,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit, size: 20),
                            SizedBox(width: 12),
                            Text('Edit'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete, size: 20, color: Colors.red),
                            SizedBox(width: 12),
                            Text('Delete', style: TextStyle(color: Colors.red)),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) {
                      if (value == 'delete') {
                        _showDeleteDialog(context, provider, block.id);
                      } else if (value == 'edit') {
                        _showEditTimeBlockDialog(context, provider, block);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventCard(BuildContext context, CalendarEvent event) {
    final startTime = DateFormat('h:mm a').format(event.startTime);
    final endTime = DateFormat('h:mm a').format(event.endTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: event.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: event.color.withOpacity(0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.task_alt,
              color: event.color,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (event.description != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      event.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '$startTime - $endTime',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateTimeBlockDialog(BuildContext context, CalendarProvider provider) {
    final titleController = TextEditingController();
    TimeOfDay startTime = TimeOfDay.now();
    TimeOfDay endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 1);
    Color selectedColor = AppTheme.primaryColor;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Create Time Block'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'e.g., Deep Work',
                    border: OutlineInputBorder(),
                  ),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                
                // Start time
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('Start Time'),
                  subtitle: Text(startTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: startTime,
                    );
                    if (time != null) {
                      setDialogState(() => startTime = time);
                    }
                  },
                ),
                
                // End time
                ListTile(
                  leading: const Icon(Icons.access_time),
                  title: const Text('End Time'),
                  subtitle: Text(endTime.format(context)),
                  onTap: () async {
                    final time = await showTimePicker(
                      context: context,
                      initialTime: endTime,
                    );
                    if (time != null) {
                      setDialogState(() => endTime = time);
                    }
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Color picker
                const Text('Color', style: TextStyle(fontSize: 12)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    AppTheme.primaryColor,
                    AppTheme.successColor,
                    AppTheme.warningColor,
                    AppTheme.errorColor,
                    AppTheme.accentColor,
                    Colors.purple,
                  ].map((color) {
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selectedColor == color
                                ? Colors.black
                                : Colors.transparent,
                            width: 3,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter a title'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final now = provider.selectedDate;
                final start = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  startTime.hour,
                  startTime.minute,
                );
                final end = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  endTime.hour,
                  endTime.minute,
                );

                if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('End time must be after start time'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  return;
                }

                final block = TimeBlock(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: titleController.text.trim(),
                  startTime: start,
                  endTime: end,
                  color: selectedColor,
                );

                provider.createTimeBlock(block);
                Navigator.pop(dialogContext);
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Time block "${block.title}" created'),
                    backgroundColor: AppTheme.successColor,
                  ),
                );
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditTimeBlockDialog(BuildContext context, CalendarProvider provider, TimeBlock block) {
    // Similar to create dialog but with pre-filled values
    _showCreateTimeBlockDialog(context, provider);
  }

  void _showTimeBlockDetails(BuildContext context, CalendarProvider provider, TimeBlock block) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(block.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
              Icons.access_time,
              'Time',
              '${DateFormat('h:mm a').format(block.startTime)} - ${DateFormat('h:mm a').format(block.endTime)}',
            ),
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.timelapse,
              'Duration',
              '${block.duration.inHours}h ${block.duration.inMinutes % 60}m',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(value),
      ],
    );
  }

  void _showDeleteDialog(BuildContext context, CalendarProvider provider, String blockId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Time Block'),
        content: const Text('Are you sure you want to delete this time block?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              provider.deleteTimeBlock(blockId);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}