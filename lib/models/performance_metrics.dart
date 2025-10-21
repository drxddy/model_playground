import 'package:json_annotation/json_annotation.dart';

part 'performance_metrics.g.dart';

@JsonSerializable()
class PerformanceMetrics {
  final String modelId;
  final int promptTokens;
  final int completionTokens;
  final int totalTokens;
  final double cost;
  final int latency;

  PerformanceMetrics({
    required this.modelId,
    required this.promptTokens,
    required this.completionTokens,
    required this.totalTokens,
    required this.cost,
    required this.latency,
  });

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) =>
      _$PerformanceMetricsFromJson(json);

  Map<String, dynamic> toJson() => _$PerformanceMetricsToJson(this);
}
