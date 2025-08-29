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
  final _messageKeys = <int, GlobalKey>{};

  bool _hasScrolledOnInit = false;

  bool get _isMobile => MediaQuery.of(context).size.width < 600;

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
    return SelectionArea(
      child: Scaffold(
        body: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: BlocConsumer<ChatCubit, ChatState>(
              listener: (context, state) {
                if (state.shouldScrollToLatest &&
                    state.latestMessageIndex >= 0) {
                  _scrollToMessageIndex(state.latestMessageIndex);
                  context.read<ChatCubit>().markScrollCompleted();
                }

                if (!state.loading &&
                    state.messages.isNotEmpty &&
                    !state.hasNewMessage &&
                    !state.shouldScrollToLatest &&
                    !_hasScrolledOnInit) {
                  // Scroll to bottom when messages are first loaded (initialization)
                  _hasScrolledOnInit = true;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (_scrollController.hasClients) {
                      _scrollController.jumpTo(
                        _scrollController.position.maxScrollExtent,
                      );
                    }
                  });
                }
              },
              builder: (context, state) {
                return Stack(
                  children: [
                    state.messages.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.only(
                              top: 20,
                              bottom: 140,
                            ),
                            itemCount: state.messages.length,
                            itemBuilder: (context, index) {
                              final message = state.messages[index];
                              _messageKeys[index] ??= GlobalKey();
                              return ChatMessageWidget(
                                key: _messageKeys[index],
                                message: message,
                              );
                            },
                          ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          MessageInput(
                            controller: _messageInputController,
                            onSend: () => _sendMessage(context),
                            isLoading: state.generatingResponse,
                            isDisabled: state.loading,
                            onClear: () async => _showClearDialog(context),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 100,
        left: MediaQuery.of(context).size.width * (_isMobile ? 0.10 : 0.06),
        right: MediaQuery.of(context).size.width * (_isMobile ? 0.10 : 0.06),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('👋🤠', style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.startAdventure,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(179),
                fontFamily: 'Vidaloka',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.askAnything,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withAlpha(128),
              ),
            ),
          ],
        ),
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

  void _scrollToMessageIndex(int messageIndex) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && messageIndex >= 0) {
        final messageKey = _messageKeys[messageIndex];
        final messageContext = messageKey?.currentContext;

        if (messageContext != null) {
          Scrollable.ensureVisible(
            messageContext,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        } else {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }
    });
  }

  Future<void> _showClearDialog(BuildContext context) async {
    final shouldDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        constraints: const BoxConstraints(maxWidth: 600),
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
