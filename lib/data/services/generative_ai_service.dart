import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class GenerativeAiService {
  const GenerativeAiService(this._generativeModel);

  final GenerativeModel _generativeModel;

  static const maxMessagesBeforeSummary = 20;
  static const messagesToKeepAfterSummary = 5;

  Future<String> generateResponse({required List<Content> messages}) async {
    try {
      final optimizedMessages = await _optimizeMessages(messages);
      final chat = _generativeModel.startChat(history: optimizedMessages);
      final response = await chat.sendMessage(optimizedMessages.last);
      return response.text!;
    } catch (e) {
      if (kDebugMode) print(e);
      rethrow;
    }
  }

  Future<List<Content>> _optimizeMessages(List<Content> messages) async {
    if (messages.length <= maxMessagesBeforeSummary) return messages;

    final messagesToSummarize = messages
        .take(messages.length - messagesToKeepAfterSummary)
        .toList();
    final recentMessages = messages
        .skip(messages.length - messagesToKeepAfterSummary)
        .toList();

    final summary = await _summarizeMessages(messagesToSummarize);

    final summaryContent = Content.text(
      'Story Summary: $summary\n\n--- Recent Messages ---',
    );

    return [summaryContent, ...recentMessages];
  }

  Future<String> _summarizeMessages(List<Content> messages) async {
    try {
      final summaryPrompt = Content.text(
        'Please provide a concise summary of this D&D conversation, focusing on key story events, character actions, and current situation. Keep it under 300 words:\n\n',
      );

      final messagesForSummary = [summaryPrompt, ...messages];
      final chat = _generativeModel.startChat(
        history: messagesForSummary
            .take(messagesForSummary.length - 1)
            .toList(),
      );
      final response = await chat.sendMessage(messagesForSummary.last);

      return response.text ?? 'Unable to generate summary';
    } catch (e) {
      if (kDebugMode) print('Error summarizing messages: $e');
      return 'Previous conversation context (summary unavailable)';
    }
  }
}
