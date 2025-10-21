import 'package:okara_chat/models/message.dart';
import 'package:sembast/sembast.dart';

class MessageDao {
  final Database _db;
  final StoreRef<String, Map<String, dynamic>> _store;

  MessageDao(this._db) : _store = stringMapStoreFactory.store('messages');

  Future<void> insert(Message message) async {
    await _store.record(message.id).put(_db, message.toJson());
  }

  Future<void> update(Message message) async {
    await _store.record(message.id).update(_db, message.toJson());
  }

  Future<void> delete(String messageId) async {
    await _store.record(messageId).delete(_db);
  }

  Future<Message?> getById(String messageId) async {
    final snapshot = await _store.record(messageId).get(_db);
    if (snapshot != null) {
      return Message.fromJson(snapshot);
    }
    return null;
  }

  Future<List<Message>> getAllByConversationId(String conversationId) async {
    final finder = Finder(
      filter: Filter.equals('conversationId', conversationId),
    );
    final snapshots = await _store.find(_db, finder: finder);
    return snapshots.map((snapshot) {
      return Message.fromJson(snapshot.value);
    }).toList();
  }
}
