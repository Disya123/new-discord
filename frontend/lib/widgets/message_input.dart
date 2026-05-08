import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndiscord/config/theme.dart';
import 'package:ndiscord/providers/chat_provider.dart';

class MessageInput extends ConsumerStatefulWidget {
  final String channelId;

  const MessageInput({super.key, required this.channelId});

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final _controller = TextEditingController();
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final typingUsers = chatState.typingUsers[widget.channelId] ?? [];

    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (typingUsers.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '${typingUsers.length} ${typingUsers.length == 1 ? "user is" : "users are"} typing...',
                style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
            ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file, color: AppColors.textMuted),
                onPressed: () {},
              ),
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(
                    hintText: 'Message #${widget.channelId}',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onChanged: _onTextChanged,
                  onSubmitted: _sendMessage,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send, color: AppColors.primary),
                onPressed: () => _sendMessage(_controller.text),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _onTextChanged(String text) {
    if (text.isNotEmpty && !_isTyping) {
      _isTyping = true;
      ref.read(chatProvider.notifier).startTyping(widget.channelId);
    }

    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      if (_isTyping) {
        _isTyping = false;
        ref.read(chatProvider.notifier).stopTyping(widget.channelId);
      }
    });
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty) return;
    ref.read(chatProvider.notifier).sendMessage(widget.channelId, text.trim());
    _controller.clear();
    _isTyping = false;
    _typingTimer?.cancel();
  }

  @override
  void dispose() {
    _controller.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }
}
