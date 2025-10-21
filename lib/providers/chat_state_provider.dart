import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:okara_chat/models/conversation.dart';
import 'package:okara_chat/models/message.dart';
import 'package:okara_chat/models/model_response.dart';
import 'package:okara_chat/providers/providers.dart';
import 'package:okara_chat/services/parallel_response_handler.dart';
import 'package:okara_chat/data/repositories/conversation_repository.dart';
import 'package:uuid/uuid.dart';

List<Map<String, dynamic>> serializeMessages(List<Message> messages) {
  return messages.map((message) {
    final messageJson = message.toJson();
    if (message.responses != null) {
      // Manually convert AIModel enum keys to strings
      messageJson['responses'] = message.responses!.map(
        (key, value) =>
            MapEntry(key.toString().split('.').last, value.toJson()),
      );
    }
    return messageJson;
  }).toList();
}

final chatStateProvider =
    StateNotifierProvider<ChatStateNotifier, AsyncValue<ChatState>>((ref) {
      final responseHandler = ref.watch(parallelResponseHandlerProvider);
      final repositoryAsyncValue = ref.watch(conversationRepositoryProvider);

      return repositoryAsyncValue.when(
        data: (repo) => ChatStateNotifier(
          responseHandler: responseHandler,
          repository: repo,
          ref: ref,
        ),
        loading: () => ChatStateNotifier(
          responseHandler: responseHandler,
          repository: null,
          ref: ref,
        ),
        error: (err, stack) {
          // You might want to log the error
          return ChatStateNotifier(
            responseHandler: responseHandler,
            repository: null,
            ref: ref,
          );
        },
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

class ChatStateNotifier extends StateNotifier<AsyncValue<ChatState>> {
  final ParallelResponseHandler _responseHandler;
  final ConversationRepository? _repository;
  final Ref _ref;
  final _uuid = const Uuid();

  Map<AIModel, StreamSubscription>? _currentSubscriptions;

  ChatStateNotifier({
    required ParallelResponseHandler responseHandler,
    required ConversationRepository? repository,
    required Ref ref,
  }) : _responseHandler = responseHandler,
       _repository = repository,
       _ref = ref,
       super(const AsyncValue.loading()) {
    _loadInitialConversation();
  }

  Future<void> _loadInitialConversation() async {
    if (_repository == null) {
      state = AsyncValue.data(ChatState());
      return;
    }
    try {
      final conversations = await _repository!.getAllConversations();
      if (conversations.isNotEmpty) {
        conversations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        state = AsyncValue.data(
          ChatState(currentConversation: conversations.first),
        );
      } else {
        // Create a new one if none exist
        final newConversation = _createNewConversation();
        await _repository.saveConversation(newConversation);
        state = AsyncValue.data(
          ChatState(currentConversation: newConversation),
        );
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadConversation(String conversationId) async {
    if (_repository == null) return;
    _cancelCurrentStreams();
    final conversation = await _repository.getConversation(conversationId);
    if (conversation != null) {
      state = AsyncValue.data(
        state.value?.copyWith(currentConversation: conversation) ??
            ChatState(currentConversation: conversation),
      );
    }
  }

  void toggleFastResponseMode() {
    state.whenData((value) {
      state = AsyncValue.data(
        value.copyWith(isFastResponseMode: !value.isFastResponseMode),
      );
    });
  }

  void stopStreaming() {
    _cancelCurrentStreams();
    _finalizeAssistantMessage();
  }

  void createNewConversation() {
    if (_repository == null) return;
    _cancelCurrentStreams();
    final newConversation = _createNewConversation();
    _repository!.saveConversation(newConversation);
    state = AsyncValue.data(ChatState(currentConversation: newConversation));
  }

  Conversation _createNewConversation() {
    return Conversation(
      id: _uuid.v4(),
      messages: [],
      createdAt: DateTime.now(),
    );
  }

  Future<void> sendPrompt(String prompt) async {
    if (_repository == null || prompt.trim().isEmpty || state.value == null) {
      return;
    }

    await _cancelCurrentStreams();

    final conversation =
        state.value!.currentConversation ?? _createNewConversation();
    final userMessage = Message(
      id: _uuid.v4(),
      content: prompt,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    conversation.messages.add(userMessage);

    await _repository!.saveConversation(conversation);

    state = AsyncValue.data(
      state.value!.copyWith(
        isProcessing: true,
        currentResponses: {},
        currentConversation: conversation,
      ),
    );

    if (state.value!.isFastResponseMode) {
      _sendFastPrompt(prompt, conversation.messages);
    } else {
      _sendParallelPrompt(prompt, conversation.messages);
    }
  }

  Future<void> sendFollowUpPrompt(String prompt, AIModel model) async {
    if (_repository == null || prompt.trim().isEmpty || state.value == null) {
      return;
    }
    await _cancelCurrentStreams();

    final conversation =
        state.value!.currentConversation ?? _createNewConversation();
    final userMessage = Message(
      id: _uuid.v4(),
      content: prompt,
      role: MessageRole.user,
      timestamp: DateTime.now(),
    );
    conversation.messages.add(userMessage);

    await _repository!.saveConversation(conversation);

    state = AsyncValue.data(
      state.value!.copyWith(
        isProcessing: true,
        currentResponses: {},
        currentConversation: conversation,
      ),
    );

    // Send to a single model
    _sendSinglePrompt(prompt, conversation.messages, model);
  }

  void _sendSinglePrompt(String prompt, List<Message> messages, AIModel model) {
    final controller = _responseHandler.sendPromptToModel(
      prompt: prompt,
      conversationHistory: messages,
      model: model,
    );

    _currentSubscriptions = {
      model: controller.stream.listen(
        (response) {
          state.whenData((value) {
            final currentResponses = Map<AIModel, ModelResponse>.from(
              value.currentResponses,
            );
            currentResponses[model] = response;
            state = AsyncValue.data(
              value.copyWith(currentResponses: currentResponses),
            );
          });
        },
        onDone: () {
          _currentSubscriptions!.remove(model);
          _finalizeAssistantMessage();
        },
        onError: (error) {
          _currentSubscriptions!.remove(model);
          _finalizeAssistantMessage();
        },
      ),
    };
  }

  void updateModelResponse(
    int messageIndex,
    AIModel model,
    ModelResponse response,
  ) {
    state.whenData((value) {
      if (value.currentConversation == null) return;

      final conversation = value.currentConversation!;
      if (messageIndex >= conversation.messages.length) return;

      final message = conversation.messages[messageIndex];

      if (message.role == MessageRole.assistant) {
        final newResponses = Map<AIModel, ModelResponse>.from(
          message.responses ?? {},
        );
        newResponses[model] = response;

        final newMessage = message.copyWith(responses: newResponses);

        final newMessages = List<Message>.from(conversation.messages);
        newMessages[messageIndex] = newMessage;

        final newConversation = conversation.copyWith(messages: newMessages);

        state = AsyncValue.data(
          value.copyWith(currentConversation: newConversation),
        );
      }
    });
  }

  void _sendFastPrompt(String prompt, List<Message> messages) {
    // Placeholder for fast response logic
    _finalizeAssistantMessage();
  }

  void _sendParallelPrompt(String prompt, List<Message> messages) {
    final controllers = _responseHandler.sendPromptToAllModels(
      prompt: prompt,
      conversationHistory: messages,
    );

    _currentSubscriptions = controllers.map((model, controller) {
      return MapEntry(
        model,
        controller.stream.listen(
          (response) {
            state.whenData((value) {
              final currentResponses = Map<AIModel, ModelResponse>.from(
                value.currentResponses,
              );
              currentResponses[model] = response;
              state = AsyncValue.data(
                value.copyWith(currentResponses: currentResponses),
              );
            });
          },
          onDone: () {
            _currentSubscriptions!.remove(model);
            if (_currentSubscriptions!.isEmpty) {
              _finalizeAssistantMessage();
            }
          },
          onError: (error) {
            // Handle error appropriately
            _currentSubscriptions!.remove(model);
            if (_currentSubscriptions!.isEmpty) {
              _finalizeAssistantMessage();
            }
          },
        ),
      );
    });
  }

  void _finalizeAssistantMessage() {
    state.whenData((value) {
      if (value.currentConversation == null) {
        state = AsyncValue.data(value.copyWith(isProcessing: false));
        return;
      }

      // Create a new assistant message shell if the last one isn't one
      if (value.currentConversation!.messages.isEmpty ||
          value.currentConversation!.messages.last.role == MessageRole.user) {
        final assistantMessage = Message(
          id: _uuid.v4(),
          content: '', // Will be populated by individual model responses
          role: MessageRole.assistant,
          timestamp: DateTime.now(),
          responses: value.currentResponses,
        );
        value.currentConversation!.messages.add(assistantMessage);
      } else {
        // Update the last message if it's already an assistant message
        final lastMessage = value.currentConversation!.messages.last;
        final updatedMessage = lastMessage.copyWith(
          responses: value.currentResponses,
        );
        value.currentConversation!.messages.removeLast();
        value.currentConversation!.messages.add(updatedMessage);
      }

      _repository!.saveConversation(value.currentConversation!);
      state = AsyncValue.data(
        value.copyWith(isProcessing: false, currentResponses: {}),
      );
    });
  }

  Future<void> _cancelCurrentStreams() async {
    if (_currentSubscriptions != null) {
      for (var sub in _currentSubscriptions!.values) {
        await sub.cancel();
      }
      _currentSubscriptions = null;
    }
  }
}
