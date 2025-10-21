import 'package:json_annotation/json_annotation.dart';
import 'package:okara_chat/models/model_response.dart';

part 'message.g.dart';

@JsonSerializable(explicitToJson: true)
class Message {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final Map<AIModel, ModelResponse>? responses;

  Message({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.responses,
  });

  factory Message.fromJson(Map<String, dynamic> json) =>
      _$MessageFromJson(json);

  Map<String, dynamic> toJson() => _$MessageToJson(this);
}

enum MessageRole { user, assistant }
