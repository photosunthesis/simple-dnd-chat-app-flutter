part of 'chat_cubit.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.loading = false,
    this.generatingResponse = false,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final bool loading;
  final bool generatingResponse;
  final String? errorMessage;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? generatingResponse,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      generatingResponse: generatingResponse ?? this.generatingResponse,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
