import 'package:json_annotation/json_annotation.dart';

part 'message.g.dart';

@JsonSerializable()
class Message {
  final String id;
  final String content;
  final bool encrypted;
  final String channelId;
  final String authorId;
  final String authorUsername;
  final String? authorAvatar;
  final String? replyToId;
  final DateTime? editedAt;
  final DateTime? createdAt;

  Message({
    required this.id,
    required this.content,
    this.encrypted = false,
    required this.channelId,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatar,
    this.replyToId,
    this.editedAt,
    this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

@JsonSerializable()
class DMMessage {
  final String id;
  final String content;
  final bool encrypted;
  final String conversationId;
  final String authorId;
  final String authorUsername;
  final String? authorAvatar;
  final bool read;
  final DateTime? createdAt;

  DMMessage({
    required this.id,
    required this.content,
    this.encrypted = false,
    required this.conversationId,
    required this.authorId,
    required this.authorUsername,
    this.authorAvatar,
    this.read = false,
    this.createdAt,
  });

  factory DMMessage.fromJson(Map<String, dynamic> json) => _$DMMessageFromJson(json);
  Map<String, dynamic> toJson() => _$DMMessageToJson(this);
}

@JsonSerializable()
class DMConversation {
  final String id;
  final String user1Id;
  final String user2Id;
  final String otherUserId;
  final String otherUsername;
  final String? otherAvatar;
  final bool otherIsOnline;
  final DMMessage? lastMessage;
  final int unreadCount;
  final DateTime? createdAt;

  DMConversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.otherUserId,
    required this.otherUsername,
    this.otherAvatar,
    this.otherIsOnline = false,
    this.lastMessage,
    this.unreadCount = 0,
    this.createdAt,
  });

  factory DMConversation.fromJson(Map<String, dynamic> json) => _$DMConversationFromJson(json);
  Map<String, dynamic> toJson() => _$DMConversationToJson(this);
}
