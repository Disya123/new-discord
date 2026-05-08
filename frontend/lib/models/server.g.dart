// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Server _$ServerFromJson(Map<String, dynamic> json) => Server(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      iconUrl: json['icon_url'] as String?,
      inviteCode: json['invite_code'] as String?,
      ownerId: json['owner_id'] as String,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ServerToJson(Server instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'icon_url': instance.iconUrl,
      'invite_code': instance.inviteCode,
      'owner_id': instance.ownerId,
      'created_at': instance.createdAt?.toIso8601String(),
    };

ServerMember _$ServerMemberFromJson(Map<String, dynamic> json) =>
    ServerMember(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      username: json['username'] as String,
      displayName: json['display_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      nickname: json['nickname'] as String?,
      role: json['role'] as String? ?? 'member',
      isOnline: json['is_online'] as bool? ?? false,
      status: json['status'] as String? ?? 'offline',
      joinedAt: json['joined_at'] == null
          ? null
          : DateTime.parse(json['joined_at'] as String),
    );

Map<String, dynamic> _$ServerMemberToJson(ServerMember instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'username': instance.username,
      'display_name': instance.displayName,
      'avatar_url': instance.avatarUrl,
      'nickname': instance.nickname,
      'role': instance.role,
      'is_online': instance.isOnline,
      'status': instance.status,
      'joined_at': instance.joinedAt?.toIso8601String(),
    };
