import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:okara_chat/models/conversation.dart';
import 'package:okara_chat/models/message.dart';
import 'package:okara_chat/models/model_response.dart';
import 'package:okara_chat/providers/providers.dart';
import 'package:okara_chat/services/parallel_response_handler.dart';
import 'package:okara_chat/data/repositories/conversation_repository.dart';
import 'package:uuid/uuid.dart';

final chatStateProvider = StateNotifierProvider<ChatStateNotifier, ChatState>((
  ref,
) {
  final responseHandler = ref.watch(parallelResponseHandlerProvider);
  final repository = ref.watch(conversationRepositoryProvider);
  return ChatStateNotifier(
    responseHandler: responseHandler,
    repository: repository,
  );
});

class ChatState {
  final Conversation? currentConversation;
  final Map<AIModel, ModelResponse> currentResponses;
  final bool isProcessing;
  final String? error;
  final bool isFastResponseMode;

  ChatState({
    this.currentConversation,
    this.currentResponses = const {},
    this.isProcessing = false,
    this.error,
    this.isFastResponseMode = false,
  });

  ChatState copyWith({
    Conversation? currentConversation,
    Map<AIModel, ModelResponse>? currentResponses,
    bool? isProcessing,
    String? error,
    bool? isFastResponseMode,
  }) {
    return ChatState(
      currentConversation: currentConversation ?? this.currentConversation,
      currentResponses: currentResponses ?? this.currentResponses,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error ?? this.error,
      isFastResponseMode: isFastResponseMode ?? this.isFastResponseMode,
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
  }) : _responseHandler = responseHandler,
       _repository = repository,
       super(ChatState());

  void toggleFastResponseMode() {
    state = state.copyWith(isFastResponseMode: !state.isFastResponseMode);
  }

  void stopStreaming() {
    _cancelCurrentStreams();
    _finalizeAssistantMessage();
  }

  Future<void> sendPrompt(String prompt) async {
    if (prompt.trim().isEmpty) return;

    await _cancelCurrentStreams();

    // Add user message immediately and update state
    final conversation = state.currentConversation ?? _createNewConversation();
    final userMessage = Message(
      id: _uuid.v4(),
      content: prompt,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    conversation.messages.add(userMessage);

    state = state.copyWith(
      isProcessing: true,
      currentResponses: {},
      currentConversation: conversation,
    );

    if (state.isFastResponseMode) {
      _sendFastPrompt(prompt, conversation.messages);
    } else {
      _sendParallelPrompt(prompt, conversation.messages);
    }
  }

  void _sendFastPrompt(String prompt, List<Message> conversationHistory) {
    final controller = _responseHandler.sendPromptToFastModel(
      prompt: prompt,
      conversationHistory: conversationHistory,
    );

    _currentSubscriptions = {
      AIModel.xaiGrok: controller.stream.listen(
        (response) {
          state = state.copyWith(currentResponses: {AIModel.xaiGrok: response});
        },
        onDone: _finalizeAssistantMessage,
        onError: (error) {
          _finalizeAssistantMessage();
          state = state.copyWith(error: 'An error occurred: $error');
        },
      ),
    };
  }

  void _sendParallelPrompt(String prompt, List<Message> conversationHistory) {
    final controllers = _responseHandler.sendPromptToAllModels(
      prompt: prompt,
      conversationHistory: conversationHistory,
    );

    _currentSubscriptions?.values.forEach((sub) => sub.cancel());
    _currentSubscriptions = {};

    for (var model in controllers.keys) {
      _currentSubscriptions![model] = controllers[model]!.stream.listen(
        (response) {
          final newResponses = Map.of(state.currentResponses);
          newResponses[model] = response;
          state = state.copyWith(currentResponses: newResponses);
        },
        onDone: () {
          _currentSubscriptions!.remove(model);
          if (_currentSubscriptions!.isEmpty) {
            _finalizeAssistantMessage();
          }
        },
        onError: (error) {
          // Handle stream error
          _currentSubscriptions!.remove(model);
          if (_currentSubscriptions!.isEmpty) {
            _finalizeAssistantMessage();
          }
          // Optionally update state with error info
          state = state.copyWith(error: 'An error occurred: $error');
        },
      );
    }
  }

  void _finalizeAssistantMessage() {
    if (state.currentResponses.isEmpty) {
      state = state.copyWith(isProcessing: false);
      return;
    }

    final assistantMessage = Message(
      id: _uuid.v4(),
      // Use a primary model's content or a default text
      content:
          state.currentResponses[AIModel.openaiGpt4o]?.content ??
          state.currentResponses.values.first.content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      responses: state.currentResponses,
    );

    final updatedConversation = state.currentConversation;
    updatedConversation?.messages.add(assistantMessage);

    state = state.copyWith(
      isProcessing: false,
      currentConversation: updatedConversation,
      currentResponses: {}, // Clear live responses
    );
    _saveConversation();
  }

  Future<void> _saveConversation() async {
    if (state.currentConversation != null) {
      await _repository.saveConversation(state.currentConversation!);
    }
  }

  Conversation _createNewConversation() {
    return Conversation(
      id: _uuid.v4(),
      messages: [],
      createdAt: DateTime.now(),
    );
  }

  Future<void> _cancelCurrentStreams() async {
    if (_currentSubscriptions != null) {
      for (var sub in _currentSubscriptions!.values) {
        await sub.cancel();
      }
    }
    _currentSubscriptions = null;
  }

  @override
  void dispose() {
    _cancelCurrentStreams();
    super.dispose();
  }
}
