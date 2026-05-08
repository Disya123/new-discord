import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:ndiscord/config/api_config.dart';

typedef MessageHandler = void Function(Map<String, dynamic> data);

class WebSocketService {
  WebSocketChannel? _channel;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final List<MessageHandler> _handlers = [];
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  bool _intentionalClose = false;
  int _reconnectAttempts = 0;

  void addHandler(MessageHandler handler) {
    _handlers.add(handler);
  }

  void removeHandler(MessageHandler handler) {
    _handlers.remove(handler);
  }

  Future<void> connect() async {
    final token = await _storage.read(key: 'access_token');
    if (token == null) return;

    _intentionalClose = false;
    final url = ApiConfig.wsUrlWithToken(token);

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      _reconnectAttempts = 0;

      _channel!.stream.listen(
        (data) {
          final decoded = jsonDecode(data);
          for (final handler in _handlers) {
            handler(decoded);
          }
        },
        onDone: () {
          _stopPing();
          if (!_intentionalClose) {
            _scheduleReconnect();
          }
        },
        onError: (error) {
          _stopPing();
          if (!_intentionalClose) {
            _scheduleReconnect();
          }
        },
      );

      _startPing();
    } catch (e) {
      _scheduleReconnect();
    }
  }

  void _startPing() {
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      send({'type': 'ping'});
    });
  }

  void _stopPing() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }

  void _scheduleReconnect() {
    _reconnectAttempts++;
    final delay = Duration(seconds: (_reconnectAttempts * 2).clamp(2, 30));
    _reconnectTimer = Timer(delay, () {
      connect();
    });
  }

  void send(Map<String, dynamic> data) {
    _channel?.sink.add(jsonEncode(data));
  }

  void subscribeChannel(String channelId) {
    send({'type': 'subscribe_channel', 'channel_id': channelId});
  }

  void unsubscribeChannel(String channelId) {
    send({'type': 'unsubscribe_channel', 'channel_id': channelId});
  }

  void sendChatMessage(String channelId, String content, {bool encrypted = false, String? replyToId}) {
    send({
      'type': 'chat_message',
      'channel_id': channelId,
      'content': content,
      'encrypted': encrypted,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
  }

  void sendDMMessage(String conversationId, String content, {bool encrypted = false}) {
    send({
      'type': 'dm_message',
      'conversation_id': conversationId,
      'content': content,
      'encrypted': encrypted,
    });
  }

  void startTyping(String channelId) {
    send({'type': 'typing_start', 'channel_id': channelId});
  }

  void stopTyping(String channelId) {
    send({'type': 'typing_stop', 'channel_id': channelId});
  }

  void joinVoiceChannel(String channelId) {
    send({'type': 'join_voice', 'channel_id': channelId});
  }

  void leaveVoiceChannel(String channelId) {
    send({'type': 'leave_voice', 'channel_id': channelId});
  }

  void sendWebRTCSignal(String targetUserId, Map<String, dynamic> signal) {
    send({
      'type': 'webrtc_signal',
      'target_user_id': targetUserId,
      'signal': signal,
    });
  }

  void disconnect() {
    _intentionalClose = true;
    _stopPing();
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
  }

  bool get isConnected => _channel != null;
}
