import 'package:sembast/sembast.dart';
import '../../models/conversation.dart';
import '../database_service.dart';

class ConversationRepository {
  final DatabaseService _dbService;
  final _store = stringMapStoreFactory.store('conversations');

  ConversationRepository(this._dbService);

  Future<void> saveConversation(Conversation conversation) async {
    final db = await _dbService.database;
    await _store.record(conversation.id).put(db, conversation.toJson());
  }

  Future<Conversation?> getConversation(String id) async {
    final db = await _dbService.database;
    final snapshot = await _store.record(id).get(db);
    if (snapshot != null) {
      return Conversation.fromJson(snapshot);
    }
    return null;
  }

  Future<List<Conversation>> getAllConversations() async {
    final db = await _dbService.database;
    final snapshots = await _store.find(db);
    return snapshots.map((snapshot) {
      return Conversation.fromJson(snapshot.value);
    }).toList();
  }

  Future<void> deleteConversation(String id) async {
    final db = await _dbService.database;
    await _store.record(id).delete(db);
  }
}
