import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:simple_ai_dnd_chat_app/data/models/chat_message.dart';
import 'package:simple_ai_dnd_chat_app/localizations/app_localizations.dart';

class ChatMessageWidget extends StatefulWidget {
  const ChatMessageWidget({required this.message, super.key});

  final ChatMessage message;

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with TickerProviderStateMixin {
  late final _fadeController = AnimationController(
    duration: const Duration(milliseconds: 600),
    vsync: this,
  )..value = 1.0;

  late final _fadeAnimation = CurvedAnimation(
    parent: _fadeController,
    curve: Curves.easeInOut,
  );

  late final _thinkingController = AnimationController(
    duration: const Duration(milliseconds: 1500),
    vsync: this,
  )..repeat();

  late final _thinkingAnimation = IntTween(begin: 0, end: 3).animate(
    CurvedAnimation(parent: _thinkingController, curve: Curves.easeInOut),
  );

  ThemeData get theme => Theme.of(context);
  AppLocalizations get localizations => AppLocalizations.of(context)!;

  @override
  void didUpdateWidget(ChatMessageWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if this message transitioned from thinking to actual content
    final wasThinking = oldWidget.message.isThinking;
    final isNowActualContent =
        !widget.message.isThinking &&
        widget.message.content.isNotEmpty &&
        widget.message.role == Role.model;

    if (wasThinking && isNowActualContent) {
      // Reset and start fade animation
      _fadeController.reset();
      _fadeController.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _thinkingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == Role.user;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 40 : 16,
        right: isUser ? 16 : 40,
        top: 8,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) _buildAvatarSection(),
          Expanded(child: _buildMessageContent(isUser)),
          if (isUser) _buildUserAvatarSection(),
        ],
      ),
    );
  }

  Widget _buildAvatarSection() {
    return const Row(
      children: [
        SizedBox(
          width: 44,
          height: 44,
          child: Center(child: Text('🎲', style: TextStyle(fontSize: 24))),
        ),
        SizedBox(width: 12),
      ],
    );
  }

  Widget _buildUserAvatarSection() {
    return const Row(
      children: [
        SizedBox(width: 12),
        SizedBox(
          width: 44,
          height: 44,
          child: Center(child: Text('👤', style: TextStyle(fontSize: 24))),
        ),
      ],
    );
  }

  Widget _buildMessageContent(bool isUser) {
    return Column(
      crossAxisAlignment: isUser
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        if (isUser)
          _buildUserMessage()
        else if (widget.message.isThinking)
          _buildThinkingIndicator()
        else
          _buildModelMessage(),
        if (!widget.message.isThinking) ...[
          SizedBox(height: isUser ? 4 : 0),
          _buildTimestamp(),
        ],
      ],
    );
  }

  Widget _buildUserMessage() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
      ),
      child: _buildMarkdownBody(
        textColor: theme.colorScheme.onSurface,
        ruleColor: theme.colorScheme.tertiary.withAlpha(64),
      ),
    );
  }

  Widget _buildThinkingIndicator() {
    return SizedBox(
      height: 44,
      child: Align(
        alignment: Alignment.centerLeft,
        child: AnimatedBuilder(
          animation: _thinkingAnimation,
          builder: (context, child) {
            final dots = '.' * (_thinkingAnimation.value + 1);
            return Text(
              '${localizations.thinking}$dots',
              style: theme.textTheme.bodyMedium,
            );
          },
        ),
      ),
    );
  }

  Widget _buildModelMessage() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: _buildMarkdownBody(
            ruleColor: theme.colorScheme.outline.withAlpha(64),
          ),
        );
      },
    );
  }

  Widget _buildMarkdownBody({Color? textColor, required Color ruleColor}) {
    return MarkdownBody(
      data: widget.message.content,
      styleSheet: MarkdownStyleSheet(
        p: theme.textTheme.bodyMedium!.copyWith(color: textColor, height: 1.6),
        pPadding: const EdgeInsets.only(bottom: 8),
        code: theme.textTheme.bodyMedium!.copyWith(
          fontFamily: 'IBMPlexMono',
          fontSize: 12,
          height: 1.6,
        ),
        horizontalRuleDecoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: ruleColor, width: 0.5)),
        ),
      ),
    );
  }

  Widget _buildTimestamp() {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Text(
            _formatTime(widget.message.createdAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withAlpha(80),
            ),
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    return switch (difference) {
      Duration(inMinutes: < 1) => localizations.justNow,
      Duration(inHours: < 1) => localizations.minutesAgo(difference.inMinutes),
      Duration(inDays: < 1) => localizations.hoursAgo(difference.inHours),
      _ => localizations.daysAgo(difference.inDays),
    };
  }
}
