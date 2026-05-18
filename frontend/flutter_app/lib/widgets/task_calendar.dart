import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_provider.dart';
import '../models/calendar_models.dart';
import '../config/theme_config.dart';

class TaskCalendar extends StatefulWidget {
  const TaskCalendar({super.key});

  @override
  State<TaskCalendar> createState() => _TaskCalendarState();
}

class _TaskCalendarState extends State<TaskCalendar> {
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<CalendarProvider>(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: provider.focusedDate,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) {
                return isSameDay(provider.selectedDate, day);
              },
              onDaySelected: (selectedDay, focusedDay) {
                provider.setSelectedDate(selectedDay);
                provider.setFocusedDate(focusedDay);
              },
              onFormatChanged: (format) {
                setState(() {
                  _calendarFormat = format;
                });
              },
              onPageChanged: (focusedDay) {
                provider.setFocusedDate(focusedDay);
              },
              eventLoader: (day) {
                return provider.getEventsForDay(day);
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: AppTheme.primaryColor,
                  shape: BoxShape.circle,
                ),
                markerDecoration: BoxDecoration(
                  color: AppTheme.accentColor,
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 3,
                outsideDaysVisible: false,
              ),
              headerStyle: HeaderStyle(
                formatButtonVisible: true,
                titleCentered: true,
                formatButtonShowsNext: false,
                formatButtonDecoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                formatButtonTextStyle: TextStyle(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              calendarBuilders: CalendarBuilders(
                markerBuilder: (context, day, events) {
                  if (events.isEmpty) return null;
                  
                  return Positioned(
                    bottom: 1,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: events.take(3).map((event) {
                        final calendarEvent = event as CalendarEvent;
                        return Container(
                          width: 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 1),
                          decoration: BoxDecoration(
                            color: calendarEvent.color,
                            shape: BoxShape.circle,
                          ),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}