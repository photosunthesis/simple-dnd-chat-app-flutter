import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

class GenerativeAiService {
  const GenerativeAiService(this._generativeModel);

  final GenerativeModel _generativeModel;

  Future<String> generateResponse({required List<Content> messages}) async {
    try {
      final chat = _generativeModel.startChat(history: messages);
      final response = await chat.sendMessage(messages.last);
      return response.text!;
    } catch (e) {
      if (kDebugMode) print(e);
      rethrow;
    }
  }
}
