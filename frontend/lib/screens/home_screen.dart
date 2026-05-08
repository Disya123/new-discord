import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndiscord/config/theme.dart';
import 'package:ndiscord/providers/auth_provider.dart';
import 'package:ndiscord/providers/server_provider.dart';
import 'package:ndiscord/providers/chat_provider.dart';
import 'package:ndiscord/providers/voice_provider.dart';
import 'package:ndiscord/widgets/server_list.dart';
import 'package:ndiscord/widgets/channel_list.dart';
import 'package:ndiscord/widgets/message_list.dart';
import 'package:ndiscord/widgets/message_input.dart';
import 'package:ndiscord/widgets/member_list.dart';
import 'package:ndiscord/widgets/voice_controls.dart';
import 'package:ndiscord/screens/dm_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ws = ref.read(wsServiceProvider);
      ws.connect();
    });
  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(serverProvider);
    final voiceState = ref.watch(voiceProvider);

    return Scaffold(
      body: Row(
        children: [
          ServerList(
            onDMSelected: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DMScreen()),
              );
            },
          ),
          Container(width: 1, color: AppColors.divider),
          if (serverState.selectedServer != null) ...[
            ChannelList(server: serverState.selectedServer!),
            Container(width: 1, color: AppColors.divider),
          ],
          Expanded(
            child: Column(
              children: [
                if (serverState.selectedChannel != null)
                  Container(
                    height: 48,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      border: Border(bottom: BorderSide(color: AppColors.divider)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.tag, color: AppColors.textMuted, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          serverState.selectedChannel!.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        if (serverState.selectedChannel!.topic != null) ...[
                          const SizedBox(width: 16),
                          Container(width: 1, height: 24, color: AppColors.divider),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              serverState.selectedChannel!.topic!,
                              style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                        IconButton(
                          icon: const Icon(Icons.people, color: AppColors.textMuted),
                          onPressed: () {
                            if (serverState.selectedServer != null) {
                              ref.read(serverProvider.notifier).loadMembers(serverState.selectedServer!.id);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            Expanded(
                              child: serverState.selectedChannel != null
                                  ? MessageList(channelId: serverState.selectedChannel!.id)
                                  : const Center(child: Text('Select a channel', style: TextStyle(color: AppColors.textMuted))),
                            ),
                            if (serverState.selectedChannel != null)
                              MessageInput(channelId: serverState.selectedChannel!.id),
                          ],
                        ),
                      ),
                      if (serverState.members.isNotEmpty)
                        MemberList(members: serverState.members),
                    ],
                  ),
                ),
                if (voiceState.isInVoiceChannel)
                  const VoiceControls(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
