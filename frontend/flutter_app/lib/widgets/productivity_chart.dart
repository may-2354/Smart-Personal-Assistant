import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/analytics_model.dart';
import '../config/theme_config.dart';

class ProductivityChart extends StatelessWidget {
  final List<DailyProductivity> data;
  final int periodDays;

  const ProductivityChart({
    super.key,
    required this.data,
    required this.periodDays,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return _buildEmptyState();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Productivity Trend',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Last $periodDays days',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
                _buildLegend(),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 200,
              child: LineChart(
                _buildChartData(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      children: [
        _buildLegendItem('Completed', AppTheme.successColor),
        const SizedBox(width: 12),
        _buildLegendItem('Created', AppTheme.primaryColor),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  LineChartData _buildChartData() {
    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: 2,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey.shade200,
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: periodDays <= 7 ? 1 : (periodDays / 7).ceil().toDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= data.length) {
                return const Text('');
              }
              final date = data[index].dateTime;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  DateFormat('M/d').format(date),
                  style: TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 2,
            reservedSize: 32,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300, width: 1),
          left: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
      ),
      minX: 0,
      maxX: (data.length - 1).toDouble(),
      minY: 0,
      maxY: _getMaxY(),
      lineBarsData: [
        // Completed tasks line
        LineChartBarData(
          spots: _getCompletedSpots(),
          isCurved: true,
          color: AppTheme.successColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppTheme.successColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.successColor.withOpacity(0.1),
          ),
        ),
        // Created tasks line
        LineChartBarData(
          spots: _getCreatedSpots(),
          isCurved: true,
          color: AppTheme.primaryColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: AppTheme.primaryColor,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: AppTheme.primaryColor.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  List<FlSpot> _getCompletedSpots() {
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.completed.toDouble());
    }).toList();
  }

  List<FlSpot> _getCreatedSpots() {
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.created.toDouble());
    }).toList();
  }

  double _getMaxY() {
    var maxCompleted = data.map((d) => d.completed).reduce((a, b) => a > b ? a : b);
    var maxCreated = data.map((d) => d.created).reduce((a, b) => a > b ? a : b);
    var max = maxCompleted > maxCreated ? maxCompleted : maxCreated;
    return (max + 2).toDouble();
  }

  Widget _buildEmptyState() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        height: 250,
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.show_chart,
                size: 48,
                color: AppTheme.textSecondary.withOpacity(0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'No data available',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}