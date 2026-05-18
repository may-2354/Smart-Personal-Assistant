import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../providers/chat_provider.dart';
import '../../providers/task_provider.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme_config.dart';
import '../../widgets/message_bubble.dart';
import '../../widgets/typing_indicator.dart';
import '../../services/storage_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  
  // Voice input - THE MISSING FEATURE!
  late stt.SpeechToText _speech;
  bool _isListening = false;
  bool _speechAvailable = false;

  @override
  void initState() {
    super.initState();
    _initChat();
    _initSpeech(); // Initialize voice recognition
  }

  Future<void> _initChat() async {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    
    // Set token
    final token = await StorageService().getToken();
    if (token != null) {
      chatProvider.setToken(token);
    }

    // Add welcome message if first time
    if (chatProvider.messages.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        chatProvider.addSystemMessage(
          "👋 Hi! I'm your AI assistant. I can help you create and manage tasks. "
          "Try saying things like:\n\n"
          "• Create a task to finish the report\n"
          "• Add a meeting for tomorrow at 3pm\n"
          "• Show my pending tasks\n\n"
          "🎤 Tap the microphone to use voice input!\n\n"
          "How can I help you today?"
        );
      });
    }
  }

  Future<void> _initSpeech() async {
    _speech = stt.SpeechToText();
    try {
      _speechAvailable = await _speech.initialize(
        onStatus: (status) {
          print('Speech status: $status');
          if (status == 'done' || status == 'notListening') {
            setState(() => _isListening = false);
          }
        },
        onError: (error) {
          print('Speech error: $error');
          setState(() => _isListening = false);
        },
      );
      setState(() {});
      print('Speech available: $_speechAvailable');
    } catch (e) {
      print('Speech initialization error: $e');
      _speechAvailable = false;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _speech.stop();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text;
    if (message.trim().isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    
    _messageController.clear();
    _focusNode.unfocus();

    // ⭐ THE KEY FIX: Properly reload tasks from server!
    await chatProvider.sendMessage(
      message,
      onTaskCreated: () async {
        print('');
        print('═══════════════════════════════════════');
        print('🎯 CALLBACK FIRED!!!');
        print('═══════════════════════════════════════');
        print('');
        
        print('📊 Current task count BEFORE reload: ${taskProvider.tasks.length}');
        
        print('🔄 Calling taskProvider.loadTasks()...');
        try {
          await taskProvider.loadTasks();
          print('✅ loadTasks() completed successfully!');
        } catch (e) {
          print('❌ ERROR in loadTasks(): $e');
        }
        
        print('📊 Task count AFTER reload: ${taskProvider.tasks.length}');
        print('');
        print('📝 Current tasks in list:');
        if (taskProvider.tasks.isEmpty) {
          print('   (empty - no tasks!)');
        } else {
          for (var i = 0; i < taskProvider.tasks.length && i < 5; i++) {
            final task = taskProvider.tasks[i];
            print('   $i. "${task.title}" (${task.status}) [${task.deadline}]');
          }
          if (taskProvider.tasks.length > 5) {
            print('   ... and ${taskProvider.tasks.length - 5} more');
          }
        }
        print('');
        
        print('🔄 Calling taskProvider.loadStats()...');
        try {
          await taskProvider.loadStats();
          print('✅ loadStats() completed!');
          print('📊 Stats: ${taskProvider.stats}');
        } catch (e) {
          print('❌ ERROR in loadStats(): $e');
        }
        
        print('');
        print('═══════════════════════════════════════');
        print('');
        
        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text('Task created! Total tasks: ${taskProvider.tasks.length}'),
                  ),
                ],
              ),
              backgroundColor: AppTheme.successColor,
              duration: Duration(seconds: 3),
            ),
          );
        }
      },
    );
    
    _scrollToBottom();
  }

  // ⭐ VOICE INPUT METHODS - THE MISSING FEATURE!
  void _toggleListening() async {
    if (!_speechAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🎤 Speech recognition not available on this device'),
          backgroundColor: AppTheme.errorColor,
        ),
      );
      return;
    }

    if (_isListening) {
      // Stop listening
      await _speech.stop();
      setState(() => _isListening = false);
    } else {
      // Start listening
      setState(() => _isListening = true);
      
      await _speech.listen(
        onResult: (result) {
          setState(() {
            _messageController.text = result.recognizedWords;
          });
          
          // Auto-send if final result
          if (result.finalResult) {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (_messageController.text.isNotEmpty) {
                _sendMessage();
              }
            });
          }
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        cancelOnError: true,
        partialResults: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearDialog(chatProvider),
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: chatProvider.messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: AppTheme.textSecondary.withOpacity(0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(
                            fontSize: 18,
                            color: AppTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start a conversation to create tasks',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.textSecondary.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: chatProvider.messages.length + 
                               (chatProvider.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == chatProvider.messages.length) {
                        return const TypingIndicator();
                      }
                      
                      final message = chatProvider.messages[index];
                      return MessageBubble(message: message);
                    },
                  ),
          ),

          // Input area
          _buildInputArea(chatProvider),
        ],
      ),
    );
  }

  Widget _buildInputArea(ChatProvider chatProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            // ⭐ VOICE INPUT BUTTON - THE MISSING BUTTON!
            if (_speechAvailable)
              Container(
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                  color: _isListening 
                      ? AppTheme.errorColor.withOpacity(0.1)
                      : AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isListening ? Icons.mic : Icons.mic_none,
                    color: _isListening 
                        ? AppTheme.errorColor 
                        : AppTheme.primaryColor,
                  ),
                  onPressed: chatProvider.isTyping ? null : _toggleListening,
                  tooltip: _isListening ? 'Stop listening' : 'Voice input',
                ),
              ),

            // Text input
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppTheme.textSecondary.withOpacity(0.2),
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  focusNode: _focusNode,
                  decoration: InputDecoration(
                    hintText: _isListening 
                        ? '🎤 Listening...' 
                        : 'Type your message...',
                    hintStyle: TextStyle(
                      color: _isListening 
                          ? AppTheme.errorColor 
                          : AppTheme.textSecondary,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                  enabled: !_isListening,
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Send button
            Container(
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.send),
                color: Colors.white,
                onPressed: (chatProvider.isTyping || _isListening) 
                    ? null 
                    : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showClearDialog(ChatProvider chatProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Chat'),
        content: const Text(
          'Are you sure you want to clear all messages? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              chatProvider.clearMessages();
              Navigator.pop(context);
              _initChat();
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('How to Use AI Assistant'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'You can interact using voice or text:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildHelpItem(
                Icons.mic,
                'Voice Input',
                'Tap the 🎤 microphone and speak your request',
              ),
              _buildHelpItem(
                Icons.keyboard,
                'Text Input',
                'Type your message in the text field',
              ),
              const SizedBox(height: 16),
              const Text(
                'Example Commands:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              _buildExampleCommand('Create a task to buy groceries'),
              _buildExampleCommand('Add meeting tomorrow at 2pm'),
              _buildExampleCommand('Show my pending tasks'),
              _buildExampleCommand('What tasks are due today?'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleCommand(String command) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            Icons.chevron_right,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              command,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}