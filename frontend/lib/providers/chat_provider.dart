import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndiscord/services/api_service.dart';
import 'package:ndiscord/services/ws_service.dart';
import 'package:ndiscord/models/message.dart';

class ChatState {
  final Map<String, List<Message>> channelMessages;
  final Map<String, List<DMMessage>> dmMessages;
  final List<DMConversation> dmConversations;
  final Map<String, List<String>> typingUsers;
  final bool isLoading;

  ChatState({
    this.channelMessages = const {},
    this.dmMessages = const {},
    this.dmConversations = const [],
    this.typingUsers = const {},
    this.isLoading = false,
  });

  ChatState copyWith({
    Map<String, List<Message>>? channelMessages,
    Map<String, List<DMMessage>>? dmMessages,
    List<DMConversation>? dmConversations,
    Map<String, List<String>>? typingUsers,
    bool? isLoading,
  }) {
    return ChatState(
      channelMessages: channelMessages ?? this.channelMessages,
      dmMessages: dmMessages ?? this.dmMessages,
      dmConversations: dmConversations ?? this.dmConversations,
      typingUsers: typingUsers ?? this.typingUsers,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ChatNotifier extends StateNotifier<ChatState> {
  final ApiService _api = ApiService();
  final WebSocketService _ws;

  ChatNotifier(this._ws) : super(ChatState()) {
    _ws.addHandler(_handleWsMessage);
  }

  void _handleWsMessage(Map<String, dynamic> data) {
    final type = data['type'] as String?;

    if (type == 'new_message') {
      _handleNewMessage(data['message']);
    } else if (type == 'new_dm_message') {
      _handleNewDMMessage(data['message']);
    } else if (type == 'typing_start') {
      _handleTypingStart(data);
    } else if (type == 'typing_stop') {
      _handleTypingStop(data);
    }
  }

  void _handleNewMessage(Map<String, dynamic> data) {
    final message = Message.fromJson(data);
    final channelId = message.channelId;
    final messages = Map<String, List<Message>>.from(state.channelMessages);
    messages[channelId] = [...(messages[channelId] ?? []), message];
    state = state.copyWith(channelMessages: messages);
  }

  void _handleNewDMMessage(Map<String, dynamic> data) {
    final message = DMMessage.fromJson(data);
    final convId = message.conversationId;
    final messages = Map<String, List<DMMessage>>.from(state.dmMessages);
    messages[convId] = [...(messages[convId] ?? []), message];
    state = state.copyWith(dmMessages: messages);
  }

  void _handleTypingStart(Map<String, dynamic> data) {
    final channelId = data['channel_id'] as String;
    final userId = data['user_id'] as String;
    final typing = Map<String, List<String>>.from(state.typingUsers);
    typing[channelId] = [...(typing[channelId] ?? []), userId];
    state = state.copyWith(typingUsers: typing);
  }

  void _handleTypingStop(Map<String, dynamic> data) {
    final channelId = data['channel_id'] as String;
    final userId = data['user_id'] as String;
    final typing = Map<String, List<String>>.from(state.typingUsers);
    typing[channelId] = (typing[channelId] ?? []).where((id) => id != userId).toList();
    state = state.copyWith(typingUsers: typing);
  }

  Future<void> loadMessages(String channelId) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _api.getList('/channels/$channelId/messages');
      final messages = data.map((m) => Message.fromJson(m)).toList().reversed.toList();
      final allMessages = Map<String, List<Message>>.from(state.channelMessages);
      allMessages[channelId] = messages;
      state = state.copyWith(channelMessages: allMessages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> loadDMConversations() async {
    try {
      final data = await _api.getList('/dm/conversations');
      final conversations = data.map((c) => DMConversation.fromJson(c)).toList();
      state = state.copyWith(dmConversations: conversations);
    } catch (e) {}
  }

  Future<void> loadDMMessages(String conversationId) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _api.getList('/dm/conversations/$conversationId/messages');
      final messages = data.map((m) => DMMessage.fromJson(m)).toList().reversed.toList();
      final allMessages = Map<String, List<DMMessage>>.from(state.dmMessages);
      allMessages[conversationId] = messages;
      state = state.copyWith(dmMessages: allMessages, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  void sendMessage(String channelId, String content) {
    _ws.sendChatMessage(channelId, content);
  }

  void sendDM(String conversationId, String content) {
    _ws.sendDMMessage(conversationId, content);
  }

  void startTyping(String channelId) {
    _ws.startTyping(channelId);
  }

  void stopTyping(String channelId) {
    _ws.stopTyping(channelId);
  }

  List<Message> getMessages(String channelId) {
    return state.channelMessages[channelId] ?? [];
  }

  List<DMMessage> getDMMessages(String conversationId) {
    return state.dmMessages[conversationId] ?? [];
  }
}

final wsServiceProvider = Provider<WebSocketService>((ref) {
  return WebSocketService();
});

final chatProvider = StateNotifierProvider<ChatNotifier, ChatState>((ref) {
  final ws = ref.watch(wsServiceProvider);
  return ChatNotifier(ws);
});
