import 'dart:convert';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:http/http.dart' as http;
import 'package:okara_chat/env.dart';
import 'package:okara_chat/models/model_response.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';

class AIGatewayService {
  static const String _baseUrl = 'https://ai-gateway.vercel.sh/v1';
  // IMPORTANT: Replace with your actual API key or use a secure method to store it.
  static final String _apiKey = Env.apiKey;

  Stream<SSEModel> streamChatCompletion({
    required AIModel model,
    required List<Map<String, dynamic>> messages,
    bool isFast = false,
  }) {
    final url = '$_baseUrl/chat/completions';
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
    final body = {
      'model': _getModelIdentifier(model),
      'messages': messages,
      'stream': true,
      'max_tokens': 1024,
    };

    return SSEClient.subscribeToSSE(
      method: SSERequestType.POST,
      url: url,
      header: headers,
      body: body,
    );
  }

  Future<Map<String, dynamic>> getChatCompletion({
    required AIModel model,
    required List<Map<String, dynamic>> messages,
  }) async {
    final url = Uri.parse('$_baseUrl/chat/completions');
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': _getModelIdentifier(model),
      'messages': messages,
      'stream': false,
      'max_tokens': 1024,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load chat completion: ${response.body}');
    }
  }

  Future<List<String>> getFollowUpSuggestions({
    required AIModel model,
    required List<Map<String, dynamic>> messages,
  }) async {
    const suggestionPrompt =
        'Based on the last message, suggest 3 short, concise follow-up questions a user might ask. Each suggestion should be on a new line, without any numbering or bullet points.';
    // Filter out messages with null or empty content, which can cause API errors.
    final filteredMessages = messages
        .where((m) => m['content'] != null && m['content']!.isNotEmpty)
        .toList();
    final suggestionMessages = List<Map<String, dynamic>>.from(filteredMessages)
      ..add({'role': 'user', 'content': suggestionPrompt});

    try {
      final response = await _performPostRequest(
        model: model,
        messages: suggestionMessages,
        isStreaming: false,
      );

      final content = response['choices'][0]['message']['content'] as String;
      // Split by newline and remove any empty strings that might result from extra newlines.
      final suggestions = content
          .split('\n')
          .where((s) => s.trim().isNotEmpty)
          .toList();
      return suggestions;
    } catch (e) {
      // ignore: avoid_print
      print('Error getting follow-up suggestions: $e');
      return [];
    }
  }

  String _getModelIdentifier(AIModel model) {
    switch (model) {
      case AIModel.openaiGpt4o:
        return 'openai/gpt-4o';
      case AIModel.anthropicClaude:
        return 'anthropic/claude-3-5-sonnet';
      case AIModel.xaiGrok:
        return 'xai/grok-3';
      case AIModel.groqLlama31Instant:
        return 'groq/llama-3.1-8b-instant';
    }
  }

  Future<Map<String, dynamic>> _performPostRequest({
    required AIModel model,
    required List<Map<String, dynamic>> messages,
    required bool isStreaming,
  }) async {
    final url = Uri.parse('$_baseUrl/chat/completions');
    final headers = {
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
    };
    final body = jsonEncode({
      'model': _getModelIdentifier(model), // Always use the specific model
      'messages': messages,
      'stream': isStreaming,
      'max_tokens': 1024,
    });

    final response = await http.post(url, headers: headers, body: body);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load chat completion: ${response.body}');
    }
  }
}
