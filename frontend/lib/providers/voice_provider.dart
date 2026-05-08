import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndiscord/services/webrtc_service.dart';
import 'package:ndiscord/services/ws_service.dart';
import 'package:ndiscord/providers/chat_provider.dart';

class VoiceState {
  final bool isInVoiceChannel;
  final bool isMuted;
  final bool isDeafened;
  final bool isScreenSharing;
  final String? currentVoiceChannelId;
  final Map<String, dynamic> remoteStreams;

  VoiceState({
    this.isInVoiceChannel = false,
    this.isMuted = false,
    this.isDeafened = false,
    this.isScreenSharing = false,
    this.currentVoiceChannelId,
    this.remoteStreams = const {},
  });

  VoiceState copyWith({
    bool? isInVoiceChannel,
    bool? isMuted,
    bool? isDeafened,
    bool? isScreenSharing,
    String? currentVoiceChannelId,
    Map<String, dynamic>? remoteStreams,
  }) {
    return VoiceState(
      isInVoiceChannel: isInVoiceChannel ?? this.isInVoiceChannel,
      isMuted: isMuted ?? this.isMuted,
      isDeafened: isDeafened ?? this.isDeafened,
      isScreenSharing: isScreenSharing ?? this.isScreenSharing,
      currentVoiceChannelId: currentVoiceChannelId ?? this.currentVoiceChannelId,
      remoteStreams: remoteStreams ?? this.remoteStreams,
    );
  }
}

class VoiceNotifier extends StateNotifier<VoiceState> {
  final WebRTCService _webrtc;
  final WebSocketService _ws;

  VoiceNotifier(this._webrtc, this._ws) : super(VoiceState());

  Future<void> joinVoiceChannel(String channelId) async {
    await _webrtc.initialize();
    await _webrtc.startLocalAudio();
    _ws.joinVoiceChannel(channelId);
    state = state.copyWith(isInVoiceChannel: true, currentVoiceChannelId: channelId);
  }

  Future<void> leaveVoiceChannel() async {
    if (state.currentVoiceChannelId != null) {
      _ws.leaveVoiceChannel(state.currentVoiceChannelId!);
    }
    await _webrtc.stopAll();
    state = state.copyWith(
      isInVoiceChannel: false,
      currentVoiceChannelId: null,
      isMuted: false,
      isDeafened: false,
      isScreenSharing: false,
    );
  }

  Future<void> toggleMute() async {
    final newMuted = !state.isMuted;
    await _webrtc.muteAudio(newMuted);
    state = state.copyWith(isMuted: newMuted);
  }

  Future<void> toggleDeafen() async {
    final newDeafened = !state.isDeafened;
    if (newDeafened) {
      await _webrtc.muteAudio(true);
    } else {
      await _webrtc.muteAudio(state.isMuted);
    }
    state = state.copyWith(isDeafened: newDeafened);
  }

  Future<void> toggleScreenShare() async {
    if (state.isScreenSharing) {
      state = state.copyWith(isScreenSharing: false);
    } else {
      await _webrtc.startScreenShare();
      state = state.copyWith(isScreenSharing: true);
    }
  }

  Future<void> callUser(String userId) async {
    await _webrtc.call(userId);
  }
}

final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  final ws = ref.watch(wsServiceProvider);
  return WebRTCService(ws);
});

final voiceProvider = StateNotifierProvider<VoiceNotifier, VoiceState>((ref) {
  final webrtc = ref.watch(webrtcServiceProvider);
  final ws = ref.watch(wsServiceProvider);
  return VoiceNotifier(webrtc, ws);
});
