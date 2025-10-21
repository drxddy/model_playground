import 'dart:async';
import 'dart:convert';
import 'package:okara_chat/models/message.dart';
import 'package:okara_chat/models/model_response.dart';
import 'package:okara_chat/services/ai_gateway_service.dart';
import 'package:okara_chat/services/token_calculator.dart';
import 'package:uuid/uuid.dart';

class ParallelResponseHandler {
  final AIGatewayService _aiGateway;
  final TokenCalculator _tokenCalculator;
  final _uuid = const Uuid();

  ParallelResponseHandler({
    required AIGatewayService aiGateway,
    required TokenCalculator tokenCalculator,
  }) : _aiGateway = aiGateway,
       _tokenCalculator = tokenCalculator;

  Map<AIModel, StreamController<ModelResponse>> sendPromptToAllModels({
    required String prompt,
    required List<Message> conversationHistory,
  }) {
    final models = AIModel.values;
    final controllers = {
      for (var model in models) model: StreamController<ModelResponse>(),
    };

    for (var model in models) {
      _streamModelResponse(
        model: model,
        prompt: prompt,
        conversationHistory: conversationHistory,
        controller: controllers[model]!,
      );
    }

    return controllers;
  }

  StreamController<ModelResponse> sendPromptToFastModel({
    required String prompt,
    required List<Message> conversationHistory,
  }) {
    final controller = StreamController<ModelResponse>();
    _streamModelResponse(
      model: AIModel.xaiGrok,
      prompt: prompt,
      conversationHistory: conversationHistory,
      controller: controller,
      isFast: true,
    );
    return controller;
  }

  Future<void> _streamModelResponse({
    required AIModel model,
    required String prompt,
    required List<Message> conversationHistory,
    required StreamController<ModelResponse> controller,
    bool isFast = false,
  }) async {
    final startTime = DateTime.now();
    final responseId = _uuid.v4();
    String accumulatedContent = '';

    controller.add(
      ModelResponse(
        id: responseId,
        model: model,
        content: '',
        status: ResponseStatus.loading,
        cost: 0,
        latency: 0,
        tokens: 0,
      ),
    );

    try {
      final messages = _buildMessageList(conversationHistory, prompt);
      final stream = _aiGateway.streamChatCompletion(
        model: model,
        messages: messages,
        isFast: isFast,
      );

      await for (var sseModel in stream) {
        if (sseModel.data != null) {
          final trimmedData = sseModel.data!.trim();
          if (trimmedData == '[DONE]') {
            break;
          }
          if (trimmedData.isEmpty) {
            continue;
          }

          final data = jsonDecode(trimmedData);
          if (data['choices'] != null && data['choices'].isNotEmpty) {
            final delta = data['choices'][0]['delta'];
            if (delta != null && delta['content'] != null) {
              final contentChunk = delta['content'] as String;
              accumulatedContent += contentChunk;

              final newTokens = _tokenCalculator.estimateCompletionTokens(
                accumulatedContent,
              );
              final newLatency = DateTime.now()
                  .difference(startTime)
                  .inMilliseconds;

              controller.add(
                ModelResponse(
                  id: responseId,
                  model: model,
                  content: accumulatedContent,
                  status: ResponseStatus.streaming,
                  cost: 0,
                  latency: newLatency,
                  tokens: newTokens,
                ),
              );
            }
          }
        }
      }

      final endTime = DateTime.now();
      final latency = endTime.difference(startTime).inMilliseconds;
      final promptTokens = _tokenCalculator.estimatePromptTokens(prompt);
      final completionTokens = _tokenCalculator.estimateCompletionTokens(
        accumulatedContent,
      );
      final cost = _tokenCalculator.calculateCost(
        model: model,
        promptTokens: promptTokens,
        completionTokens: completionTokens,
      );

      controller.add(
        ModelResponse(
          id: responseId,
          model: model,
          content: accumulatedContent,
          status: ResponseStatus.completed,
          cost: cost,
          latency: latency,
          tokens: completionTokens,
        ),
      );
    } catch (e) {
      controller.add(
        ModelResponse(
          id: responseId,
          model: model,
          content: 'Error: $e',
          status: ResponseStatus.error,
          cost: 0,
          latency: 0,
          tokens: 0,
        ),
      );
    } finally {
      controller.close();
    }
  }

  List<Map<String, dynamic>> _buildMessageList(
    List<Message> history,
    String newPrompt,
  ) {
    final messages = history.map((message) {
      return {
        'role': message.role.toString().split('.').last,
        'content': message.content,
      };
    }).toList();

    messages.add({'role': 'user', 'content': newPrompt});
    return messages;
  }
}
