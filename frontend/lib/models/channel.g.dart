// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'channel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Channel _$ChannelFromJson(Map<String, dynamic> json) => Channel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'text',
      serverId: json['server_id'] as String,
      position: (json['position'] as num?)?.toInt() ?? 0,
      topic: json['topic'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$ChannelToJson(Channel instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'type': instance.type,
      'server_id': instance.serverId,
      'position': instance.position,
      'topic': instance.topic,
      'created_at': instance.createdAt?.toIso8601String(),
    };
