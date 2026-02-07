import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart'; 
import 'ai_service.dart';

class AiChatPage extends StatefulWidget {
  const AiChatPage({super.key});

  @override
  State<AiChatPage> createState() => _AiChatPageState();
}

class _AiChatPageState extends State<AiChatPage> {
  final AiService _aiService = AiService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Stores chat history
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // LOGIC: Send message to Gemini
  void _sendMessage({String? quickQuestion}) async {
    final text = quickQuestion ?? _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _controller.clear();
    _scrollToBottom();

    // Call API
    final response = await _aiService.sendMessage(text);

    setState(() {
      _messages.add({
        'role': 'ai', 
        'text': response ?? "I am having trouble connecting. Try again."
      });
      _isLoading = false;
    });
    _scrollToBottom();
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Custom App Bar
            _buildAppBar(context),
            
            // 2. Chat Area
            Expanded(
              child: _messages.isEmpty 
                  ? _buildQuickQuestions() // Show buttons if chat is empty
                  : _buildChatList(),      // Show chat if messages exist
            ),
            
            // 3. Input Area
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
      decoration: BoxDecoration(
        color: const Color(0xFF2C7C48),
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
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                shape: BoxShape.circle, 
                color: Colors.white24
              ),
              child: const Icon(Icons.arrow_back, color: Colors.white),
            ),
          ),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                'Smart Kisan AI',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontFamily: 'Arimo',
                  fontWeight: FontWeight.bold,
                ),
              ),
               Text(
                'Your Expert Assistant',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontFamily: 'Arimo',
                ),
              ),
            ],
          ),
          const Spacer(),
          if (_isLoading) 
            const SizedBox(
              width: 20, height: 20, 
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
            )
          else 
            const Icon(Icons.auto_awesome, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildQuickQuestions() {
    final quickQuestions = [
      {'q': 'Best fertilizer for rice?', 'icon': Icons.agriculture, 'color': 0xFFDCFCE7, 'text': 0xFF008236},
      {'q': 'Identify this pest', 'icon': Icons.bug_report, 'color': 0xFFFFE2E2, 'text': 0xFFC10007},
      {'q': 'Irrigation for wheat?', 'icon': Icons.water_drop, 'color': 0xFFDBEAFE, 'text': 0xFF1447E6},
      {'q': 'Tomorrow\'s weather?', 'icon': Icons.cloud, 'color': 0xFFFFEDD4, 'text': 0xFFCA3500},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Quick Questions:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
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
          Center(
            child: Column(
              children: [
                Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
                const SizedBox(height: 10),
                Text("Start chatting with Smart Kisan", style: TextStyle(color: Colors.grey[400])),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';
        return Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
            decoration: BoxDecoration(
              color: isUser ? const Color(0xFF2C7C48) : Colors.grey[100],
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: isUser ? const Radius.circular(12) : Radius.zero,
                bottomRight: isUser ? Radius.zero : const Radius.circular(12),
              ),
              border: isUser ? null : Border.all(color: Colors.grey.shade300),
            ),
            child: isUser 
              ? Text(msg['text']!, style: const TextStyle(color: Colors.white))
              : MarkdownBody(data: msg['text']!),
          ),
        );
      },
    );
  }

  Widget _buildInputSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: 'Ask about farming...',
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isLoading ? null : () => _sendMessage(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _isLoading ? Colors.grey : const Color(0xFF2C7C48),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}