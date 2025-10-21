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

  ModelResponse({
    required this.id,
    required this.model,
    required this.content,
    required this.status,
    required this.cost,
    required this.latency,
    required this.tokens,
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
  }) {
    return ModelResponse(
      id: id ?? this.id,
      model: model ?? this.model,
      content: content ?? this.content,
      status: status ?? this.status,
      cost: cost ?? this.cost,
      latency: latency ?? this.latency,
      tokens: tokens ?? this.tokens,
    );
  }
}

enum AIModel {
  @JsonValue('openai/gpt-4o')
  openaiGpt4o,
  @JsonValue('anthropic/claude-3-5-sonnet')
  anthropicClaude,
  @JsonValue('x-ai/grok-4')
  xaiGrok,
}

enum ResponseStatus { loading, streaming, completed, error }
