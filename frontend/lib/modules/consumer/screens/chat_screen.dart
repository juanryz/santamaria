import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/glass_widget.dart';
import '../../../shared/widgets/glass_app_bar.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ApiClient _api = ApiClient();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isSending = false;

  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content':
          'Halo, saya asisten Santa Maria. Saya turut berbelasungkawa atas kehilangan yang Anda alami. Izinkan saya membantu Anda menyiapkan segala keperluan di saat sulit ini.\n\nSilakan ceritakan kebutuhan Anda, atau saya bisa membantu mengisi formulir pemesanan layanan.',
    }
  ];

  Map<String, dynamic>? _suggestedOrderData;

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

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _controller.clear();
      _isSending = true;
      _suggestedOrderData = null;
    });
    _scrollToBottom();

    try {
      final res = await _api.dio.post('/consumer/ai/chat', data: {
        'message': text,
        'history': _messages
            .map((m) => {'role': m['role'], 'content': m['content']})
            .toList(),
      });

      if (res.data['success'] == true) {
        final reply = res.data['data']?['message'] ?? res.data['data']?['reply'] ?? 'Maaf, saya tidak bisa memproses permintaan Anda.';
        setState(() {
          _messages.add({'role': 'assistant', 'content': reply});
        });
        // Check if AI returned suggested order data
        if (res.data['data']?['order_data'] != null) {
          setState(() {
            _suggestedOrderData = Map<String, dynamic>.from(res.data['data']['order_data']);
          });
        }
      } else {
        setState(() {
          _messages.add({'role': 'assistant', 'content': 'Maaf, terjadi kesalahan. Silakan coba lagi.'});
        });
      }
    } catch (_) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Maaf, tidak dapat terhubung ke server. Silakan coba lagi nanti.'});
      });
    }

    if (mounted) setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _useOrderData() {
    if (_suggestedOrderData != null) {
      Navigator.pop(context, _suggestedOrderData);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GlassAppBar(
        title: 'Santa Maria AI',
        accentColor: AppColors.roleConsumer,
        showBack: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              itemCount: _messages.length + (_suggestedOrderData != null ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _buildBubble(_messages[index]);
                }
                // Suggested order data card
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassWidget(
                    borderRadius: 16,
                    tint: AppColors.statusSuccess.withValues(alpha: 0.08),
                    borderColor: AppColors.statusSuccess.withValues(alpha: 0.25),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Data order terisi dari percakapan:',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 8),
                          ..._suggestedOrderData!.entries
                              .where((e) => e.value != null && e.value.toString().isNotEmpty)
                              .map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Text('${e.key}: ${e.value}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                                  )),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _useOrderData,
                              icon: const Icon(Icons.check, size: 18),
                              label: const Text('Gunakan data ini untuk order'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.statusSuccess,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isSending)
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
            ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isUser = msg['role'] == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: GlassWidget(
          borderRadius: 16,
          tint: isUser
              ? AppColors.roleConsumer.withValues(alpha: 0.12)
              : AppColors.glassWhite,
          borderColor: isUser
              ? AppColors.roleConsumer.withValues(alpha: 0.25)
              : AppColors.glassBorder,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Text(
              msg['content'] ?? '',
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.4),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      child: GlassWidget(
        borderRadius: 28,
        tint: AppColors.glassWhite,
        borderColor: AppColors.glassBorder,
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Ketik pesan Anda...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.roleConsumer),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
