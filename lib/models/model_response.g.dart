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
      followUpSuggestions:
          (json['followUpSuggestions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
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
      'followUpSuggestions': instance.followUpSuggestions,
    };

const _$AIModelEnumMap = {
  AIModel.openaiGpt4o: 'openai/gpt-4o',
  AIModel.anthropicClaude: 'anthropic/claude-3-5-sonnet',
  AIModel.xaiGrok: 'xai/grok-3',
  AIModel.groqLlama31Instant: 'groq/llama-3.1-8b-instant',
};

const _$ResponseStatusEnumMap = {
  ResponseStatus.loading: 'loading',
  ResponseStatus.streaming: 'streaming',
  ResponseStatus.completed: 'completed',
  ResponseStatus.error: 'error',
};
