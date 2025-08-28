import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_ai_dnd_chat_app/features/chat/chat_cubit.dart';
import 'package:simple_ai_dnd_chat_app/features/chat/components/chat_message.dart';
import 'package:simple_ai_dnd_chat_app/features/chat/components/message_input.dart';
import 'package:simple_ai_dnd_chat_app/localizations/app_localizations.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final theme = Theme.of(context);
  late final l10n = AppLocalizations.of(context)!;
  final _messageInputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatCubit>().initialize(
        aiTimeoutError: l10n.aiTimeoutError,
        aiGeneralError: l10n.aiGeneralError,
      );
    });
  }

  @override
  void dispose() {
    _messageInputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          BlocSelector<ChatCubit, ChatState, bool>(
            selector: (state) =>
                state.loading ||
                state.generatingResponse ||
                state.messages.isEmpty,
            builder: (context, disabled) {
              return Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    foregroundColor: theme.colorScheme.onPrimaryContainer,
                  ),
                  onPressed: disabled
                      ? null
                      : () async => _showClearDialog(context),
                  icon: const Icon(Icons.refresh_outlined),
                  tooltip: l10n.clearChat,
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 800),
          child: BlocConsumer<ChatCubit, ChatState>(
            listener: (context, state) {
              if (state.messages.isNotEmpty) _scrollToBottom();
            },
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: state.messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final message = state.messages[index];
                              return ChatMessageWidget(message: message);
                            },
                          ),
                  ),
                  MessageInput(
                    controller: _messageInputController,
                    onSend: () => _sendMessage(context),
                    isLoading: state.generatingResponse,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('ᕙ(＠°▽°＠)ᕗ', style: theme.textTheme.headlineLarge),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: Text(
              l10n.startAdventure,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(179),
                fontFamily: 'Vidaloka',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 56),
            child: Text(
              l10n.askAnything,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(128),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage(BuildContext context) {
    final message = _messageInputController.text.trim();
    if (message.isNotEmpty) {
      context.read<ChatCubit>().sendUserMessage(message);
      _messageInputController.clear();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _showClearDialog(BuildContext context) async {
    final shouldDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          l10n.clearChatTitle,
          style: theme.textTheme.titleLarge!.copyWith(fontFamily: 'Vidaloka'),
        ),
        content: Text(l10n.clearChatConfirmation),
        actions: [
          TextButton(
            onPressed: Navigator.of(context).pop,
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.clear),
          ),
        ],
      ),
    );

    if (shouldDelete == true) {
      await context.read<ChatCubit>().deleteAllMessages();
    }
  }
}
