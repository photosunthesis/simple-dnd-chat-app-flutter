part of 'chat_cubit.dart';

class ChatState {
  const ChatState({
    this.messages = const [],
    this.loading = false,
    this.generatingResponse = false,
    this.hasNewMessage = false,
    this.shouldScrollToLatest = false,
    this.latestMessageIndex = -1,
    this.errorMessage,
  });

  final List<ChatMessage> messages;
  final bool loading;
  final bool generatingResponse;
  final bool hasNewMessage;
  final bool shouldScrollToLatest;
  final int latestMessageIndex;
  final String? errorMessage;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? loading,
    bool? generatingResponse,
    bool? hasNewMessage,
    bool? shouldScrollToLatest,
    int? latestMessageIndex,
    String? errorMessage,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      generatingResponse: generatingResponse ?? this.generatingResponse,
      hasNewMessage: hasNewMessage ?? this.hasNewMessage,
      shouldScrollToLatest: shouldScrollToLatest ?? this.shouldScrollToLatest,
      latestMessageIndex: latestMessageIndex ?? this.latestMessageIndex,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
