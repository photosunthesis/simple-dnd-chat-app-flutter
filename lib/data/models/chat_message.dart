import 'package:hive_ce_flutter/hive_flutter.dart';

enum Role { user, model }

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.createdAt,
    this.isThinking = false,
  });

  final String id;
  final Role role;
  final String content;
  final DateTime createdAt;
  final bool isThinking;
}

class ChatMessageAdapter extends TypeAdapter<ChatMessage> {
  @override
  final int typeId = 0;

  @override
  ChatMessage read(BinaryReader reader) {
    return ChatMessage(
      id: reader.readString(),
      role: Role.values[reader.readByte()],
      content: reader.readString(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(reader.readInt()),
      isThinking: reader.readBool(),
    );
  }

  @override
  void write(BinaryWriter writer, ChatMessage obj) {
    writer
      ..writeString(obj.id)
      ..writeByte(obj.role.index)
      ..writeString(obj.content)
      ..writeInt(obj.createdAt.millisecondsSinceEpoch)
      ..writeBool(obj.isThinking);
  }
}
