import 'package:json_annotation/json_annotation.dart';
import 'message.dart';

part 'conversation.g.dart';

@JsonSerializable(explicitToJson: true)
class Conversation {
  final String id;
  final List<Message> messages;
  final DateTime createdAt;

  Conversation({
    required this.id,
    required this.messages,
    required this.createdAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);

  Map<String, dynamic> toJson() => _$ConversationToJson(this);
}
