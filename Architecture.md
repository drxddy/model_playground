# AI Model Playground - Architecture & Implementation Plan

## Executive Summary

This document outlines the complete architecture and implementation plan for building a Flutter-based AI Model Playground app that provides **side-by-side parallel responses** from three different AI models (OpenAI GPT-4o, Anthropic Claude, and XAI) using the Vercel AI Gateway API.

---

## 1. Overall Architecture

### 1.1 High-Level Architecture

```
┌─────────────────────────────────────────────────────────┐
│                  Presentation Layer                      │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│  │  Model 1   │  │  Model 2   │  │  Model 3   │       │
│  │ Response   │  │ Response   │  │ Response   │       │
│  │   Card     │  │   Card     │  │   Card     │       │
│  └────────────┘  └────────────┘  └────────────┘       │
│         ↓                ↓               ↓              │
│  ┌──────────────────────────────────────────┐          │
│  │         Prompt Input Field               │          │
│  └──────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                  State Management Layer                  │
│              (Riverpod 3.x Providers)                   │
│  ┌──────────────────────────────────────────┐          │
│  │  ChatStateNotifier (StateNotifier)       │          │
│  │  - Manages current conversation state    │          │
│  │  - Orchestrates parallel API calls       │          │
│  │  - Handles loading states per model      │          │
│  └──────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                   Service Layer                          │
│  ┌──────────────────────────────────────────┐          │
│  │   AIGatewayService (Singleton)           │          │
│  │   - HTTP client configuration            │          │
│  │   - SSE stream handling                  │          │
│  │   - Error handling & retries             │          │
│  │   - Rate limit management                │          │
│  └──────────────────────────────────────────┘          │
│                                                          │
│  ┌──────────────────────────────────────────┐          │
│  │   ModelResponseHandler                   │          │
│  │   - Parallel request orchestration       │          │
│  │   - Token counting                       │          │
│  │   - Cost calculation                     │          │
│  └──────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│              Data Persistence Layer                      │
│  ┌──────────────────────────────────────────┐          │
│  │   Sembast Local Database                 │          │
│  │   - Conversations (Store)                │          │
│  │   - Messages (Store)                     │          │
│  │   - Performance Metrics (Store)          │          │
│  └──────────────────────────────────────────┘          │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│                 External API Layer                       │
│              Vercel AI Gateway API                       │
│         https://ai-gateway.vercel.sh/v1                 │
│  ┌────────────┐  ┌────────────┐  ┌────────────┐       │
│  │  OpenAI    │  │ Anthropic  │  │    XAI     │       │
│  │  GPT-4o    │  │   Claude   │  │  Grok-2    │       │
│  └────────────┘  └────────────┘  └────────────┘       │
└─────────────────────────────────────────────────────────┘
```

### 1.2 Application Layers

**Presentation Layer**
- UI widgets for side-by-side model responses
- Input controls and action buttons
- Loading indicators per model
- Performance metrics display

**State Management Layer** 
- Riverpod providers for reactive state
- StateNotifiers for complex state logic
- Async state handling for API calls

**Service Layer**
- API integration with Vercel AI Gateway
- HTTP client with SSE streaming support
- Error handling and retry logic
- Token and cost tracking

**Data Layer**
- Sembast NoSQL database for persistence
- Repository pattern for data access
- Model classes with Freezed

---

## 2. Flutter Packages & Dependencies

### 2.1 Core Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
    
  # State Management
  flutter_riverpod: ^2.5.1
  riverpod_annotation: ^2.3.5
  
  # HTTP & Networking
  http: ^1.2.1
  dio: ^5.4.3+1  # Alternative for better error handling
  
  # SSE Streaming
  flutter_client_sse: ^2.1.0
  fetch_client: ^1.1.2  # For web SSE support
  
  # Local Database
  sembast: ^3.8.5
  path_provider: ^2.1.3
  path: ^1.9.0
  
  # Data Models & Serialization
  freezed_annotation: ^2.4.1
  json_annotation: ^4.9.0
  
  # Utilities
  uuid: ^4.4.0
  intl: ^0.19.0

dev_dependencies:
  # Code Generation
  build_runner: ^2.4.9
  freezed: ^2.5.2
  json_serializable: ^6.8.0
  riverpod_generator: ^2.4.0
  riverpod_lint: ^2.3.10
  
  # Testing
  flutter_test:
    sdk: flutter
  mockito: ^5.4.4
```

### 2.2 Package Justifications

**Riverpod (State Management)**
- Compile-time safety and type-checking
- No BuildContext dependency
- Easy testing and mocking
- Excellent async state handling
- Perfect for managing multiple parallel API responses

**Sembast (Local Database)**
- NoSQL with no upfront schema definitions (as requested)
- 100% Dart - works on all platforms
- Simple key-value and document storage
- Easy queries and filtering
- Built-in encryption support
- Lightweight and fast

**flutter_client_sse + fetch_client**
- Handles Server-Sent Events for streaming responses
- fetch_client specifically for Flutter Web SSE support
- Automatic reconnection handling

**Freezed + json_serializable**
- Immutable data classes
- Built-in copyWith, equality, toString
- Type-safe JSON serialization
- Reduces boilerplate significantly

**Dio (Alternative to http)**
- Better error handling
- Built-in retry logic
- Interceptors for logging
- Request/response transformation

---

## 3. Data Models

### 3.1 Model Definitions (using Freezed)

```dart
// lib/models/message.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  const factory Message({
    required String id,
    required String conversationId,
    required String content,
    required MessageRole role,
    required DateTime timestamp,
  }) = _Message;

  factory Message.fromJson(Map<String, dynamic> json) => 
      _$MessageFromJson(json);
}

enum MessageRole {
  user,
  assistant,
}
```

```dart
// lib/models/model_response.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'model_response.freezed.dart';
part 'model_response.g.dart';

@freezed
class ModelResponse with _$ModelResponse {
  const factory ModelResponse({
    required String id,
    required String messageId,
    required AIModel model,
    required String content,
    required ResponseStatus status,
    required DateTime startTime,
    DateTime? endTime,
    int? promptTokens,
    int? completionTokens,
    int? totalTokens,
    double? estimatedCost,
    String? errorMessage,
  }) = _ModelResponse;

  factory ModelResponse.fromJson(Map<String, dynamic> json) => 
      _$ModelResponseFromJson(json);
}

enum AIModel {
  @JsonValue('openai/gpt-4o')
  openaiGpt4o,
  @JsonValue('anthropic/claude-3-5-sonnet')
  anthropicClaude,
  @JsonValue('x-ai/grok-2')
  xaiGrok,
}

enum ResponseStatus {
  loading,
  streaming,
  completed,
  error,
}
```

```dart
// lib/models/conversation.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'message.dart';
import 'model_response.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required String title,
    required DateTime createdAt,
    required DateTime updatedAt,
    required List<Message> messages,
    required List<ModelResponse> responses,
    @Default(0) int totalTokensUsed,
    @Default(0.0) double totalCostUSD,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) => 
      _$ConversationFromJson(json);
}
```

```dart
// lib/models/performance_metrics.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'performance_metrics.freezed.dart';
part 'performance_metrics.g.dart';

@freezed
class PerformanceMetrics with _$PerformanceMetrics {
  const factory PerformanceMetrics({
    required String modelId,
    required DateTime timestamp,
    required int responseTimeMs,
    required int tokenCount,
    required double costUSD,
    required bool successful,
  }) = _PerformanceMetrics;

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) => 
      _$PerformanceMetricsFromJson(json);
}
```

---

## 4. Vercel AI Gateway Integration

### 4.1 API Service Implementation

```dart
// lib/services/ai_gateway_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/model_response.dart';

class AIGatewayService {
  static const String _baseUrl = 'https://ai-gateway.vercel.sh/v1';
  static const String _apiKey = 'YOUR_AI_GATEWAY_API_KEY'; // Move to env
  
  final http.Client _client;
  
  AIGatewayService({http.Client? client}) 
      : _client = client ?? http.Client();

  /// Send a single prompt to a specific model with SSE streaming
  Stream<String> streamChatCompletion({
    required AIModel model,
    required List<Map<String, dynamic>> messages,
  }) async* {
    final request = http.Request(
      'POST',
      Uri.parse('$_baseUrl/chat/completions'),
    );
    
    request.headers.addAll({
      'Authorization': 'Bearer $_apiKey',
      'Content-Type': 'application/json',
      'Accept': 'text/event-stream',
      'Cache-Control': 'no-cache',
    });
    
    request.body = jsonEncode({
      'model': _getModelIdentifier(model),
      'messages': messages,
      'stream': true,
    });
    
    try {
      final streamedResponse = await _client.send(request);
      
      if (streamedResponse.statusCode != 200) {
        throw Exception(
          'API Error: ${streamedResponse.statusCode}'
        );
      }
      
      await for (var chunk in streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())) {
        
        if (chunk.isEmpty || !chunk.startsWith('data: ')) continue;
        
        final data = chunk.substring(6); // Remove 'data: ' prefix
        
        if (data == '[DONE]') break;
        
        try {
          final json = jsonDecode(data);
          final content = json['choices']?[0]?['delta']?['content'];
          
          if (content != null) {
            yield content as String;
          }
        } catch (e) {
          // Skip malformed chunks
          continue;
        }
      }
    } catch (e) {
      throw Exception('Stream error: $e');
    }
  }
  
  /// Non-streaming completion (for when streaming isn't needed)
  Future<Map<String, dynamic>> getChatCompletion({
    required AIModel model,
    required List<Map<String, dynamic>> messages,
  }) async {
    final response = await _client.post(
      Uri.parse('$_baseUrl/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': _getModelIdentifier(model),
        'messages': messages,
        'stream': false,
      }),
    );
    
    if (response.statusCode != 200) {
      throw Exception(
        'API Error: ${response.statusCode} - ${response.body}'
      );
    }
    
    return jsonDecode(response.body);
  }
  
  String _getModelIdentifier(AIModel model) {
    switch (model) {
      case AIModel.openaiGpt4o:
        return 'openai/gpt-4o';
      case AIModel.anthropicClaude:
        return 'anthropic/claude-3-5-sonnet';
      case AIModel.xaiGrok:
        return 'x-ai/grok-2';
    }
  }
  
  void dispose() {
    _client.close();
  }
}
```

### 4.2 Parallel Request Handler

```dart
// lib/services/parallel_response_handler.dart
import 'dart:async';
import '../models/model_response.dart';
import '../models/message.dart';
import 'ai_gateway_service.dart';
import 'token_calculator.dart';

class ParallelResponseHandler {
  final AIGatewayService _aiGateway;
  final TokenCalculator _tokenCalculator;
  
  ParallelResponseHandler({
    required AIGatewayService aiGateway,
    required TokenCalculator tokenCalculator,
  })  : _aiGateway = aiGateway,
        _tokenCalculator = tokenCalculator;

  /// Send prompt to all three models in parallel
  /// Returns a Map of StreamControllers for each model
  Map<AIModel, StreamController<ModelResponse>> sendPromptToAllModels({
    required String prompt,
    required String messageId,
    required List<Message> conversationHistory,
  }) {
    final models = [
      AIModel.openaiGpt4o,
      AIModel.anthropicClaude,
      AIModel.xaiGrok,
    ];
    
    final controllers = <AIModel, StreamController<ModelResponse>>{};
    
    // Create message format for API
    final messages = _buildMessageList(conversationHistory, prompt);
    
    for (final model in models) {
      final controller = StreamController<ModelResponse>();
      controllers[model] = controller;
      
      // Start streaming for this model
      _streamModelResponse(
        model: model,
        messages: messages,
        messageId: messageId,
        controller: controller,
      );
    }
    
    return controllers;
  }
  
  Future<void> _streamModelResponse({
    required AIModel model,
    required List<Map<String, dynamic>> messages,
    required String messageId,
    required StreamController<ModelResponse> controller,
  }) async {
    final startTime = DateTime.now();
    final responseId = _generateId();
    String accumulatedContent = '';
    
    // Emit initial loading state
    controller.add(ModelResponse(
      id: responseId,
      messageId: messageId,
      model: model,
      content: '',
      status: ResponseStatus.loading,
      startTime: startTime,
    ));
    
    try {
      await for (final chunk in _aiGateway.streamChatCompletion(
        model: model,
        messages: messages,
      )) {
        accumulatedContent += chunk;
        
        // Emit streaming update
        controller.add(ModelResponse(
          id: responseId,
          messageId: messageId,
          model: model,
          content: accumulatedContent,
          status: ResponseStatus.streaming,
          startTime: startTime,
        ));
      }
      
      // Stream completed - calculate final metrics
      final endTime = DateTime.now();
      final tokens = _tokenCalculator.estimateTokens(
        prompt: messages.last['content'] as String,
        completion: accumulatedContent,
      );
      final cost = _tokenCalculator.calculateCost(
        model: model,
        promptTokens: tokens.prompt,
        completionTokens: tokens.completion,
      );
      
      // Emit final completed state
      controller.add(ModelResponse(
        id: responseId,
        messageId: messageId,
        model: model,
        content: accumulatedContent,
        status: ResponseStatus.completed,
        startTime: startTime,
        endTime: endTime,
        promptTokens: tokens.prompt,
        completionTokens: tokens.completion,
        totalTokens: tokens.total,
        estimatedCost: cost,
      ));
      
    } catch (e) {
      // Emit error state
      controller.add(ModelResponse(
        id: responseId,
        messageId: messageId,
        model: model,
        content: accumulatedContent,
        status: ResponseStatus.error,
        startTime: startTime,
        endTime: DateTime.now(),
        errorMessage: e.toString(),
      ));
    } finally {
      await controller.close();
    }
  }
  
  List<Map<String, dynamic>> _buildMessageList(
    List<Message> history,
    String newPrompt,
  ) {
    final messages = <Map<String, dynamic>>[];
    
    // Add conversation history
    for (final msg in history) {
      messages.add({
        'role': msg.role == MessageRole.user ? 'user' : 'assistant',
        'content': msg.content,
      });
    }
    
    // Add new prompt
    messages.add({
      'role': 'user',
      'content': newPrompt,
    });
    
    return messages;
  }
  
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }
}
```

### 4.3 Token Calculator Service

```dart
// lib/services/token_calculator.dart
import '../models/model_response.dart';

class TokenCalculator {
  /// Estimate tokens (rough approximation)
  /// In production, use tiktoken for accurate counting
  TokenEstimate estimateTokens({
    required String prompt,
    required String completion,
  }) {
    // Rough estimation: 1 token ≈ 4 characters
    final promptTokens = (prompt.length / 4).ceil();
    final completionTokens = (completion.length / 4).ceil();
    
    return TokenEstimate(
      prompt: promptTokens,
      completion: completionTokens,
      total: promptTokens + completionTokens,
    );
  }
  
  /// Calculate estimated cost in USD
  double calculateCost({
    required AIModel model,
    required int promptTokens,
    required int completionTokens,
  }) {
    final pricing = _getPricing(model);
    
    final promptCost = (promptTokens / 1000000) * pricing.inputPerMillion;
    final completionCost = 
        (completionTokens / 1000000) * pricing.outputPerMillion;
    
    return promptCost + completionCost;
  }
  
  ModelPricing _getPricing(AIModel model) {
    // Pricing as of Oct 2025 (verify current rates)
    switch (model) {
      case AIModel.openaiGpt4o:
        return ModelPricing(
          inputPerMillion: 2.50,
          outputPerMillion: 10.00,
        );
      case AIModel.anthropicClaude:
        return ModelPricing(
          inputPerMillion: 3.00,
          outputPerMillion: 15.00,
        );
      case AIModel.xaiGrok:
        return ModelPricing(
          inputPerMillion: 5.00,
          outputPerMillion: 15.00,
        );
    }
  }
}

class TokenEstimate {
  final int prompt;
  final int completion;
  final int total;
  
  TokenEstimate({
    required this.prompt,
    required this.completion,
    required this.total,
  });
}

class ModelPricing {
  final double inputPerMillion;
  final double outputPerMillion;
  
  ModelPricing({
    required this.inputPerMillion,
    required this.outputPerMillion,
  });
}
```

---

## 5. Sembast Database Layer

### 5.1 Database Setup

```dart
// lib/data/database_service.dart
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();
  
  Database? _database;
  
  // Store references
  final conversationsStore = intMapStoreFactory.store('conversations');
  final messagesStore = intMapStoreFactory.store('messages');
  final responsesStore = intMapStoreFactory.store('responses');
  final metricsStore = intMapStoreFactory.store('metrics');
  
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }
  
  Future<Database> _initDatabase() async {
    final appDir = await getApplicationDocumentsDirectory();
    await appDir.create(recursive: true);
    final dbPath = join(appDir.path, 'ai_playground.db');
    
    return await databaseFactoryIo.openDatabase(dbPath);
  }
  
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
```

### 5.2 Repository Pattern

```dart
// lib/data/repositories/conversation_repository.dart
import 'package:sembast/sembast.dart';
import '../../models/conversation.dart';
import '../../models/message.dart';
import '../../models/model_response.dart';
import '../database_service.dart';

class ConversationRepository {
  final DatabaseService _dbService;
  
  ConversationRepository(this._dbService);
  
  Future<int> saveConversation(Conversation conversation) async {
    final db = await _dbService.database;
    return await _dbService.conversationsStore.add(
      db,
      conversation.toJson(),
    );
  }
  
  Future<void> updateConversation(
    int id,
    Conversation conversation,
  ) async {
    final db = await _dbService.database;
    await _dbService.conversationsStore.record(id).update(
      db,
      conversation.toJson(),
    );
  }
  
  Future<List<Conversation>> getAllConversations() async {
    final db = await _dbService.database;
    
    final finder = Finder(
      sortOrders: [SortOrder('updatedAt', false)], // Most recent first
    );
    
    final snapshots = await _dbService.conversationsStore.find(
      db,
      finder: finder,
    );
    
    return snapshots
        .map((snapshot) => Conversation.fromJson(
              snapshot.value as Map<String, dynamic>,
            ))
        .toList();
  }
  
  Future<Conversation?> getConversationById(String id) async {
    final db = await _dbService.database;
    
    final finder = Finder(
      filter: Filter.equals('id', id),
    );
    
    final snapshot = await _dbService.conversationsStore.findFirst(
      db,
      finder: finder,
    );
    
    if (snapshot == null) return null;
    
    return Conversation.fromJson(
      snapshot.value as Map<String, dynamic>,
    );
  }
  
  Future<void> deleteConversation(String id) async {
    final db = await _dbService.database;
    
    final finder = Finder(
      filter: Filter.equals('id', id),
    );
    
    await _dbService.conversationsStore.delete(
      db,
      finder: finder,
    );
  }
  
  Future<void> saveMessage(Message message) async {
    final db = await _dbService.database;
    await _dbService.messagesStore.add(
      db,
      message.toJson(),
    );
  }
  
  Future<void> saveModelResponse(ModelResponse response) async {
    final db = await _dbService.database;
    await _dbService.responsesStore.add(
      db,
      response.toJson(),
    );
  }
}
```

---

## 6. Riverpod State Management

### 6.1 Providers Setup

```dart
// lib/providers/ai_gateway_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ai_gateway_service.dart';
import '../services/token_calculator.dart';
import '../services/parallel_response_handler.dart';

final aiGatewayServiceProvider = Provider<AIGatewayService>((ref) {
  return AIGatewayService();
});

final tokenCalculatorProvider = Provider<TokenCalculator>((ref) {
  return TokenCalculator();
});

final parallelResponseHandlerProvider = 
    Provider<ParallelResponseHandler>((ref) {
  return ParallelResponseHandler(
    aiGateway: ref.watch(aiGatewayServiceProvider),
    tokenCalculator: ref.watch(tokenCalculatorProvider),
  );
});
```

```dart
// lib/providers/database_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/database_service.dart';
import '../data/repositories/conversation_repository.dart';

final databaseServiceProvider = Provider<DatabaseService>((ref) {
  return DatabaseService();
});

final conversationRepositoryProvider = 
    Provider<ConversationRepository>((ref) {
  return ConversationRepository(
    ref.watch(databaseServiceProvider),
  );
});
```

### 6.2 Chat State Notifier

```dart
// lib/providers/chat_state_provider.dart
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/model_response.dart';
import '../services/parallel_response_handler.dart';
import '../data/repositories/conversation_repository.dart';

final chatStateProvider = 
    StateNotifierProvider<ChatStateNotifier, ChatState>((ref) {
  return ChatStateNotifier(
    responseHandler: ref.watch(parallelResponseHandlerProvider),
    repository: ref.watch(conversationRepositoryProvider),
  );
});

class ChatState {
  final Conversation? currentConversation;
  final Map<AIModel, ModelResponse> currentResponses;
  final bool isProcessing;
  final String? error;
  
  ChatState({
    this.currentConversation,
    this.currentResponses = const {},
    this.isProcessing = false,
    this.error,
  });
  
  ChatState copyWith({
    Conversation? currentConversation,
    Map<AIModel, ModelResponse>? currentResponses,
    bool? isProcessing,
    String? error,
  }) {
    return ChatState(
      currentConversation: currentConversation ?? this.currentConversation,
      currentResponses: currentResponses ?? this.currentResponses,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
    );
  }
}

class ChatStateNotifier extends StateNotifier<ChatState> {
  final ParallelResponseHandler _responseHandler;
  final ConversationRepository _repository;
  final _uuid = const Uuid();
  
  Map<AIModel, StreamSubscription>? _currentSubscriptions;
  
  ChatStateNotifier({
    required ParallelResponseHandler responseHandler,
    required ConversationRepository repository,
  })  : _responseHandler = responseHandler,
        _repository = repository,
        super(ChatState());

  /// Send a prompt and get responses from all three models
  Future<void> sendPrompt(String prompt) async {
    if (prompt.trim().isEmpty) return;
    
    state = state.copyWith(isProcessing: true, error: null);
    
    try {
      // Cancel any ongoing streams
      await _cancelCurrentStreams();
      
      // Create or get conversation
      final conversation = state.currentConversation ?? _createNewConversation();
      
      // Create user message
      final userMessage = Message(
        id: _uuid.v4(),
        conversationId: conversation.id,
        content: prompt,
        role: MessageRole.user,
        timestamp: DateTime.now(),
      );
      
      // Save user message
      await _repository.saveMessage(userMessage);
      
      // Update conversation with new message
      final updatedConversation = conversation.copyWith(
        messages: [...conversation.messages, userMessage],
        updatedAt: DateTime.now(),
      );
      
      state = state.copyWith(currentConversation: updatedConversation);
      
      // Send to all models in parallel
      final controllers = _responseHandler.sendPromptToAllModels(
        prompt: prompt,
        messageId: userMessage.id,
        conversationHistory: conversation.messages,
      );
      
      // Subscribe to each model's stream
      _currentSubscriptions = {};
      
      for (final entry in controllers.entries) {
        final model = entry.key;
        final controller = entry.value;
        
        _currentSubscriptions![model] = controller.stream.listen(
          (response) {
            // Update state with latest response
            final updatedResponses = Map<AIModel, ModelResponse>.from(
              state.currentResponses,
            );
            updatedResponses[model] = response;
            
            state = state.copyWith(currentResponses: updatedResponses);
            
            // Save completed responses to database
            if (response.status == ResponseStatus.completed) {
              _repository.saveModelResponse(response);
            }
          },
          onError: (error) {
            print('Stream error for $model: $error');
          },
        );
      }
      
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        error: e.toString(),
      );
    }
  }
  
  Conversation _createNewConversation() {
    return Conversation(
      id: _uuid.v4(),
      title: 'New Conversation',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      messages: [],
      responses: [],
    );
  }
  
  Future<void> _cancelCurrentStreams() async {
    if (_currentSubscriptions != null) {
      for (final subscription in _currentSubscriptions!.values) {
        await subscription.cancel();
      }
      _currentSubscriptions = null;
    }
  }
  
  void startNewConversation() {
    state = ChatState();
  }
  
  Future<void> loadConversation(String conversationId) async {
    final conversation = await _repository.getConversationById(conversationId);
    if (conversation != null) {
      state = state.copyWith(currentConversation: conversation);
    }
  }
  
  @override
  void dispose() {
    _cancelCurrentStreams();
    super.dispose();
  }
}
```

---

## 7. UI Implementation Plan

### 7.1 Side-by-Side Response Cards

```dart
// lib/widgets/model_response_card.dart
import 'package:flutter/material.dart';
import '../models/model_response.dart';
import '../models/model_response.dart' show AIModel;

class ModelResponseCard extends StatelessWidget {
  final ModelResponse response;
  
  const ModelResponseCard({
    super.key,
    required this.response,
  });
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Model name header
            Row(
              children: [
                _buildModelIcon(),
                const SizedBox(width: 8),
                Text(
                  _getModelName(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStatusIndicator(),
              ],
            ),
            
            const Divider(height: 24),
            
            // Response content
            Expanded(
              child: SingleChildScrollView(
                child: _buildContent(),
              ),
            ),
            
            // Performance metrics
            if (response.status == ResponseStatus.completed)
              _buildMetrics(context),
          ],
        ),
      ),
    );
  }
  
  Widget _buildModelIcon() {
    IconData icon;
    Color color;
    
    switch (response.model) {
      case AIModel.openaiGpt4o:
        icon = Icons.auto_awesome;
        color = Colors.green;
        break;
      case AIModel.anthropicClaude:
        icon = Icons.psychology;
        color = Colors.orange;
        break;
      case AIModel.xaiGrok:
        icon = Icons.rocket_launch;
        color = Colors.blue;
        break;
    }
    
    return Icon(icon, color: color);
  }
  
  String _getModelName() {
    switch (response.model) {
      case AIModel.openaiGpt4o:
        return 'GPT-4o';
      case AIModel.anthropicClaude:
        return 'Claude 3.5';
      case AIModel.xaiGrok:
        return 'Grok-2';
    }
  }
  
  Widget _buildStatusIndicator() {
    Widget indicator;
    
    switch (response.status) {
      case ResponseStatus.loading:
        indicator = const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
        break;
      case ResponseStatus.streaming:
        indicator = const Icon(
          Icons.pending,
          size: 16,
          color: Colors.blue,
        );
        break;
      case ResponseStatus.completed:
        indicator = const Icon(
          Icons.check_circle,
          size: 16,
          color: Colors.green,
        );
        break;
      case ResponseStatus.error:
        indicator = const Icon(
          Icons.error,
          size: 16,
          color: Colors.red,
        );
        break;
    }
    
    return indicator;
  }
  
  Widget _buildContent() {
    if (response.status == ResponseStatus.loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (response.status == ResponseStatus.error) {
      return Text(
        'Error: ${response.errorMessage ?? "Unknown error"}',
        style: const TextStyle(color: Colors.red),
      );
    }
    
    return Text(response.content);
  }
  
  Widget _buildMetrics(BuildContext context) {
    final responseTime = response.endTime != null
        ? response.endTime!.difference(response.startTime).inMilliseconds
        : 0;
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricItem(
            context,
            'Tokens',
            '${response.totalTokens ?? 0}',
          ),
          _buildMetricItem(
            context,
            'Time',
            '${responseTime}ms',
          ),
          _buildMetricItem(
            context,
            'Cost',
            '\$${response.estimatedCost?.toStringAsFixed(5) ?? '0'}',
          ),
        ],
      ),
    );
  }
  
  Widget _buildMetricItem(
    BuildContext context,
    String label,
    String value,
  ) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
```

### 7.2 Main Chat Screen

```dart
// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/chat_state_provider.dart';
import '../widgets/model_response_card.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});
  
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _promptController = TextEditingController();
  final _scrollController = ScrollController();
  
  @override
  void dispose() {
    _promptController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatStateProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Model Playground'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              // Navigate to history screen
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ref.read(chatStateProvider.notifier).startNewConversation();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Response area
          Expanded(
            child: chatState.currentResponses.isEmpty
                ? _buildEmptyState()
                : _buildResponseGrid(chatState),
          ),
          
          // Input area
          _buildInputArea(chatState),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your prompt will be sent to 3 AI models simultaneously',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildResponseGrid(ChatState chatState) {
    final responses = [
      chatState.currentResponses[AIModel.openaiGpt4o],
      chatState.currentResponses[AIModel.anthropicClaude],
      chatState.currentResponses[AIModel.xaiGrok],
    ];
    
    return LayoutBuilder(
      builder: (context, constraints) {
        // Use column layout on mobile, row on tablet/desktop
        final isMobile = constraints.maxWidth < 600;
        
        if (isMobile) {
          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: responses.length,
            itemBuilder: (context, index) {
              final response = responses[index];
              if (response == null) return const SizedBox.shrink();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 400,
                  child: ModelResponseCard(response: response),
                ),
              );
            },
          );
        } else {
          return Row(
            children: responses.map((response) {
              if (response == null) return const Expanded(child: SizedBox());
              
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ModelResponseCard(response: response),
                ),
              );
            }).toList(),
          );
        }
      },
    );
  }
  
  Widget _buildInputArea(ChatState chatState) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _promptController,
              maxLines: null,
              enabled: !chatState.isProcessing,
              decoration: InputDecoration(
                hintText: 'Enter your prompt...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          FloatingActionButton(
            onPressed: chatState.isProcessing ? null : _sendPrompt,
            child: chatState.isProcessing
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.send),
          ),
        ],
      ),
    );
  }
  
  void _sendPrompt() {
    final prompt = _promptController.text.trim();
    if (prompt.isEmpty) return;
    
    ref.read(chatStateProvider.notifier).sendPrompt(prompt);
    _promptController.clear();
  }
}
```

---

## 8. Implementation Roadmap

### Phase 1: Foundation (4-6 hours)
1. ✅ Set up Flutter project with all dependencies
2. ✅ Define data models with Freezed
3. ✅ Set up Sembast database and repositories
4. ✅ Create basic UI structure

### Phase 2: API Integration (6-8 hours)
1. ✅ Implement AIGatewayService with SSE streaming
2. ✅ Create ParallelResponseHandler
3. ✅ Implement TokenCalculator
4. ✅ Add error handling and retry logic

### Phase 3: State Management (4-6 hours)
1. ✅ Set up Riverpod providers
2. ✅ Implement ChatStateNotifier
3. ✅ Connect UI to state management
4. ✅ Handle loading states and errors

### Phase 4: UI Polish (4-6 hours)
1. ✅ Design side-by-side response cards
2. ✅ Implement responsive layout
3. ✅ Add performance metrics display
4. ✅ Create history/conversation list screen

### Phase 5: Testing & Documentation (2-4 hours)
1. ✅ Write unit tests for services
2. ✅ Test parallel streaming
3. ✅ Create comprehensive README
4. ✅ Document architecture decisions

**Total Estimated Time: 20-30 hours** (fits within 2-day intensive work)

---

## 9. Key Technical Decisions

### Why Riverpod over Bloc?
- Better async state handling out of the box
- No boilerplate event/state classes needed
- Easier testing and mocking
- Perfect for managing multiple parallel streams
- Type-safe without code generation (though we use it for convenience)

### Why Sembast over SQLite?
- No schema migrations required
- Works identically across all platforms
- Simpler API for document-based storage
- Built-in support for complex queries
- Perfect for storing JSON-like data structures

### Why SSE over WebSockets?
- Vercel AI Gateway provides SSE out of the box
- Simpler protocol for unidirectional streaming
- Automatic reconnection in most implementations
- Works better through proxies and firewalls
- Built on HTTP, so easier to authenticate

### Cost Tracking Strategy
- Use rough token estimation (4 chars ≈ 1 token)
- For production: integrate tiktoken library for accurate counting
- Track costs per model and conversation
- Store historical metrics for analysis

---

## 10. Future Improvements

1. **Advanced Features**
   - Model parameter customization (temperature, max tokens)
   - Image input support for vision models
   - Export conversations as PDF/Markdown
   - Search across conversation history

2. **Performance Optimizations**
   - Implement proper token counting with tiktoken
   - Add request caching
   - Lazy load conversation history
   - Optimize database queries with indexes

3. **User Experience**
   - Dark mode support
   - Customizable model selection
   - Comparison metrics (side-by-side analysis)
   - Favorites and bookmarking

4. **Developer Experience**
   - Add comprehensive logging
   - Implement analytics tracking
   - Create admin dashboard for usage stats
   - Add A/B testing framework

---

## 11. Environment Setup

```bash
# .env file (use flutter_dotenv or similar)
AI_GATEWAY_API_KEY=your_vercel_ai_gateway_key_here
```

```dart
// lib/config/environment.dart
class Environment {
  static const String aiGatewayApiKey = 
      String.fromEnvironment('AI_GATEWAY_API_KEY');
}
```

---

## 12. Testing Strategy

### Unit Tests
- Service layer tests with mocked HTTP client
- Token calculator accuracy tests
- Database repository CRUD tests

### Integration Tests
- End-to-end conversation flow
- Parallel streaming behavior
- Database persistence verification

### Widget Tests
- UI component rendering
- User interactions
- State updates

---

## Conclusion

This architecture provides a solid foundation for building a production-ready AI Model Playground app. The use of Riverpod for state management, Sembast for local storage, and proper separation of concerns ensures the codebase is maintainable, testable, and scalable.

The parallel streaming architecture allows for real-time side-by-side comparisons of AI model responses, giving users valuable insights into model performance and characteristics.
