import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:simple_ai_dnd_chat_app/data/models/chat_message.dart';
import 'package:simple_ai_dnd_chat_app/data/repositories/chat_messages_repository.dart';
import 'package:simple_ai_dnd_chat_app/data/services/generative_ai_service.dart';

part 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  ChatCubit(
    this._chatMessagesRepository,
    this._generativeAiService,
    this._firebaseAnalytics,
  ) : super(const ChatState());

  final ChatMessagesRepository _chatMessagesRepository;
  final GenerativeAiService _generativeAiService;
  final FirebaseAnalytics _firebaseAnalytics;

  Timer? _timeUpdateTimer;

  late final String _aiTimeoutError;
  late final String _aiGeneralError;

  Future<void> initialize({
    required String aiTimeoutError,
    required String aiGeneralError,
  }) async {
    try {
      _aiTimeoutError = aiTimeoutError;
      _aiGeneralError = aiGeneralError;

      emit(state.copyWith(loading: true));
      final messages = await _chatMessagesRepository.getAll();
      emit(
        state.copyWith(
          messages: messages,
          loading: false,
          hasNewMessage: false,
        ),
      );

      _startTimeUpdateTimer();

      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'chat_initialized',
          parameters: {'message_count': messages.length},
        ),
      );
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
      emit(state.copyWith(errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(loading: false));
    }
  }

  Future<void> sendUserMessage(String content) async {
    if (state.generatingResponse) return;

    try {
      emit(state.copyWith(generatingResponse: true));

      final chatMessage = ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        role: Role.user,
        content: content,
        createdAt: DateTime.now(),
      );

      await _chatMessagesRepository.add(chatMessage);
      await _refreshMessages(hasNewMessage: true);

      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'message_sent',
          parameters: {
            'role': chatMessage.role.name,
            'content_length': content.length,
          },
        ),
      );

      await _generateModelResponse();
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
      emit(state.copyWith(errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(generatingResponse: false));
    }
  }

  Future<void> _refreshMessages({bool hasNewMessage = false}) async {
    final messages = await _chatMessagesRepository.getAll();
    final latestIndex = messages.isNotEmpty ? messages.length - 1 : -1;
    emit(
      state.copyWith(
        messages: messages,
        hasNewMessage: hasNewMessage,
        shouldScrollToLatest: hasNewMessage,
        latestMessageIndex: latestIndex,
      ),
    );
  }

  Future<void> deleteAllMessages() async {
    try {
      emit(state.copyWith(loading: true));

      _generativeAiService.clearCache();
      await _chatMessagesRepository.deleteAll();
      await _refreshMessages();

      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'chat_deleted',
          parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
        ),
      );
    } catch (e, s) {
      unawaited(Sentry.captureException(e, stackTrace: s));
      emit(state.copyWith(errorMessage: e.toString()));
    } finally {
      emit(state.copyWith(loading: false));
    }
  }

  Future<void> _generateModelResponse() async {
    final startTime = DateTime.now();
    final messages = await _chatMessagesRepository.getAll();
    final contentMessages = messages
        .map((msg) => Content.text(msg.content))
        .toList();

    final modelMessageId = DateTime.now().microsecondsSinceEpoch.toString();
    final createdAt = DateTime.now();

    // Show thinking message first
    final thinkingMessage = ChatMessage(
      id: modelMessageId,
      role: Role.model,
      content: '',
      createdAt: createdAt,
      isThinking: true,
    );

    final messagesWithThinking = List<ChatMessage>.from(messages)
      ..add(thinkingMessage);
    final latestIndex = messagesWithThinking.length - 1;
    emit(
      state.copyWith(
        messages: messagesWithThinking,
        hasNewMessage: true,
        shouldScrollToLatest: true,
        latestMessageIndex: latestIndex,
      ),
    );

    try {
      final responseContent = await _generativeAiService
          .generateResponse(messages: contentMessages)
          .timeout(const Duration(seconds: 30));

      // Save the final complete message to repository
      final finalMessage = ChatMessage(
        id: modelMessageId,
        role: Role.model,
        content: responseContent,
        createdAt: createdAt,
      );

      await _chatMessagesRepository.add(finalMessage);
      emit(state.copyWith(generatingResponse: false));
      await _refreshMessages(hasNewMessage: true);

      final responseTime = DateTime.now().difference(startTime).inMilliseconds;
      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'ai_response_generated',
          parameters: {
            'response_time_ms': responseTime,
            'response_length': finalMessage.content.length,
            'conversation_length': messages.length + 1,
          },
        ),
      );
    } on TimeoutException catch (e, s) {
      // Create error message from AI
      final errorMessage = ChatMessage(
        id: modelMessageId,
        role: Role.model,
        content: _aiTimeoutError,
        createdAt: createdAt,
      );

      await _chatMessagesRepository.add(errorMessage);
      emit(state.copyWith(generatingResponse: false));
      await _refreshMessages(hasNewMessage: true);

      unawaited(Sentry.captureException(e, stackTrace: s));
      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'ai_response_timeout',
          parameters: {
            'timeout_duration_ms': 30000,
            'conversation_length': messages.length + 1,
          },
        ),
      );
    } catch (e, s) {
      // Handle other errors
      final errorMessage = ChatMessage(
        id: modelMessageId,
        role: Role.model,
        content: _aiGeneralError,
        createdAt: createdAt,
      );

      unawaited(Sentry.captureException(e, stackTrace: s));
      await _chatMessagesRepository.add(errorMessage);
      emit(state.copyWith(generatingResponse: false));
      await _refreshMessages(hasNewMessage: true);
    }
  }

  void _startTimeUpdateTimer() {
    _timeUpdateTimer?.cancel();
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      emit(
        state.copyWith(
          messages: List.from(state.messages),
          hasNewMessage: false,
          shouldScrollToLatest: false,
        ),
      );
    });
  }

  void markScrollCompleted() {
    emit(state.copyWith(shouldScrollToLatest: false));
  }

  @override
  Future<void> close() {
    _timeUpdateTimer?.cancel();
    return super.close();
  }
}
