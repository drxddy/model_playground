import 'dart:convert';
import 'package:flutter_client_sse/constants/sse_request_type_enum.dart';
import 'package:http/http.dart' as http;
import 'package:okara_chat/models/model_response.dart';
import 'package:flutter_client_sse/flutter_client_sse.dart';

class AIGatewayService {
  static const String _baseUrl = 'https://ai-gateway.vercel.sh/v1';
  // IMPORTANT: Replace with your actual API key or use a secure method to store it.
  static const String _apiKey =
      'vck_2Ig5OGqFkQqxhkqx8VtHfI0COFmOE1pz78nlQqFfLJ4jUdihFZ4Xsqt2';

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
      'model': _getModelIdentifier(model, isFast),
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
      'model': _getModelIdentifier(model, false),
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

  String _getModelIdentifier(AIModel model, bool isFast) {
    if (isFast) {
      return 'groq/llama-3.1-8b-instant';
    }
    switch (model) {
      case AIModel.openaiGpt4o:
        return 'openai/gpt-4o';
      case AIModel.anthropicClaude:
        return 'anthropic/claude-3-5-sonnet';
      case AIModel.xaiGrok:
        return 'xai/grok-4';
    }
  }
}
