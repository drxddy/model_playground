import 'package:okara_chat/models/conversation.dart';
import 'package:sembast/sembast.dart';

class ConversationDao {
  final Database _db;
  final StoreRef<String, Map<String, dynamic>> _store;

  ConversationDao(this._db)
    : _store = stringMapStoreFactory.store('conversations');

  Future<void> insert(Conversation conversation) async {
    await _store.record(conversation.id).put(_db, conversation.toJson());
  }

  Future<void> update(Conversation conversation) async {
    await _store.record(conversation.id).update(_db, conversation.toJson());
  }

  Future<void> delete(String conversationId) async {
    await _store.record(conversationId).delete(_db);
  }

  Future<Conversation?> getById(String conversationId) async {
    final snapshot = await _store.record(conversationId).get(_db);
    if (snapshot != null) {
      return Conversation.fromJson(snapshot);
    }
    return null;
  }

  Future<List<Conversation>> getAll() async {
    final snapshots = await _store.find(_db);
    return snapshots.map((snapshot) {
      return Conversation.fromJson(snapshot.value);
    }).toList();
  }
}
