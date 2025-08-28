import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:simple_ai_dnd_chat_app/app/app.dart';
import 'package:simple_ai_dnd_chat_app/config/firebase_options.dart';
import 'package:simple_ai_dnd_chat_app/constants/ai_system_instructions.dart';
import 'package:simple_ai_dnd_chat_app/data/models/chat_message.dart';

void main() {
  runZoned(() async {
    WidgetsFlutterBinding.ensureInitialized();

    LicenseRegistry.addLicense(() async* {
      final licenses = await Future.wait([
        rootBundle.loadString('assets/fonts/ibm_plex_sans/OFL.txt'),
        rootBundle.loadString('assets/fonts/ibm_plex_mono/OFL.txt'),
        rootBundle.loadString('assets/fonts/vidaloka/OFL.txt'),
      ]);
      yield LicenseEntryWithLineBreaks(['IBMPlexSans'], licenses[0]);
      yield LicenseEntryWithLineBreaks(['IBMPlexMono'], licenses[1]);
      yield LicenseEntryWithLineBreaks(['Vidaloka'], licenses[2]);
    });

    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await Hive.initFlutter();
    Hive.registerAdapter(ChatMessageAdapter());

    final chatMessagesBox = await Hive.openBox<ChatMessage>('chat_messages');

    final generativeModel = FirebaseAI.googleAI().generativeModel(
      model: 'gemini-2.5-flash-lite',
      safetySettings: [
        SafetySetting(
          HarmCategory.sexuallyExplicit,
          HarmBlockThreshold.none,
          null,
        ),
      ],
      systemInstruction: Content.system(AiSystemInstructions.systemPrompt),
    );

    runApp(App(chatMessagesBox, generativeModel));
  });
}
