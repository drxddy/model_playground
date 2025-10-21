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
    final models = AIModel.values.take(3); // Exclude the fast model
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
      model: AIModel.groqLlama31Instant,
      prompt: prompt,
      conversationHistory: conversationHistory,
      controller: controller,
      isFast: true,
    );
    return controller;
  }

  StreamController<ModelResponse> sendPromptToModel({
    required String prompt,
    required List<Message> conversationHistory,
    required AIModel model,
  }) {
    final controller = StreamController<ModelResponse>();
    _streamModelResponse(
      model: model,
      prompt: prompt,
      conversationHistory: conversationHistory,
      controller: controller,
      isFast: false, // Ensure we don't use the fast model for single prompts
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
    List<Message> conversationHistory,
    String prompt,
  ) {
    final messages = conversationHistory.map((m) {
      String? content = m.content;
      // If the message is from the assistant and its main content is empty,
      // it means it's a container for multiple model responses.
      // We need to find the content from the specific model we are querying.
      if (m.role == MessageRole.assistant && content.isEmpty &&
          m.responses != null &&
          m.responses!.isNotEmpty) {
        // For follow-up prompts, we are targeting a single model.
        // We find the content from that model's response.
        // This is a bit of a hack, as we don't have the target model here.
        // A better approach would be to pass the target model or have a primary response.
        // For now, we'll take the first available response content.
        content = m.responses!.values.first.content;
      }
      return {'role': m.role.toString().split('.').last, 'content': content};
    }).toList();

    // The prompt is the last user message, which is already in the history.
    return messages;
  }
}
