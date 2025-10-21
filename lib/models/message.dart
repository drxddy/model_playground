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

  Message copyWith({
    String? id,
    String? content,
    MessageRole? role,
    DateTime? timestamp,
    Map<AIModel, ModelResponse>? responses,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      role: role ?? this.role,
      timestamp: timestamp ?? this.timestamp,
      responses: responses ?? this.responses,
    );
  }
}

enum MessageRole { user, assistant }
