import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:okara_chat/models/message.dart';
import 'package:okara_chat/providers/chat_state_provider.dart';
import 'package:okara_chat/utils/app_theme.dart';
import 'package:okara_chat/widgets/model_responses_view.dart';

import 'conversations_screen.dart';

class ChatScreen extends ConsumerWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final chatStateAsync = ref.watch(chatStateProvider);
    final chatNotifier = ref.read(chatStateProvider.notifier);
    final TextEditingController textController = TextEditingController();

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        shadowColor: Colors.transparent,
        toolbarHeight: 0,
        backgroundColor: Colors.transparent,
        titleSpacing: 0.0,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: AppTheme.gradientDecoration,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Image.asset('assets/images/icon-black.webp', height: 42),
                    const SizedBox(width: 10),
                    const Text(
                      'Okara',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Poly',
                        fontSize: 26,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.history, color: Colors.white),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const ConversationsScreen(),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.add, color: Colors.white),
                      onPressed: () {
                        chatNotifier.createNewConversation();
                      },
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: chatStateAsync.when(
                data: (chatState) {
                  final messages =
                      chatState.currentConversation?.messages ?? [];
                  final currentResponses = chatState.currentResponses;
                  return ListView.builder(
                    padding: const EdgeInsets.only(top: 10, bottom: 10),
                    itemCount:
                        messages.length + (currentResponses.isNotEmpty ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == messages.length &&
                          currentResponses.isNotEmpty) {
                        return ModelResponsesView(
                          index: index,
                          responses: currentResponses,
                        );
                      }

                      if (index >= messages.length) {
                        return const SizedBox.shrink(); // Should not happen, but for safety
                      }

                      final message = messages[index];
                      if (message.role == MessageRole.user) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.fromLTRB(60, 8, 0, 20),
                            padding: const EdgeInsets.all(12.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(18),
                                topRight: Radius.circular(18),
                                bottomLeft: Radius.circular(18),
                                bottomRight: Radius.circular(4),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                ),
                              ],
                            ),
                            child: Text(
                              message.content,
                              style: const TextStyle(color: Colors.black87),
                            ),
                          ),
                        );
                      } else {
                        return ModelResponsesView(
                          index: index,
                          responses: message.responses ?? {},
                        );
                      }
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, stack) => Center(
                  child: Text(
                    'Something went wrong:\n$err',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            // Bottom input bar
            chatStateAsync.when(
              data: (chatState) => SafeArea(
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
                      GestureDetector(
                        onTap: () => chatNotifier.toggleFastResponseMode(),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Icon(
                            Icons.bolt,
                            color: chatState.isFastResponseMode
                                ? Colors.amber.shade700
                                : Colors.grey,
                          ),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: textController,
                          decoration: const InputDecoration(
                            hintText: 'How can I help you today?',
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 10,
                            ),
                          ),
                          onSubmitted: (value) {
                            if (value.isNotEmpty) {
                              chatNotifier.sendPrompt(value);
                              textController.clear();
                            }
                          },
                        ),
                      ),
                      chatState.isProcessing
                          ? GestureDetector(
                              child: const Icon(CupertinoIcons.stop_circle_fill, size: 32),
                              onTap: () => chatNotifier.stopStreaming(),
                            )
                          : GestureDetector(
                              child: const Icon(CupertinoIcons.arrow_up_circle_fill, size: 32),
                              onTap: () {
                                if (textController.text.isNotEmpty) {
                                  chatNotifier.sendPrompt(textController.text);
                                  textController.clear();
                                }
                              },
                            ),
                    ],
                  ),
                ),
              ),
              loading: () => const Padding(
                padding: EdgeInsets.all(16.0),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (err, stack) => Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    'Could not load chat input: $err',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
