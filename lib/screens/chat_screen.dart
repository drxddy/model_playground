import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:okara_chat/models/message.dart';
import 'package:okara_chat/providers/chat_state_provider.dart';
import 'package:okara_chat/utils/app_theme.dart';
import 'package:okara_chat/widgets/model_responses_view.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatState = ref.watch(chatStateProvider);
    final chatNotifier = ref.read(chatStateProvider.notifier);
    final TextEditingController textController = TextEditingController();

    final messages = chatState.currentConversation?.messages ?? [];
    final currentResponses = chatState.currentResponses;
    final isProcessing = chatState.isProcessing;
    final isFastResponseMode = chatState.isFastResponseMode;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        shadowColor: Colors.transparent,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/icon-black.webp', height: 30),
            const SizedBox(width: 10),
            const Text(
              'Okara Playground',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: AppTheme.gradientDecoration,
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.only(
                  top: kToolbarHeight + MediaQuery.of(context).padding.top,
                  bottom: 10,
                ),
                itemCount:
                    messages.length + (currentResponses.isNotEmpty ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length && currentResponses.isNotEmpty) {
                    return ModelResponsesView(responses: currentResponses);
                  }

                  final message = messages[index];
                  if (message.role == MessageRole.user) {
                    return Align(
                      alignment: Alignment.centerRight,
                      child: Card(
                        margin: const EdgeInsets.fromLTRB(60, 6, 12, 6),
                        color: Colors.white.withOpacity(0.9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            message.content,
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ),
                      ),
                    );
                  } else if (message.role == MessageRole.assistant &&
                      message.responses != null) {
                    return ModelResponsesView(responses: message.responses!);
                  }
                  return Container();
                },
              ),
            ),
            if (isProcessing)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: LinearProgressIndicator(),
              ),
            _buildInputArea(
              context,
              textController,
              chatNotifier,
              isProcessing,
              isFastResponseMode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(
    BuildContext context,
    TextEditingController controller,
    ChatStateNotifier notifier,
    bool isProcessing,
    bool isFastResponseMode,
  ) {
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.8),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                Icons.bolt,
                color: isFastResponseMode ? Colors.amber.shade700 : Colors.grey,
              ),
              onPressed: () => notifier.toggleFastResponseMode(),
              tooltip: 'Fast Response Mode',
            ),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter your prompt...',
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 10),
                ),
                onSubmitted: (value) {
                  if (value.isNotEmpty) {
                    notifier.sendPrompt(value);
                    controller.clear();
                  }
                },
              ),
            ),
            if (isProcessing)
              IconButton(
                icon: const Icon(Icons.stop_circle_outlined),
                onPressed: () => notifier.stopStreaming(),
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'Stop',
              )
            else
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    notifier.sendPrompt(controller.text);
                    controller.clear();
                  }
                },
                color: Theme.of(context).colorScheme.primary,
                tooltip: 'Send',
              ),
          ],
        ),
      ),
    );
  }
}
