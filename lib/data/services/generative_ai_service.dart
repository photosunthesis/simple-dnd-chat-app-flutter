import 'package:firebase_ai/firebase_ai.dart';

class GenerativeAiService {
  GenerativeAiService(this._generativeModel);

  static const maxMessagesBeforeSummary = 20;
  static const messagesToKeepAfterSummary = 8;

  final GenerativeModel _generativeModel;

  // Cache for summaries to avoid re-summarizing the same content
  String? _cachedSummary;
  int _lastSummarizedCount = 0;

  Future<String> generateResponse({required List<Content> messages}) async {
    try {
      final optimizedMessages = await _optimizeMessages(messages);
      final chat = _generativeModel.startChat(history: optimizedMessages);
      final response = await chat.sendMessage(optimizedMessages.last);
      return response.text!;
    } catch (e) {
      rethrow;
    }
  }

  // Public method for analytics (optional)
  Future<int> getOptimizedMessageCount(List<Content> messages) async {
    final optimized = await _optimizeMessages(messages);
    return optimized.length;
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

    // Check if we can reuse cached summary
    String summary;
    if (_canReuseCachedSummary(messagesToSummarizeCount)) {
      summary = _cachedSummary!;
    } else {
      summary = await _summarizeMessages(messagesToSummarize);
      _updateCache(summary, messagesToSummarizeCount);
    }

    // Create the optimized message list
    final summaryContent = Content.text(
      'Previous conversation summary: $summary\n\n--- Recent Messages ---',
    );

    return [summaryContent, ...recentMessages];
  }

  bool _canReuseCachedSummary(int messageCount) {
    return _cachedSummary != null && _lastSummarizedCount == messageCount;
  }

  void _updateCache(String summary, int messageCount) {
    _cachedSummary = summary;
    _lastSummarizedCount = messageCount;
  }

  Future<String> _summarizeMessages(List<Content> messages) async {
    try {
      final summaryPrompt = Content.text(
        'Please provide a concise summary of this D&D conversation, focusing on key story events, character actions, and current situation. Keep it under 300 words:',
      );

      // Create a separate chat just for summarization
      final summarizationMessages = [summaryPrompt, ...messages];
      final summaryChat = _generativeModel.startChat(history: []);

      // Send all messages at once for summarization
      final allContent = summarizationMessages
          .map((msg) => msg.toString())
          .join('\n\n');

      final summaryRequest = Content.text(
        'Please provide a concise summary of this D&D conversation, focusing on key story events, character actions, and current situation. Keep it under 300 words:\n\n$allContent',
      );

      final response = await summaryChat.sendMessage(summaryRequest);
      return response.text ?? 'Unable to generate summary';
    } catch (e) {
      return 'Previous conversation context (summary unavailable)';
    }
  }

  // Clear cache when needed (e.g., when starting a new conversation)
  void clearCache() {
    _cachedSummary = null;
    _lastSummarizedCount = 0;
  }
}
