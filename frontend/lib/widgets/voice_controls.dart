import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndiscord/config/theme.dart';
import 'package:ndiscord/providers/voice_provider.dart';

class VoiceControls extends ConsumerWidget {
  const VoiceControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final voiceState = ref.watch(voiceProvider);

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surfaceLight,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          const Icon(Icons.volume_up, color: AppColors.green, size: 20),
          const SizedBox(width: 8),
          const Text(
            'Voice Connected',
            style: TextStyle(color: AppColors.green, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              voiceState.isMuted ? Icons.mic_off : Icons.mic,
              color: voiceState.isMuted ? AppColors.red : AppColors.textPrimary,
            ),
            onPressed: () => ref.read(voiceProvider.notifier).toggleMute(),
            tooltip: voiceState.isMuted ? 'Unmute' : 'Mute',
          ),
          IconButton(
            icon: Icon(
              voiceState.isDeafened ? Icons.headset_off : Icons.headset,
              color: voiceState.isDeafened ? AppColors.red : AppColors.textPrimary,
            ),
            onPressed: () => ref.read(voiceProvider.notifier).toggleDeafen(),
            tooltip: voiceState.isDeafened ? 'Undeafen' : 'Deafen',
          ),
          IconButton(
            icon: Icon(
              voiceState.isScreenSharing ? Icons.stop_screen_share : Icons.screen_share,
              color: voiceState.isScreenSharing ? AppColors.green : AppColors.textPrimary,
            ),
            onPressed: () => ref.read(voiceProvider.notifier).toggleScreenShare(),
            tooltip: voiceState.isScreenSharing ? 'Stop Sharing' : 'Share Screen',
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.call_end, color: AppColors.red),
            onPressed: () => ref.read(voiceProvider.notifier).leaveVoiceChannel(),
            tooltip: 'Disconnect',
          ),
        ],
      ),
    );
  }
}
