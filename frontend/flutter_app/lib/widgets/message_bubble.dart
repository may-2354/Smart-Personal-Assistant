import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_message_model.dart';
import '../config/theme_config.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAvatar;

  const MessageBubble({
    super.key,
    required this.message,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment:
            message.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Bot avatar (left side)
          if (!message.isUser && showAvatar) _buildAvatar(),
          if (!message.isUser && showAvatar) const SizedBox(width: 8),

          // Message bubble
          Flexible(
            child: Column(
              crossAxisAlignment: message.isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                // System badge (for bot messages)
                if (!message.isUser && message.systemType != null)
                  _buildSystemBadge(),
                
                const SizedBox(height: 4),
                
                // Message container
                Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  decoration: BoxDecoration(
                    color: message.isUser
                        ? AppTheme.primaryColor
                        : Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: Radius.circular(message.isUser ? 20 : 4),
                      bottomRight: Radius.circular(message.isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Message text
                      Text(
                        message.content,
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white
                              : AppTheme.textPrimary,
                          fontSize: 15,
                          height: 1.4,
                        ),
                      ),
                      
                      const SizedBox(height: 4),
                      
                      // Timestamp
                      Text(
                        DateFormat('HH:mm').format(message.timestamp),
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white.withOpacity(0.7)
                              : AppTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // User avatar (right side)
          if (message.isUser && showAvatar) const SizedBox(width: 8),
          if (message.isUser && showAvatar) _buildAvatar(),
        ],
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: message.isUser
            ? AppTheme.primaryColor
            : AppTheme.secondaryColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Icon(
          message.isUser ? Icons.person : Icons.smart_toy,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }

  Widget _buildSystemBadge() {
    // Check if it's Gemini AI
    final isGeminiAI = message.systemType?.toLowerCase().contains('gemini') ?? false;
    
    // Determine badge properties
    final badgeColor = isGeminiAI ? AppTheme.accentColor : AppTheme.successColor;
    final badgeText = isGeminiAI ? 'Gemini AI' : 'Simple NLU';
    final badgeIcon = isGeminiAI ? Icons.auto_awesome : Icons.lightbulb_outline;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: badgeColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            badgeIcon,
            size: 12,
            color: badgeColor,
          ),
          const SizedBox(width: 4),
          Text(
            badgeText,
            style: TextStyle(
              color: badgeColor,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}