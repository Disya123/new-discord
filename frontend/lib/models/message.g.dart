// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
      id: json['id'] as String,
      content: json['content'] as String,
      encrypted: json['encrypted'] as bool? ?? false,
      channelId: json['channel_id'] as String,
      authorId: json['author_id'] as String,
      authorUsername: json['author_username'] as String,
      authorAvatar: json['author_avatar'] as String?,
      replyToId: json['reply_to_id'] as String?,
      editedAt: json['edited_at'] == null
          ? null
          : DateTime.parse(json['edited_at'] as String),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'encrypted': instance.encrypted,
      'channel_id': instance.channelId,
      'author_id': instance.authorId,
      'author_username': instance.authorUsername,
      'author_avatar': instance.authorAvatar,
      'reply_to_id': instance.replyToId,
      'edited_at': instance.editedAt?.toIso8601String(),
      'created_at': instance.createdAt?.toIso8601String(),
    };

DMMessage _$DMMessageFromJson(Map<String, dynamic> json) => DMMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      encrypted: json['encrypted'] as bool? ?? false,
      conversationId: json['conversation_id'] as String,
      authorId: json['author_id'] as String,
      authorUsername: json['author_username'] as String,
      authorAvatar: json['author_avatar'] as String?,
      read: json['read'] as bool? ?? false,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$DMMessageToJson(DMMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'content': instance.content,
      'encrypted': instance.encrypted,
      'conversation_id': instance.conversationId,
      'author_id': instance.authorId,
      'author_username': instance.authorUsername,
      'author_avatar': instance.authorAvatar,
      'read': instance.read,
      'created_at': instance.createdAt?.toIso8601String(),
    };

DMConversation _$DMConversationFromJson(Map<String, dynamic> json) =>
    DMConversation(
      id: json['id'] as String,
      user1Id: json['user1_id'] as String,
      user2Id: json['user2_id'] as String,
      otherUserId: json['other_user_id'] as String,
      otherUsername: json['other_username'] as String,
      otherAvatar: json['other_avatar'] as String?,
      otherIsOnline: json['other_is_online'] as bool? ?? false,
      lastMessage: json['last_message'] == null
          ? null
          : DMMessage.fromJson(json['last_message'] as Map<String, dynamic>),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$DMConversationToJson(DMConversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user1_id': instance.user1Id,
      'user2_id': instance.user2Id,
      'other_user_id': instance.otherUserId,
      'other_username': instance.otherUsername,
      'other_avatar': instance.otherAvatar,
      'other_is_online': instance.otherIsOnline,
      'last_message': instance.lastMessage,
      'unread_count': instance.unreadCount,
      'created_at': instance.createdAt?.toIso8601String(),
    };
