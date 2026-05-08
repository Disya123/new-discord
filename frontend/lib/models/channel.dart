import 'package:json_annotation/json_annotation.dart';

part 'channel.g.dart';

@JsonSerializable()
class Channel {
  final String id;
  final String name;
  final String type;
  final String serverId;
  final int position;
  final String? topic;
  final DateTime? createdAt;

  Channel({
    required this.id,
    required this.name,
    this.type = 'text',
    required this.serverId,
    this.position = 0,
    this.topic,
    this.createdAt,
  });

  bool get isText => type == 'text';
  bool get isVoice => type == 'voice';

  factory Channel.fromJson(Map<String, dynamic> json) => _$ChannelFromJson(json);
  Map<String, dynamic> toJson() => _$ChannelToJson(this);
}
