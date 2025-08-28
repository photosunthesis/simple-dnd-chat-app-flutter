import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:simple_ai_dnd_chat_app/app/theme.dart';
import 'package:simple_ai_dnd_chat_app/data/models/chat_message.dart';
import 'package:simple_ai_dnd_chat_app/data/repositories/chat_messages_repository.dart';
import 'package:simple_ai_dnd_chat_app/data/services/generative_ai_service.dart';
import 'package:simple_ai_dnd_chat_app/features/chat/chat_cubit.dart';
import 'package:simple_ai_dnd_chat_app/features/chat/chat_screen.dart';
import 'package:simple_ai_dnd_chat_app/localizations/app_localizations.dart';

class App extends StatelessWidget {
  const App(this._chatMessagesBox, this._generativeModel, {super.key});

  final Box<ChatMessage> _chatMessagesBox;
  final GenerativeModel _generativeModel;

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: FirebaseAnalytics.instance),
        RepositoryProvider(
          create: (_) => GenerativeAiService(_generativeModel),
        ),
        RepositoryProvider(
          create: (_) => ChatMessagesRepository(_chatMessagesBox),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.instance,
        themeMode: ThemeMode.dark,
        debugShowCheckedModeBanner: false,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: BlocProvider(
          create: (context) =>
              ChatCubit(context.read(), context.read(), context.read()),
          child: const ChatScreen(),
        ),
      ),
    );
  }
}
