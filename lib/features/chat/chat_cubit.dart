import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
      emit(state.copyWith(messages: messages, loading: false));

      _startTimeUpdateTimer();

      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'chat_initialized',
          parameters: {'message_count': messages.length},
        ),
      );
    } catch (e, s) {
      emit(state.copyWith(errorMessage: e.toString()));
      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'error_occurred',
          parameters: {'error': e.toString(), 'stacktrace': s.toString()},
        ),
      );
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
      await _refreshMessages();

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
      emit(state.copyWith(errorMessage: e.toString()));
      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'error_occurred',
          parameters: {'error': e.toString(), 'stacktrace': s.toString()},
        ),
      );
    } finally {
      emit(state.copyWith(generatingResponse: false));
    }
  }

  Future<void> _refreshMessages() async {
    final messages = await _chatMessagesRepository.getAll();
    emit(state.copyWith(messages: messages));
  }

  Future<void> deleteAllMessages() async {
    try {
      emit(state.copyWith(loading: true));

      await _chatMessagesRepository.deleteAll();
      await _refreshMessages();

      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'chat_deleted',
          parameters: {'timestamp': DateTime.now().millisecondsSinceEpoch},
        ),
      );
    } catch (e, s) {
      emit(state.copyWith(errorMessage: e.toString()));
      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'error_occurred',
          parameters: {'error': e.toString(), 'stacktrace': s.toString()},
        ),
      );
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
    emit(state.copyWith(messages: messagesWithThinking));

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
      await _refreshMessages();

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
      await _refreshMessages();

      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'ai_response_timeout',
          parameters: {
            'timeout_duration_ms': 30000,
            'conversation_length': messages.length + 1,
          },
        ),
      );
      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'error_occurred',
          parameters: {'error': e.toString(), 'stacktrace': s.toString()},
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

      await _chatMessagesRepository.add(errorMessage);
      emit(state.copyWith(generatingResponse: false));
      await _refreshMessages();

      unawaited(
        _firebaseAnalytics.logEvent(
          name: 'error_occurred',
          parameters: {'error': e.toString(), 'stacktrace': s.toString()},
        ),
      );
    }
  }

  void _startTimeUpdateTimer() {
    _timeUpdateTimer?.cancel();
    _timeUpdateTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      emit(state.copyWith(messages: List.from(state.messages)));
    });
  }

  @override
  Future<void> close() {
    _timeUpdateTimer?.cancel();
    return super.close();
  }
}
