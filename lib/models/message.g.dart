// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Message _$MessageFromJson(Map<String, dynamic> json) => Message(
  id: json['id'] as String,
  content: json['content'] as String,
  role: $enumDecode(_$MessageRoleEnumMap, json['role']),
  timestamp: DateTime.parse(json['timestamp'] as String),
  responses: (json['responses'] as Map<String, dynamic>?)?.map(
    (k, e) => MapEntry(
      $enumDecode(_$AIModelEnumMap, k),
      ModelResponse.fromJson(e as Map<String, dynamic>),
    ),
  ),
);

Map<String, dynamic> _$MessageToJson(Message instance) => <String, dynamic>{
  'id': instance.id,
  'content': instance.content,
  'role': _$MessageRoleEnumMap[instance.role]!,
  'timestamp': instance.timestamp.toIso8601String(),
  'responses': instance.responses?.map(
    (k, e) => MapEntry(_$AIModelEnumMap[k]!, e.toJson()),
  ),
};

const _$MessageRoleEnumMap = {
  MessageRole.user: 'user',
  MessageRole.assistant: 'assistant',
};

const _$AIModelEnumMap = {
  AIModel.openaiGpt4o: 'openai/gpt-4o',
  AIModel.anthropicClaude: 'anthropic/claude-3-5-sonnet',
  AIModel.xaiGrok: 'xai/grok-3',
  AIModel.groqLlama31Instant: 'groq/llama-3.1-8b-instant',
};
