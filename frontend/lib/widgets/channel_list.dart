import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndiscord/config/theme.dart';
import 'package:ndiscord/providers/server_provider.dart';
import 'package:ndiscord/providers/voice_provider.dart';
import 'package:ndiscord/models/server.dart';
import 'package:ndiscord/models/channel.dart';

class ChannelList extends ConsumerWidget {
  final Server server;

  const ChannelList({super.key, required this.server});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final serverState = ref.watch(serverProvider);
    final voiceState = ref.watch(voiceProvider);

    final textChannels = serverState.channels.where((c) => c.isText).toList();
    final voiceChannels = serverState.channels.where((c) => c.isVoice).toList();

    return Container(
      width: 240,
      color: AppColors.surface,
      child: Column(
        children: [
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    server.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                if (textChannels.isNotEmpty) ...[
                  _SectionHeader(title: 'TEXT CHANNELS', onAdd: () => _showCreateChannel(context, ref, 'text')),
                  ...textChannels.map((ch) => _ChannelTile(
                        channel: ch,
                        isSelected: serverState.selectedChannel?.id == ch.id,
                        onTap: () => ref.read(serverProvider.notifier).selectChannel(ch),
                      )),
                ],
                if (voiceChannels.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _SectionHeader(title: 'VOICE CHANNELS', onAdd: () => _showCreateChannel(context, ref, 'voice')),
                  ...voiceChannels.map((ch) => _VoiceChannelTile(
                        channel: ch,
                        isInVoice: voiceState.currentVoiceChannelId == ch.id,
                        onTap: () {
                          if (voiceState.isInVoiceChannel) {
                            ref.read(voiceProvider.notifier).leaveVoiceChannel();
                          } else {
                            ref.read(voiceProvider.notifier).joinVoiceChannel(ch.id);
                          }
                        },
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateChannel(BuildContext context, WidgetRef ref, String type) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Create ${type == "text" ? "Text" : "Voice"} Channel', style: const TextStyle(color: AppColors.textPrimary)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(hintText: 'channel-name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(serverProvider.notifier).createChannel(server.id, nameController.text, type);
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onAdd;

  const _SectionHeader({required this.title, this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          if (onAdd != null)
            GestureDetector(
              onTap: onAdd,
              child: const Icon(Icons.add, color: AppColors.textMuted, size: 18),
            ),
        ],
      ),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  final bool isSelected;
  final VoidCallback onTap;

  const _ChannelTile({
    required this.channel,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: isSelected,
      selectedTileColor: AppColors.surfaceLight,
      leading: const Icon(Icons.tag, color: AppColors.textMuted, size: 20),
      title: Text(
        channel.name,
        style: TextStyle(
          color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _VoiceChannelTile extends StatelessWidget {
  final Channel channel;
  final bool isInVoice;
  final VoidCallback onTap;

  const _VoiceChannelTile({
    required this.channel,
    required this.isInVoice,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      selected: isInVoice,
      selectedTileColor: AppColors.surfaceLight,
      leading: Icon(
        isInVoice ? Icons.volume_up : Icons.volume_up_outlined,
        color: isInVoice ? AppColors.green : AppColors.textMuted,
        size: 20,
      ),
      title: Text(
        channel.name,
        style: TextStyle(
          color: isInVoice ? AppColors.green : AppColors.textSecondary,
          fontWeight: isInVoice ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      onTap: onTap,
    );
  }
}
