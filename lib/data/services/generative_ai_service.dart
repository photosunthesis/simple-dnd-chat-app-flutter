import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:firebase_ai/firebase_ai.dart';

class GenerativeAiService {
  GenerativeAiService(this._generativeModel);

  static const maxMessagesBeforeSummary = 20;
  static const messagesToKeepAfterSummary = 8;

  final GenerativeModel _generativeModel;

  // Cache for summaries to avoid re-summarizing the same content
  String? _cachedSummary;
  String? _cachedSummaryHash;

  Future<String> generateResponse({required List<Content> messages}) async {
    final optimizedMessages = await _optimizeMessages(messages);
    final chat = _generativeModel.startChat(
      history: optimizedMessages.length > 1
          ? optimizedMessages.sublist(0, optimizedMessages.length - 1)
          : [],
    );
    final response = await chat.sendMessage(optimizedMessages.last);
    return response.text ?? 'Sorry, I could not come up with a response.';
  }

  // Public method for analytics (optional)
  int getOptimizedMessageCount(List<Content> messages) {
    if (messages.length <= maxMessagesBeforeSummary) {
      return messages.length;
    }
    return messagesToKeepAfterSummary + 1; // Summary + recent messages
  }

  Future<List<Content>> _optimizeMessages(List<Content> messages) async {
    // If conversation is short, no optimization needed
    if (messages.length <= maxMessagesBeforeSummary) {
      return messages;
    }

    // Calculate how many messages to summarize vs keep recent
    final messagesToSummarizeCount =
        messages.length - messagesToKeepAfterSummary;
    final messagesToSummarize = messages
        .take(messagesToSummarizeCount)
        .toList();
    final recentMessages = messages.skip(messagesToSummarizeCount).toList();

    // Generate a hash of the content to be summarized to use as a cache key
    final summaryContentHash = _generateContentHash(messagesToSummarize);

    // Check if we can reuse cached summary
    String summary;
    if (_canReuseCachedSummary(summaryContentHash)) {
      summary = _cachedSummary!;
    } else {
      summary = await _summarizeMessages(messagesToSummarize);
      _updateCache(summary, summaryContentHash);
    }

    // Create the optimized message list
    final summaryContent = Content.text(
      'Previous conversation summary: $summary\n\n--- Recent Messages ---',
    );

    return [summaryContent, ...recentMessages];
  }

  bool _canReuseCachedSummary(String summaryContentHash) {
    return _cachedSummary != null && _cachedSummaryHash == summaryContentHash;
  }

  void _updateCache(String summary, String summaryContentHash) {
    _cachedSummary = summary;
    _cachedSummaryHash = summaryContentHash;
  }

  String _generateContentHash(List<Content> messages) {
    final contentString = messages
        .map((c) => c.parts.whereType<TextPart>().map((p) => p.text).join())
        .join();
    return sha256.convert(utf8.encode(contentString)).toString();
  }

  Future<String> _summarizeMessages(List<Content> messages) async {
    try {
      // Create a separate chat just for summarization
      final summarizationChat = _generativeModel.startChat(history: []);

      // Send all messages at once for summarization
      final contentToSummarize = messages
          .map((msg) =>
              '${msg.role ?? 'user'}: ${msg.parts.whereType<TextPart>().map((p) => p.text).join()}')
          .join('\n\n');

      final summaryRequest = Content.text(
        'Please provide a concise summary of this D&D conversation, focusing on key story events, character actions, and current situation. Keep it under 300 words:\n\n$contentToSummarize',
      );

      final response = await summarizationChat.sendMessage(summaryRequest);
      return response.text ?? 'Unable to generate summary';
    } catch (e) {
      return 'Previous conversation context (summary unavailable)';
    }
  }

  // Clear cache when needed (e.g., when starting a new conversation)
  void clearCache() {
    _cachedSummary = null;
    _cachedSummaryHash = null;
  }
}
