import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'ai_service.dart';
import 'localization_service.dart';

/// [AiChatPage] is a stateful widget that provides a chat interface for users
/// to interact with the Smart Kisan AI.
/// It displays a scrollable list of messages and an input field for new queries.
/// It interacts with [AiService] for fetching AI responses and [FirebaseFirestore]
/// for storing chat history.
class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  // Instance of the AI service to handle API calls to Gemini.
  final AiService _aiService = AiService();
  
  // Controller to manage the text input field state.
  final TextEditingController _controller = TextEditingController();
  
  // Controller to manage the scroll position of the chat list view.
  final ScrollController _scrollController = ScrollController();
  
  /// List of chat messages where each map contains a 'role' (user/ai) and 'text'.
  /// This acts as the local state for the UI before pushing to/from Firestore.
  final List<Map<String, String>> _messages = [];
  
  // Boolean flags to manage UI loading states (spinners).
  bool _isLoading = false;
  bool _isLoadingHistory = true;

  // Helper function for quick translation lookups.
  String tr(String key) => LocalizationService.translate(key);

  /// Purpose: Initializes the state of the chat page when it is first created.
  /// Inputs: None.
  /// Outputs: None directly, but triggers the asynchronous history fetch.
  @override
  void initState() {
    super.initState();
    // 1. Kick off the asynchronous fetch for previous chat messages.
    _loadChatHistory();
  }

  /// Purpose: Fetches the user's past conversation history from Firestore.
  /// Inputs: None.
  /// Outputs: Updates the internal [_messages] list and refreshes the UI.
  Future<void> _loadChatHistory() async {
    // 1. Identify the currently authenticated user.
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      // If not logged in, stop loading and return early.
      if (mounted) setState(() => _isLoadingHistory = false);
      return;
    }
    
    try {
      // 2. Query Firestore for this specific user's 'aiChats' subcollection, ordering by timestamp.
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('aiChats')
          .orderBy('timestamp', descending: false)
          .get();
      
      // 3. Ensure the widget is still in the tree before calling setState.
      if (mounted) {
        setState(() {
          _messages.clear(); // Clear local state to prevent duplicates.
          
          // 4. Iterate through the retrieved Firestore documents.
          for (var doc in snapshot.docs) {
            final data = doc.data();
            // Extract role and text, providing defaults if fields are missing.
            _messages.add({
              'role': data['role'] as String? ?? 'user',
              'text': data['text'] as String? ?? '',
            });
          }
          // Turn off the loading spinner since history is successfully fetched.
          _isLoadingHistory = false;
        });
        
        // 5. Scroll the view down to show the most recent message.
        _scrollToBottom();
      }
    } catch (e) {
      // Catch and log any database read errors.
      print("Error loading chat history: $e");
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  /// Purpose: Saves a single chat message (either from the user or AI) to the Firestore database.
  /// Inputs: [role] - 'user' or 'ai'. [text] - the content of the message.
  /// Outputs: A Future completing when the write operation finishes.
  Future<void> _saveMessageToFirestore(String role, String text) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    
    try {
      // Write a new document to the user's aiChats subcollection.
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('aiChats')
          .add({
        'role': role,
        'text': text,
        // Use serverTimestamp to ensure chronological sorting is immune to local device clock skew.
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error saving message: $e");
    }
  }

  /// Purpose: Cleans up resources when the widget is removed from the tree.
  /// Inputs: None.
  /// Outputs: None.
  @override
  void dispose() {
    // Free up memory consumed by the text and scroll controllers.
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Purpose: Handles the user's input, updates the UI, sends the query to the AI, and saves to Firestore.
  /// Inputs: Optional [quickQuestion] string if triggered by a suggestion button.
  /// Outputs: Updates local state and remote database with both query and response.
  void _sendMessage({String? quickQuestion}) async {
    // 1. Determine if the message came from a quick button or the text input field.
    final text = quickQuestion ?? _controller.text.trim();
    if (text.isEmpty) return; // Prevent sending blank messages.

    // 2. Optimistically update the UI immediately with the user's query.
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true; // Show loading indicator on the send button.
    });
    
    // Clear the input field and scroll down.
    _controller.clear();
    _scrollToBottom();

    // 3. Save the user's query to the permanent Firestore database.
    _saveMessageToFirestore('user', text);

    // 4. Call the AI Service API, passing the *entire* conversation history for context.
    final response = await _aiService.sendMessageWithHistory(_messages);

    // 5. Handle the API response, providing a fallback error message if it failed.
    final aiResponseText = response ?? tr('I am having trouble connecting. Try again.');

    // 6. Update the UI with the newly received AI response.
    setState(() {
      _messages.add({
        'role': 'ai', 
        'text': aiResponseText
      });
      _isLoading = false; // Hide loading indicator.
    });
    _scrollToBottom();

    // 7. Save the AI's response back to the Firestore database.
    _saveMessageToFirestore('ai', aiResponseText);
  }

  /// Purpose: Forces the ListView to scroll to the very bottom of the chat.
  /// Inputs: None.
  /// Outputs: Animates the scroll controller.
  void _scrollToBottom() {
    // Use addPostFrameCallback to ensure the widget tree has fully rebuilt with the new message before scrolling.
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

  /// Purpose: Constructs the main visual tree for the Chat Page screen.
  /// Inputs: [context].
  /// Outputs: A Scaffold widget containing the app bar, chat list, and input field.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).scaffoldBackgroundColor : const Color(0xFFF0FDF4),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Custom App Bar
            _buildAppBar(context),
            
            // 2. Chat Area
            Expanded(
              child: _isLoadingHistory 
                  // Show a spinner if fetching initial history.
                  ? const Center(child: CircularProgressIndicator())
                  : _messages.isEmpty 
                      // If no messages exist yet, show the suggestion buttons.
                      ? _buildQuickQuestions() 
                      // Otherwise, render the list of chat bubbles.
                      : _buildChatList(),      
            ),
            
            // 3. Input Area
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  /// Purpose: Builds a custom stylized app bar for the chat screen.
  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 6,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button logic
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle, 
                color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).dividerColor.withOpacity(0.1) : Colors.white.withOpacity(0.2)
              ),
              child: Icon(Icons.arrow_back, color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.primary : Colors.white),
            ),
          ),
          const SizedBox(width: 15),
          // Title Text
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                tr('Smart Kisan AI'),
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyLarge?.color : Colors.white,
                  fontSize: 20,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.bold,
                ),
              ),
               Text(
                tr('Your Expert Assistant'),
                style: TextStyle(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).textTheme.bodyMedium?.color : Colors.white.withOpacity(0.9),
                  fontSize: 12,
                  fontFamily: 'Arimo',
                ),
              ),
            ],
          ),
          Spacer(),
          // Dynamic icon: Shows a loading spinner if AI is thinking, otherwise shows a static icon.
          if (_isLoading) 
            SizedBox(
              width: 20, height: 20, 
              child: CircularProgressIndicator(color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.primary : Colors.white, strokeWidth: 2)
            )
          else 
            Icon(Icons.auto_awesome, color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).colorScheme.primary : Colors.white),
        ],
      ),
    );
  }

  /// Purpose: Renders suggestion chips for new users when the chat history is empty.
  Widget _buildQuickQuestions() {
    // TODO: Refactor for production - Hardcoded quick question values and colors.
    // Consider moving these to a remote configuration or a dedicated constants file.
    final quickQuestions = [
      {'q': tr('Best fertilizer for rice?'), 'icon': Icons.agriculture, 'color': 0xFFDCFCE7, 'text': 0xFF008236},
      {'q': tr('Identify this pest'), 'icon': Icons.bug_report, 'color': 0xFFFFE2E2, 'text': 0xFFC10007},
      {'q': tr('Irrigation for wheat?'), 'icon': Icons.water_drop, 'color': 0xFFDBEAFE, 'text': 0xFF1447E6},
      {'q': tr('Tomorrow\'s weather?'), 'icon': Icons.cloud, 'color': 0xFFFFEDD4, 'text': 0xFFCA3500},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr("Quick Questions:"), style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          // Uses a GridView to display the chips in a responsive 2-column layout.
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 2.5
            ),
            itemCount: quickQuestions.length,
            itemBuilder: (context, index) {
              final item = quickQuestions[index];
              return GestureDetector(
                // Triggers _sendMessage directly using the pre-defined string when tapped.
                onTap: () => _sendMessage(quickQuestion: item['q'] as String),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Color(item['color'] as int),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(item['icon'] as IconData, color: Color(item['text'] as int), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item['q'] as String,
                          style: TextStyle(color: Color(item['text'] as int), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 30),
          // Placeholder graphic for empty state.
          Center(
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text(tr("Start chatting with Smart Kisan"), style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          )
        ],
      ),
    );
  }

  /// Purpose: Renders the list of conversational message bubbles.
  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        
        // Dynamically align the bubble to the right (for user) or left (for AI).
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            // Restrict maximum width to 80% of screen so bubbles don't stretch fully across.
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: isUser ? Theme.of(context).colorScheme.primary : Theme.of(context).cardColor,
              // Round all corners except the one pointing towards the sender side.
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                bottomRight: isUser ? Radius.zero : const Radius.circular(12),
              ),
              border: isUser ? null : Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
            ),
            child: isUser 
              // User text is simple.
              ? Text(msg['text']!, style: TextStyle(color: Theme.of(context).colorScheme.onPrimary))
              // AI text is rendered via MarkdownBody to correctly display bolding and bullet points returned by Gemini.
              : MarkdownBody(data: msg['text']!),
          ),
        );
      },
    );
  }

  /// Purpose: Renders the text input field and send button at the bottom of the screen.
  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white,
          border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1))),
        ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                  hintText: tr('Ask about farming...'),
                  hintStyle: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  filled: true,
                  fillColor: Theme.of(context).colorScheme.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10), 
                    borderSide: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.1)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
              // Triggers the send logic when the user hits 'Enter' on their keyboard.
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            // Disable the tap if an API request is already in progress (_isLoading is true).
            onTap: _isLoading ? null : () => _sendMessage(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.send, color: Theme.of(context).brightness == Brightness.dark ? Theme.of(context).cardColor : Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}