import 'package:json_annotation/json_annotation.dart';

part 'server.g.dart';

@JsonSerializable()
class Server {
  final String id;
  final String name;
  final String? description;
  final String? iconUrl;
  final String? inviteCode;
  final String ownerId;
  final DateTime? createdAt;

  Server({
    required this.id,
    required this.name,
    this.description,
    this.iconUrl,
    this.inviteCode,
    required this.ownerId,
    this.createdAt,
  });

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);
  Map<String, dynamic> toJson() => _$ServerToJson(this);
}

@JsonSerializable()
class ServerMember {
  final String id;
  final String userId;
  final String username;
  final String? displayName;
  final String? avatarUrl;
  final String? nickname;
  final String role;
  final bool isOnline;
  final String status;
  final DateTime? joinedAt;

  ServerMember({
    required this.id,
    required this.userId,
    required this.username,
    this.displayName,
    this.avatarUrl,
    this.nickname,
    this.role = 'member',
    this.isOnline = false,
    this.status = 'offline',
    this.joinedAt,
  });

  String get effectiveName => nickname ?? displayName ?? username;

  factory ServerMember.fromJson(Map<String, dynamic> json) => _$ServerMemberFromJson(json);
  Map<String, dynamic> toJson() => _$ServerMemberToJson(this);
}
