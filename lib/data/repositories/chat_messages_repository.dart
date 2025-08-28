import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:simple_ai_dnd_chat_app/data/models/chat_message.dart';

class ChatMessagesRepository {
  const ChatMessagesRepository(this._chatMessagesBox);

  final Box<ChatMessage> _chatMessagesBox;

  Future<List<ChatMessage>> getAll() async {
    return _chatMessagesBox.values.toList();
  }

  Future<void> add(ChatMessage chatMessage) async {
    await _chatMessagesBox.add(chatMessage);
  }

  Future<void> deleteAll() async {
    await _chatMessagesBox.clear();
  }
}
