// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'model_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ModelResponse _$ModelResponseFromJson(Map<String, dynamic> json) =>
    ModelResponse(
      id: json['id'] as String,
      model: $enumDecode(_$AIModelEnumMap, json['model']),
      content: json['content'] as String,
      status: $enumDecode(_$ResponseStatusEnumMap, json['status']),
      cost: (json['cost'] as num).toDouble(),
      latency: (json['latency'] as num).toInt(),
      tokens: (json['tokens'] as num).toInt(),
    );

Map<String, dynamic> _$ModelResponseToJson(ModelResponse instance) =>
    <String, dynamic>{
      'id': instance.id,
      'model': _$AIModelEnumMap[instance.model]!,
      'content': instance.content,
      'status': _$ResponseStatusEnumMap[instance.status]!,
      'cost': instance.cost,
      'latency': instance.latency,
      'tokens': instance.tokens,
    };

const _$AIModelEnumMap = {
  AIModel.openaiGpt4o: 'openai/gpt-4o',
  AIModel.anthropicClaude: 'anthropic/claude-3-5-sonnet',
  AIModel.xaiGrok: 'x-ai/grok-4',
  AIModel.groqLlama31Instant: 'groq/llama-3.1-8b-instant',
};

const _$ResponseStatusEnumMap = {
  ResponseStatus.loading: 'loading',
  ResponseStatus.streaming: 'streaming',
  ResponseStatus.completed: 'completed',
  ResponseStatus.error: 'error',
};
