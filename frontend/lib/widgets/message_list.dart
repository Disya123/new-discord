import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndiscord/config/theme.dart';
import 'package:ndiscord/providers/chat_provider.dart';
import 'package:ndiscord/providers/auth_provider.dart';
import 'package:ndiscord/models/message.dart';
import 'package:intl/intl.dart';

class MessageList extends ConsumerStatefulWidget {
  final String channelId;

  const MessageList({super.key, required this.channelId});

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(chatProvider.notifier).loadMessages(widget.channelId);
    });
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId) {
      ref.read(chatProvider.notifier).loadMessages(widget.channelId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatProvider);
    final authState = ref.watch(authProvider);
    final messages = chatState.channelMessages[widget.channelId] ?? [];

    if (chatState.isLoading && messages.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tag, size: 64, color: AppColors.textMuted),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(color: AppColors.textMuted, fontSize: 18),
            ),
            SizedBox(height: 8),
            Text(
              'Be the first to send a message!',
              style: TextStyle(color: AppColors.textMuted, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final msg = messages[messages.length - 1 - index];
        final isMine = msg.authorId == authState.user?.id;
        final showHeader = index == messages.length - 1 ||
            messages[messages.length - 1 - index - 1].authorId != msg.authorId ||
            msg.createdAt!.difference(messages[messages.length - 1 - index - 1].createdAt!).inMinutes > 5;

        return _MessageTile(
          message: msg,
          isMine: isMine,
          showHeader: showHeader,
        );
      },
    );
  }
}

class _MessageTile extends StatelessWidget {
  final Message message;
  final bool isMine;
  final bool showHeader;

  const _MessageTile({
    required this.message,
    required this.isMine,
    required this.showHeader,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: showHeader
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary,
                  backgroundImage: message.authorAvatar != null
                      ? NetworkImage(message.authorAvatar!)
                      : null,
                  child: message.authorAvatar == null
                      ? Text(
                          message.authorUsername[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        )
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            message.authorUsername,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('HH:mm').format(message.createdAt!),
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        message.content,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
                      ),
                      if (message.editedAt != null)
                        const Text('(edited)', style: TextStyle(color: AppColors.textMuted, fontSize: 11)),
                    ],
                  ),
                ),
              ],
            )
          : Padding(
              padding: const EdgeInsets.only(left: 56),
              child: Text(
                message.content,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),
            ),
    );
  }
}
