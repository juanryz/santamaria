import 'package:flutter/material.dart';
import '../../../core/theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content': 'Halo, saya asisten Santa Maria. Saya turut berbelasungkawa atas kehilangan yang Anda alami. Izinkan saya membantu Anda menyiapkan segala keperluan di saat sulit ini. Siapa nama lengkap almarhum/almarhumah?',
    }
  ];
  final TextEditingController _controller = TextEditingController();

  void _sendMessage() {
    if (_controller.text.isEmpty) return;
    setState(() {
      _messages.add({
        'role': 'user',
        'content': _controller.text,
      });
      _controller.clear();
      // Logic for API call to backend AI would go here
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF10002B), Color(0xFF240046), Color(0xFF3C096C)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(child: _buildChatList()),
              _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: AppTheme.accent,
            child: Icon(Icons.support_agent, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Santa Maria AI', style: AppTheme.darkTheme.textTheme.titleLarge),
              const Text('Asisten Empati', style: TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white70),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final msg = _messages[index];
        final isUser = msg['role'] == 'user';

        return UnconstrainedBox(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            child: GlassContainer(
              opacity: isUser ? 0.2 : 0.1,
              padding: const EdgeInsets.all(16),
              borderRadius: isUser 
                ? const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20), topRight: Radius.circular(20))
                : const BorderRadius.only(topLeft: Radius.circular(20), bottomRight: Radius.circular(20), topRight: Radius.circular(20)),
              child: Text(msg['content'], style: const TextStyle(color: Colors.white, fontSize: 15)),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GlassContainer(
        borderRadius: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.mic, color: AppTheme.accent),
              onPressed: () {}, // Voice integration
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Ketik pesan Anda...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppTheme.accent),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
