import 'package:flutter/material.dart';
import '../models/analytics_model.dart';
import '../config/theme_config.dart';

class BurnoutWarning extends StatelessWidget {
  final BurnoutIndicator indicator;

  const BurnoutWarning({
    super.key,
    required this.indicator,
  });

  @override
  Widget build(BuildContext context) {
    final config = _getBurnoutConfig(indicator.level);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: config['color'] as Color, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              (config['color'] as Color).withOpacity(0.1),
              (config['color'] as Color).withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: (config['color'] as Color).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    config['icon'] as IconData,
                    color: config['color'] as Color,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        config['title'] as String,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: config['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Burnout Score: ${indicator.score.toStringAsFixed(0)}%',
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
            const SizedBox(height: 16),

            // Burnout level indicator
            _buildProgressBar(indicator.score, config['color'] as Color),
            const SizedBox(height: 16),

            // Message
            Text(
              indicator.message,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
              ),
            ),

            // Warning Signs Section
            if (indicator.indicators.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Warning Signs:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...indicator.indicators.map((ind) => _buildIndicator(ind)),
            ],

            // Recommendations Section
            if (indicator.recommendations.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text(
                'Recommendations:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...indicator.recommendations.map((rec) => _buildRecommendation(rec)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(double score, Color color) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Low',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
            Text(
              'Critical',
              style: TextStyle(
                fontSize: 11,
                color: AppTheme.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: score / 100,
            minHeight: 8,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildIndicator(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber,
            size: 16,
            color: AppTheme.warningColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendation(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: AppTheme.successColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _getBurnoutConfig(String level) {
    switch (level) {
      case 'critical':
        return {
          'title': '⚠️ Critical Burnout Risk',
          'icon': Icons.warning_amber_rounded,
          'color': AppTheme.errorColor,
        };
      case 'high':
        return {
          'title': '😰 High Burnout Risk',
          'icon': Icons.error_outline,
          'color': AppTheme.warningColor,
        };
      case 'medium':
        return {
          'title': '😓 Moderate Burnout Risk',
          'icon': Icons.info_outline,
          'color': Colors.orange,
        };
      default:
        return {
          'title': '😊 Low Burnout Risk',
          'icon': Icons.check_circle_outline,
          'color': AppTheme.successColor,
        };
    }
  }
}