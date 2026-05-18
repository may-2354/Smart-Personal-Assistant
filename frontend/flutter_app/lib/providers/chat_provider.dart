import 'package:flutter/material.dart';
import '../models/chat_message_model.dart';
import '../services/api_service.dart';

class ChatProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  String? _error;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  String? get error => _error;

  void setToken(String token) {
    _apiService.setToken(token);
  }

  Future<void> sendMessage(String content, {Function? onTaskCreated}) async {
    if (content.trim().isEmpty) return;

    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content.trim(),
      isUser: true,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isTyping = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _apiService.sendChatMessage(content.trim());
      
      print('📨 Chat response: $response');
      
      final botMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: response['response'] ?? response['message'] ?? 'No response',
        isUser: false,
        timestamp: DateTime.now(),
        systemType: response['handled_by'] ?? response['model'] ?? response['system_type'] ?? 'simple_nlu',
        metadata: response['metadata'] ?? {
          'intent': response['intent'],
          'suggestion': response['suggestion'],
        },
      );

      _messages.add(botMessage);
      _isTyping = false;
      notifyListeners();

      // SMART DETECTION - Works with any Gemini wording!
      final taskWasCreated = _checkIfTaskCreated(response);
      
      if (taskWasCreated && onTaskCreated != null) {
        print('✅ Task creation detected - triggering reload');
        await onTaskCreated();
      }
    } catch (e) {
      _error = e.toString();
      _isTyping = false;
      
      final errorMessage = ChatMessage(
        id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
        content: 'Sorry, I encountered an error. Please try again.',
        isUser: false,
        timestamp: DateTime.now(),
      );
      _messages.add(errorMessage);
      
      notifyListeners();
      print('Chat error: $e');
    }
  }

  bool _checkIfTaskCreated(Map<String, dynamic> response) {
    // 1. BEST: Check backend flag (if available)
    if (response['task_created'] == true) {
      print('✅ Detected via: task_created flag');
      return true;
    }
    
    // 2. GOOD: Check intent (if backend provides it)
    final intent = response['intent']?.toString().toLowerCase() ?? '';
    if (intent.contains('create') || 
        intent.contains('add') || 
        intent.contains('schedule')) {
      print('✅ Detected via: intent ($intent)');
      return true;
    }
    
    // 3. SMART: Analyze response text for task creation indicators
    final text = response['response']?.toString().toLowerCase() ?? '';
    
    // Step A: Check for task-related nouns
    final taskNouns = [
      'task',
      'tasks',
      'schedule',
      'appointment',
      'reminder',
      'event',
      'meeting',
      'recurring',
      'daily',
      'weekly',
    ];
    
    bool hasTaskNoun = false;
    for (final noun in taskNouns) {
      if (text.contains(noun)) {
        hasTaskNoun = true;
        break;
      }
    }
    
    if (!hasTaskNoun) {
      print('❌ No task-related words found');
      return false;
    }
    
    // Step B: Check for action/completion verbs
    final actionVerbs = [
      'added',
      'created',
      'scheduled',
      'set',
      'done',
      'ready',
      'all set',
      'organized',
      'saved',
      'registered',
      'booked',
      'planned',
      'arranged',
      'confirmed',
      'setup',
      'configured',
    ];
    
    bool hasActionVerb = false;
    String matchedVerb = '';
    for (final verb in actionVerbs) {
      if (text.contains(verb)) {
        hasActionVerb = true;
        matchedVerb = verb;
        break;
      }
    }
    
    // Step C: Check for phrases indicating completion
    final completionPhrases = [
      'for you',
      'is now',
      'has been',
      'have been',
      'all set',
      'you\'re all set',
      'here you go',
      'there you go',
      'your',
    ];
    
    bool hasCompletionPhrase = false;
    for (final phrase in completionPhrases) {
      if (text.contains(phrase)) {
        hasCompletionPhrase = true;
        break;
      }
    }
    
    // DECISION: If we have task noun + (action verb OR completion phrase)
    if (hasTaskNoun && (hasActionVerb || hasCompletionPhrase)) {
      print('✅ Detected via: smart text analysis');
      print('   → Task noun: found');
      print('   → Action verb: ${hasActionVerb ? matchedVerb : "none"}');
      print('   → Completion phrase: ${hasCompletionPhrase ? "found" : "none"}');
      return true;
    }
    
    print('❌ No clear task creation detected');
    print('   → Task noun: $hasTaskNoun');
    print('   → Action verb: $hasActionVerb');
    print('   → Completion: $hasCompletionPhrase');
    return false;
  }

  void clearMessages() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  void addSystemMessage(String content) {
    final message = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      isUser: false,
      timestamp: DateTime.now(),
      systemType: 'system',
    );
    _messages.add(message);
    notifyListeners();
  }
}