import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ndiscord/services/api_service.dart';
import 'package:ndiscord/models/server.dart';
import 'package:ndiscord/models/channel.dart';

class ServerState {
  final List<Server> servers;
  final Server? selectedServer;
  final List<Channel> channels;
  final Channel? selectedChannel;
  final List<ServerMember> members;
  final bool isLoading;

  ServerState({
    this.servers = const [],
    this.selectedServer,
    this.channels = const [],
    this.selectedChannel,
    this.members = const [],
    this.isLoading = false,
  });

  ServerState copyWith({
    List<Server>? servers,
    Server? selectedServer,
    List<Channel>? channels,
    Channel? selectedChannel,
    List<ServerMember>? members,
    bool? isLoading,
  }) {
    return ServerState(
      servers: servers ?? this.servers,
      selectedServer: selectedServer ?? this.selectedServer,
      channels: channels ?? this.channels,
      selectedChannel: selectedChannel ?? this.selectedChannel,
      members: members ?? this.members,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ServerNotifier extends StateNotifier<ServerState> {
  final ApiService _api = ApiService();

  ServerNotifier() : super(ServerState()) {
    loadServers();
  }

  Future<void> loadServers() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _api.getList('/servers');
      final servers = data.map((s) => Server.fromJson(s)).toList();
      state = state.copyWith(servers: servers, isLoading: false);
      if (servers.isNotEmpty && state.selectedServer == null) {
        selectServer(servers.first);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> selectServer(Server server) async {
    state = state.copyWith(selectedServer: server, selectedChannel: null);
    await loadChannels(server.id);
  }

  Future<void> loadChannels(String serverId) async {
    try {
      final data = await _api.getList('/servers/$serverId/channels');
      final channels = data.map((c) => Channel.fromJson(c)).toList();
      state = state.copyWith(channels: channels);
      if (channels.isNotEmpty) {
        final textChannels = channels.where((c) => c.isText).toList();
        if (textChannels.isNotEmpty) {
          selectChannel(textChannels.first);
        }
      }
    } catch (e) {}
  }

  void selectChannel(Channel channel) {
    state = state.copyWith(selectedChannel: channel);
  }

  Future<void> loadMembers(String serverId) async {
    try {
      final data = await _api.getList('/servers/$serverId/members');
      final members = data.map((m) => ServerMember.fromJson(m)).toList();
      state = state.copyWith(members: members);
    } catch (e) {}
  }

  Future<Server?> createServer(String name, String? description) async {
    try {
      final data = await _api.postJson('/servers', body: {
        'name': name,
        if (description != null) 'description': description,
      });
      final server = Server.fromJson(data);
      await loadServers();
      return server;
    } catch (e) {
      return null;
    }
  }

  Future<Channel?> createChannel(String serverId, String name, String type) async {
    try {
      final data = await _api.postJson('/servers/$serverId/channels', body: {
        'name': name,
        'type': type,
      });
      final channel = Channel.fromJson(data);
      await loadChannels(serverId);
      return channel;
    } catch (e) {
      return null;
    }
  }
}

final serverProvider = StateNotifierProvider<ServerNotifier, ServerState>((ref) {
  return ServerNotifier();
});
