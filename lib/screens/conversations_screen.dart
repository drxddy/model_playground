import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:okara_chat/providers/chat_state_provider.dart';
import 'package:okara_chat/providers/providers.dart';
import 'package:okara_chat/utils/app_theme.dart';

class ConversationsScreen extends ConsumerWidget {
  const ConversationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsyncValue = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        backgroundColor: AppTheme.primaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              ref.read(chatStateProvider.notifier).createNewConversation();
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
      body: conversationsAsyncValue.when(
        data: (conversations) {
          if (conversations.isEmpty) {
            return const Center(child: Text('No conversations yet.'));
          }
          // Sort conversations by creation date, newest first
          conversations.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return ListTile(
                title: Text(
                  conversation.messages.isNotEmpty
                      ? conversation.messages.first.content
                      : 'New Conversation',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('${conversation.messages.length} messages'),
                onTap: () {
                  ref
                      .read(chatStateProvider.notifier)
                      .loadConversation(conversation.id);
                  Navigator.of(context).pop();
                },
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Conversation?'),
                        content: const Text(
                          'Are you sure you want to delete this conversation?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true) {
                      final repo = await ref.read(
                        conversationRepositoryProvider.future,
                      );
                      await repo.deleteConversation(conversation.id);
                      // No need to invalidate, StreamProvider will handle it
                    }
                  },
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
