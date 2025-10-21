// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'performance_metrics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PerformanceMetrics _$PerformanceMetricsFromJson(Map<String, dynamic> json) =>
    PerformanceMetrics(
      modelId: json['modelId'] as String,
      promptTokens: (json['promptTokens'] as num).toInt(),
      completionTokens: (json['completionTokens'] as num).toInt(),
      totalTokens: (json['totalTokens'] as num).toInt(),
      cost: (json['cost'] as num).toDouble(),
      latency: (json['latency'] as num).toInt(),
    );

Map<String, dynamic> _$PerformanceMetricsToJson(PerformanceMetrics instance) =>
    <String, dynamic>{
      'modelId': instance.modelId,
      'promptTokens': instance.promptTokens,
      'completionTokens': instance.completionTokens,
      'totalTokens': instance.totalTokens,
      'cost': instance.cost,
      'latency': instance.latency,
    };
