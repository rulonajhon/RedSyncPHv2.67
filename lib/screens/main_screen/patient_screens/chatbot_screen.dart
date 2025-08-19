import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:hemophilia_manager/models/online/chat_message.dart';
import 'package:hemophilia_manager/services/openai_service.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  // Static list to persist messages across widget rebuilds during app session
  static List<ChatMessage> _sessionMessages = [];
  static bool _hasInitialized = false;

  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!_hasInitialized) {
      _addWelcomeMessage();
      _hasInitialized = true;
    }
  }

  void _addWelcomeMessage() {
    _sessionMessages.add(
      ChatMessage(
        text:
            "Hello! I'm HemoAssistant, your AI companion for hemophilia care and support. I'm here to help you with:\n\n"
            "• Understanding hemophilia types and symptoms\n"
            "• Treatment and medication guidance\n"
            "• Lifestyle and activity recommendations\n"
            "• Emergency care information\n"
            "• Emotional support and resources\n\n"
            "How can I assist you today?\n\n"
            "*Please remember that I provide informational support only and cannot replace professional medical advice.*",
        isUser: false,
      ),
    );
  }

  void _sendMessage() async {
    if (_textController.text.trim().isEmpty) return;

    final userMessage = _textController.text.trim();
    _textController.clear();

    setState(() {
      _sessionMessages.add(ChatMessage(text: userMessage, isUser: true));
      _isLoading = true;
    });

    _scrollToBottom();

    try {
      // First, check if the message is hemophilia-related
      final isHemophiliaRelated = await _isHemophiliaRelatedQuery(userMessage);

      if (!isHemophiliaRelated) {
        setState(() {
          _sessionMessages.add(
            ChatMessage(
              text:
                  "I'm HemoAssistant, specifically designed to help with hemophilia-related questions and concerns. "
                  "I can assist you with:\n\n"
                  "• Understanding hemophilia types and symptoms\n"
                  "• Treatment and medication guidance\n"
                  "• Lifestyle and activity recommendations\n"
                  "• Emergency care information\n"
                  "• Emotional support for hemophilia patients\n"
                  "• Diet and nutrition for hemophilia\n"
                  "• Exercise and physical therapy\n\n"
                  "Please ask me something related to hemophilia care, and I'll be happy to help!",
              isUser: false,
            ),
          );
          _isLoading = false;
        });
        _scrollToBottom();
        return;
      }

      // Convert messages to format expected by OpenAI API
      // Exclude the just-added user message from history
      final chatHistory = _sessionMessages
          .where(
            (msg) =>
                _sessionMessages.indexOf(msg) != _sessionMessages.length - 1,
          )
          .map((msg) => msg.toMap())
          .toList();

      final response = await OpenAIService.generateResponse(
        userMessage,
        chatHistory,
      );

      if (response.isNotEmpty) {
        setState(() {
          _sessionMessages.add(ChatMessage(text: response, isUser: false));
          _isLoading = false;
        });
      } else {
        setState(() {
          _sessionMessages.add(
            ChatMessage(
              text:
                  "I'm sorry, I couldn't generate a response at the moment. Please try asking your hemophilia-related question again.",
              isUser: false,
            ),
          );
          _isLoading = false;
        });
      }

      _scrollToBottom();
    } catch (e) {
      setState(() {
        _sessionMessages.add(
          ChatMessage(
            text:
                "I apologize, but I'm having trouble connecting right now. Please check your internet connection and try again. If the problem persists, you may need to verify your API configuration.",
            isUser: false,
          ),
        );
        _isLoading = false;
      });
      _scrollToBottom();
    }
  }

  Future<bool> _isHemophiliaRelatedQuery(String query) async {
    // Convert query to lowercase for better matching
    final lowerQuery = query.toLowerCase().trim();

    // Allow simple greetings and polite interactions
    final greetings = [
      'hello',
      'hi',
      'hey',
      'good morning',
      'good afternoon',
      'good evening',
      'how are you',
      'how do you do',
      'nice to meet you',
      'greetings',
      'thank you',
      'thanks',
      'please',
      'excuse me',
      'sorry',
      'goodbye',
      'bye',
      'see you',
      'have a good day',
      'take care',
    ];

    // Check for simple greetings - allow these through
    if (greetings.any((greeting) => lowerQuery.contains(greeting)) &&
        lowerQuery.split(' ').length <= 5) {
      return true;
    }

    // NEW: Check conversation context - if recent messages were about hemophilia,
    // allow follow-up questions even if they don't contain explicit hemophilia keywords
    if (_sessionMessages.length >= 2) {
      // Check the last 4 messages (2 user + 2 assistant) for hemophilia context
      final recentMessages = _sessionMessages
          .skip(_sessionMessages.length > 4 ? _sessionMessages.length - 4 : 0)
          .take(4)
          .toList();

      bool hasRecentHemophiliaContext = false;
      for (final message in recentMessages) {
        final messageText = message.text.toLowerCase();
        if (_containsHemophiliaKeywords(messageText)) {
          hasRecentHemophiliaContext = true;
          break;
        }
      }

      // If recent conversation was about hemophilia, allow follow-up questions
      // BUT ONLY if they contain medical/treatment terms
      if (hasRecentHemophiliaContext) {
        // Only allow follow-ups that mention medical/treatment terms
        final medicalTreatmentTerms = [
          'water', 'salt', 'ice', 'heat', 'warm', 'cold', 'compress',
          'bandage', 'pressure', 'rest', 'elevation', 'medication',
          'treatment', 'remedy', 'home remedy', 'care', 'help',
          'apply', 'use for', 'take for', 'medicine', 'therapy',
          'bleeding', 'blood', 'pain', 'swelling', 'bruise',
          'doctor', 'hospital', 'emergency', 'first aid',
          'dose', 'dosage', 'infusion', 'injection', 'factor',
        ];

        // Check if the query contains medical/treatment context
        bool containsMedicalTerms = medicalTreatmentTerms.any(
          (term) => lowerQuery.contains(term)
        );

        // Only allow if it's a medical follow-up question
        if (containsMedicalTerms) {
          final followUpPatterns = [
            'can i', 'should i', 'is it safe', 'can i use', 'should i use',
            'is it okay', 'what about', 'how about', 'what if',
          ];
          
          if (followUpPatterns.any((pattern) => lowerQuery.contains(pattern))) {
            return true;
          }
        }
      }
    }

    // Check if query directly contains hemophilia keywords
    if (_containsHemophiliaKeywords(lowerQuery)) {
      return true;
    }

    // Additional contextual checks for medical terms that might be hemophilia-related
    final medicalContextWords = [
      'bleeding',
      'blood',
      'clot',
      'factor',
      'treatment',
      'medication',
      'symptoms',
      'diagnosis',
      'genetic',
      'inherited',
      'disorder',
      'condition',
      'disease',
      'therapy',
      'infusion',
      'injection',
    ];

    // If query contains medical context and mentions bleeding/blood disorders
    if (medicalContextWords.any((word) => lowerQuery.contains(word))) {
      // Additional check for bleeding/blood-related context
      final bleedingContext = [
        'bleeding',
        'blood',
        'bruise',
        'clot',
        'hemorrhage',
      ];

      if (bleedingContext.any((word) => lowerQuery.contains(word))) {
        return true;
      }
    }

    // Check for common question patterns about medical conditions
    final questionPatterns = [
      'what is',
      'how to',
      'can i',
      'should i',
      'is it safe',
      'treatment for',
      'symptoms of',
      'causes of',
      'prevention of',
      'manage',
      'cope with',
      'deal with',
      'help with',
    ];

    if (questionPatterns.any((pattern) => lowerQuery.contains(pattern))) {
      // If it's a medical question, check if it could be hemophilia-related
      final potentialHemophiliaTerms = [
        'bleeding',
        'bruising',
        'joint pain',
        'swelling',
        'blood disorder',
        'clotting',
        'factor',
      ];

      if (potentialHemophiliaTerms.any((term) => lowerQuery.contains(term))) {
        return true;
      }
    }

    return false;
  }

  // Helper method to check if text contains hemophilia-related keywords
  bool _containsHemophiliaKeywords(String text) {
    final lowerText = text.toLowerCase();

    // Define comprehensive hemophilia-related keywords
    final hemophiliaKeywords = [
      // Direct hemophilia terms
      'hemophilia', 'haemophilia', 'hemophiliac', 'haemophiliac',

      // Types of hemophilia
      'hemophilia a', 'hemophilia b', 'hemophilia c',
      'factor viii', 'factor ix', 'factor xi',
      'von willebrand', 'vwd', 'factor deficiency',

      // Symptoms and conditions
      'bleeding', 'bruising', 'clotting', 'coagulation', 'hemorrhage',
      'internal bleeding', 'joint bleeding', 'muscle bleeding', 'epistaxis',
      'hematoma', 'petechiae', 'ecchymosis', 'prolonged bleeding',
      'excessive bleeding', 'abnormal bleeding', 'gum bleeding',
      'nose bleeding', 'nosebleed',

      // Treatments and medications
      'factor concentrate', 'factor replacement', 'desmopressin', 'ddavp',
      'antifibrinolytic', 'tranexamic acid', 'aminocaproic acid',
      'plasma', 'cryoprecipitate', 'fresh frozen plasma', 'ffp',
      'prophylaxis', 'on-demand treatment', 'infusion',

      // Medical terms
      'coagulation factor', 'blood clotting', 'platelet', 'hemostasis',
      'bleeding disorder', 'inherited bleeding', 'genetic bleeding',
      'bleeding time', 'pt', 'ptt', 'aptt', 'inr',

      // Body parts commonly affected
      'joint', 'knee', 'elbow', 'ankle', 'shoulder', 'hip',
      'muscle', 'brain bleeding', 'intracranial', 'gum', 'gums',

      // Emergency situations
      'head injury', 'trauma', 'surgery', 'dental', 'tooth extraction',
      'emergency', 'first aid', 'urgent care',

      // Related conditions
      'bleeding disorder', 'platelet disorder', 'thrombocytopenia',
      'immune thrombocytopenic purpura', 'itp',
    ];

    // Check if text contains any hemophilia keywords
    return hemophiliaKeywords.any((keyword) => lowerText.contains(keyword));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.red.shade700,
        title: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.smart_toy,
                color: Colors.red.shade700,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HemoAssistant',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.red.shade700,
                  ),
                ),
                Text(
                  'AI Medical Assistant',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.refresh, size: 20),
              ),
              onPressed: () {
                setState(() {
                  _sessionMessages.clear();
                  _hasInitialized = false;
                  _addWelcomeMessage();
                  _hasInitialized = true;
                });
              },
              tooltip: 'Clear chat',
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat Header Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200, width: 1),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'This AI assistant provides health information only. Always consult healthcare professionals for medical decisions.',
                    style: TextStyle(
                      color: Colors.grey.shade700,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Messages Area
          Expanded(
            child: _sessionMessages.isEmpty && !_isLoading
                ? _buildEmptyState()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 20),
                    itemCount: _sessionMessages.length + (_isLoading ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _sessionMessages.length && _isLoading) {
                        return _buildLoadingMessage();
                      }

                      final message = _sessionMessages[index];
                      return _buildMessageBubble(message, index);
                    },
                  ),
          ),

          // Input Area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.red.shade50,
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(Icons.smart_toy, size: 40, color: Colors.red.shade700),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome to HemoAssistant',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Start a conversation to get personalized hemophilia care assistance',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, int index) {
    final isConsecutive =
        index > 0 && _sessionMessages[index - 1].isUser == message.isUser;

    return Container(
      margin: EdgeInsets.only(
        bottom: isConsecutive ? 4 : 16,
        top: index == 0 ? 0 : (isConsecutive ? 0 : 8),
      ),
      child: Column(
        crossAxisAlignment:
            message.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: message.isUser
                ? MainAxisAlignment.end
                : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!message.isUser) ...[
                if (!isConsecutive)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.smart_toy,
                      color: Colors.red.shade700,
                      size: 16,
                    ),
                  )
                else
                  const SizedBox(width: 32),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.75,
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: message.isUser ? Colors.red.shade700 : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(
                        message.isUser ? 20 : (isConsecutive ? 8 : 20),
                      ),
                      topRight: Radius.circular(
                        message.isUser ? (isConsecutive ? 8 : 20) : 20,
                      ),
                      bottomLeft: const Radius.circular(20),
                      bottomRight: const Radius.circular(20),
                    ),
                    border: message.isUser
                        ? null
                        : Border.all(color: Colors.grey.shade200, width: 1),
                  ),
                  child: message.isUser
                      ? Text(
                          message.text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        )
                      : MarkdownBody(
                          data: message.text,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              color: Colors.black87,
                              fontSize: 15,
                              height: 1.5,
                            ),
                            strong: TextStyle(
                              color: Colors.red.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                            em: const TextStyle(fontStyle: FontStyle.italic),
                            listBullet: TextStyle(color: Colors.red.shade700),
                            code: TextStyle(
                              backgroundColor: Colors.grey.shade100,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                ),
              ),
              if (message.isUser) ...[
                const SizedBox(width: 8),
                if (!isConsecutive)
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: Colors.red.shade700,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child:
                        const Icon(Icons.person, color: Colors.white, size: 16),
                  )
                else
                  const SizedBox(width: 32),
              ],
            ],
          ),

          // Timestamp
          if (!isConsecutive) ...[
            const SizedBox(height: 4),
            Padding(
              padding: EdgeInsets.only(
                left: message.isUser ? 0 : 40,
                right: message.isUser ? 40 : 0,
              ),
              child: Text(
                _formatTimestamp(message.timestamp),
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      // Today - show time only
      final hour = timestamp.hour;
      final minute = timestamp.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      return '$displayHour:$minute $period';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      // Yesterday
      return 'Yesterday';
    } else if (now.difference(timestamp).inDays < 7) {
      // This week - show day name
      final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return weekdays[timestamp.weekday - 1];
    } else {
      // Older - show date
      final month = timestamp.month.toString().padLeft(2, '0');
      final day = timestamp.day.toString().padLeft(2, '0');
      return '$month/$day/${timestamp.year}';
    }
  }

  Widget _buildLoadingMessage() {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.red.shade100,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.smart_toy, color: Colors.red.shade700, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.red.shade700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'HemoAssistant is thinking...',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Quick suggestion chips
            if (_sessionMessages.length <= 1) ...[
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildSuggestionChip('What is hemophilia?'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('Treatment options'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('Emergency care'),
                    const SizedBox(width: 8),
                    _buildSuggestionChip('Daily activities'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Input field and send button
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    child: TextField(
                      controller: _textController,
                      maxLines: null,
                      decoration: InputDecoration(
                        hintText: 'Ask me about hemophilia care...',
                        hintStyle: TextStyle(color: Colors.grey.shade500),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: !_isLoading,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: FloatingActionButton(
                    heroTag:
                        "chatbot_send_fab", // Unique tag to avoid conflicts
                    mini: true,
                    backgroundColor: Colors.red.shade700,
                    elevation: 0,
                    onPressed: _isLoading ? null : _sendMessage,
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionChip(String text) {
    return GestureDetector(
      onTap: () {
        _textController.text = text;
        _sendMessage();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade300, width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
