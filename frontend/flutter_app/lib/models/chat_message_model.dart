class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final String? systemType; // 'simple_nlu' or 'claude'
  final Map<String, dynamic>? metadata; // For task creation confirmations, etc.

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.systemType,
    this.metadata,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      content: json['content'] ?? json['response'] ?? '',
      isUser: json['is_user'] ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
      systemType: json['system_type'] ?? json['model'],
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'is_user': isUser,
      'timestamp': timestamp.toIso8601String(),
      'system_type': systemType,
      'metadata': metadata,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    String? systemType,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      systemType: systemType ?? this.systemType,
      metadata: metadata ?? this.metadata,
    );
  }
}