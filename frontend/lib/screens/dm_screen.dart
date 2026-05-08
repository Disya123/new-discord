import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndiscord/config/theme.dart';
import 'package:ndiscord/providers/chat_provider.dart';
import 'package:ndiscord/providers/auth_provider.dart';
import 'package:ndiscord/models/message.dart';

class DMScreen extends ConsumerStatefulWidget {
  const DMScreen({super.key});

  @override
  ConsumerState<DMScreen> createState() => _DMScreenState();
}

class _DMScreenState extends ConsumerState<DMScreen> {
  String? _selectedConversationId;
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadDMConversations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Direct Messages')),
      body: Row(
        children: [
          SizedBox(
            width: 280,
            child: ListView.builder(
              itemCount: chatState.dmConversations.length,
              itemBuilder: (context, index) {
                final conv = chatState.dmConversations[index];
                final isSelected = conv.id == _selectedConversationId;
                return ListTile(
                  selected: isSelected,
                  selectedTileColor: AppColors.surfaceLight,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary,
                    child: Text(
                      conv.otherUsername[0].toUpperCase(),
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(
                    conv.otherUsername,
                    style: TextStyle(
                      color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                  subtitle: conv.lastMessage != null
                      ? Text(
                          conv.lastMessage!.content,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        )
                      : null,
                  trailing: conv.unreadCount > 0
                      ? CircleAvatar(
                          radius: 12,
                          backgroundColor: AppColors.red,
                          child: Text(
                            '${conv.unreadCount}',
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                          ),
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedConversationId = conv.id);
                    ref.read(chatProvider.notifier).loadDMMessages(conv.id);
                  },
                );
              },
            ),
          ),
          Container(width: 1, color: AppColors.divider),
          Expanded(
            child: _selectedConversationId != null
                ? Column(
                    children: [
                      Expanded(
                        child: _buildMessageList(chatState, authState),
                      ),
                      _buildInput(),
                    ],
                  )
                : const Center(
                    child: Text('Select a conversation', style: TextStyle(color: AppColors.textMuted)),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(ChatState chatState, AuthState authState) {
    final messages = chatState.dmMessages[_selectedConversationId] ?? [];
    return ListView.builder(
      reverse: true,
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[messages.length - 1 - index];
        final isMine = msg.authorId == authState.user?.id;
        return Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isMine ? AppColors.primary : AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMine)
                  Text(
                    msg.authorUsername,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                Text(
                  msg.content,
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(),
              ),
              onSubmitted: _sendMessage,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.send, color: AppColors.primary),
            onPressed: () => _sendMessage(_messageController.text),
          ),
        ],
      ),
    );
  }

  void _sendMessage(String text) {
    if (text.trim().isEmpty || _selectedConversationId == null) return;
    ref.read(chatProvider.notifier).sendDM(_selectedConversationId!, text.trim());
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
