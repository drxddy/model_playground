import 'package:okara_chat/data/daos/conversation_dao.dart';
import 'package:okara_chat/models/conversation.dart';

class ConversationRepository {
  final ConversationDao _conversationDao;

  ConversationRepository(this._conversationDao);

  Future<void> saveConversation(Conversation conversation) async {
    // Check if conversation exists
    final existing = await _conversationDao.getById(conversation.id);
    if (existing != null) {
      await _conversationDao.update(conversation);
    } else {
      await _conversationDao.insert(conversation);
    }
  }

  Future<Conversation?> getConversation(String id) async {
    return await _conversationDao.getById(id);
  }

  Future<List<Conversation>> getAllConversations() async {
    return await _conversationDao.getAll();
  }

  Future<void> deleteConversation(String id) async {
    await _conversationDao.delete(id);
  }

  Stream<List<Conversation>> watchAllConversations() {
    return _conversationDao.watchAll();
  }
}
