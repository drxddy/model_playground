import 'package:json_annotation/json_annotation.dart';

part 'model_response.g.dart';

@JsonSerializable()
class ModelResponse {
  final String id;
  final AIModel model;
  final String content;
  final ResponseStatus status;
  final double cost;
  final int latency;
  final int tokens;
  final List<String> followUpSuggestions;

  ModelResponse({
    required this.id,
    required this.model,
    required this.content,
    required this.status,
    required this.cost,
    required this.latency,
    required this.tokens,
    this.followUpSuggestions = const [],
  });

  factory ModelResponse.fromJson(Map<String, dynamic> json) =>
      _$ModelResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ModelResponseToJson(this);

  ModelResponse copyWith({
    String? id,
    AIModel? model,
    String? content,
    ResponseStatus? status,
    double? cost,
    int? latency,
    int? tokens,
    List<String>? followUpSuggestions,
  }) {
    return ModelResponse(
      id: id ?? this.id,
      model: model ?? this.model,
      content: content ?? this.content,
      status: status ?? this.status,
      cost: cost ?? this.cost,
      latency: latency ?? this.latency,
      tokens: tokens ?? this.tokens,
      followUpSuggestions: followUpSuggestions ?? this.followUpSuggestions,
    );
  }
}

enum AIModel {
  @JsonValue('openai/gpt-4o')
  openaiGpt4o,
  @JsonValue('anthropic/claude-3-5-sonnet')
  anthropicClaude,
  @JsonValue('xai/grok-3')
  xaiGrok,
  @JsonValue('groq/llama-3.1-8b-instant')
  groqLlama31Instant,
}

enum ResponseStatus { loading, streaming, completed, error }
