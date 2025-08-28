import 'package:flutter/material.dart';
import 'package:markdown/markdown.dart' as md;
import 'package:simple_ai_dnd_chat_app/data/models/chat_message.dart';
import 'package:simple_ai_dnd_chat_app/localizations/app_localizations.dart';

class ChatMessageWidget extends StatefulWidget {
  const ChatMessageWidget({required this.message, super.key});

  final ChatMessage message;

  @override
  State<ChatMessageWidget> createState() => _ChatMessageWidgetState();
}

class _ChatMessageWidgetState extends State<ChatMessageWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late final theme = Theme.of(context);
  late final localizations = AppLocalizations.of(context)!;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );

    // Always start with full opacity for initial render
    _fadeController.value = 1.0;
  }

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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUser = widget.message.role == Role.user;

    return Padding(
      padding: EdgeInsets.only(
        left: isUser ? 64 : 16,
        right: isUser ? 16 : 64,
        top: 8,
        bottom: 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withAlpha(51),
              ),
              child: const Center(
                child: Text('🎲', style: TextStyle(fontSize: 18)),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: isUser
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                if (isUser)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: SelectableText(
                      widget.message.content,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  )
                else if (widget.message.isThinking)
                  _ThinkingIndicator(
                    localizations: localizations,
                    style: theme.textTheme.bodyMedium,
                  )
                else
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: _MarkdownText(
                          content: widget.message.content,
                          style: theme.textTheme.bodyMedium,
                        ),
                      );
                    },
                  ),
                if (!widget.message.isThinking) ...[
                  const SizedBox(height: 4),
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _fadeAnimation.value,
                        child: SelectableText(
                          _formatTime(widget.message.createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withAlpha(153),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 12),
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.secondary.withAlpha(51),
              ),
              child: const Center(
                child: Text('⚔️', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return localizations.justNow;
    } else if (difference.inHours < 1) {
      return localizations.minutesAgo(difference.inMinutes);
    } else if (difference.inDays < 1) {
      return localizations.hoursAgo(difference.inHours);
    } else {
      return localizations.daysAgo(difference.inDays);
    }
  }
}

class _MarkdownText extends StatelessWidget {
  const _MarkdownText({required this.content, required this.style});

  final String content;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final document = md.Document(
      extensionSet: md.ExtensionSet.gitHubFlavored,
      encodeHtml: false,
    );

    final nodes = document.parseLines(content.split('\n'));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: nodes.map((node) => _buildNode(context, node, theme)).toList(),
    );
  }

  Widget _buildNode(BuildContext context, md.Node node, ThemeData theme) {
    if (node is md.Element) {
      switch (node.tag) {
        case 'h1':
        case 'h2':
        case 'h3':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SelectableText(
              node.textContent,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        case 'p':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: _buildInlineContent(context, node, theme),
          );
        case 'code':
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withAlpha(26),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha(51),
              ),
            ),
            child: SelectableText(
              node.textContent,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontFamily: 'IBMPlexMono',
              ),
            ),
          );
        case 'ul':
        case 'ol':
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children:
                  node.children?.map((child) {
                    if (child is md.Element && child.tag == 'li') {
                      return Padding(
                        padding: const EdgeInsets.only(left: 16, bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SelectableText('• ', style: style),
                            Expanded(
                              child: _buildInlineContent(context, child, theme),
                            ),
                          ],
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  }).toList() ??
                  [],
            ),
          );
        default:
          return _buildInlineContent(context, node, theme);
      }
    } else {
      return SelectableText(node.textContent, style: style);
    }
  }

  Widget _buildInlineContent(
    BuildContext context,
    md.Element element,
    ThemeData theme,
  ) {
    final spans = <TextSpan>[];

    for (final child in element.children ?? []) {
      if (child is md.Text) {
        spans.add(TextSpan(text: child.text, style: style));
      } else if (child is md.Element) {
        switch (child.tag) {
          case 'strong':
          case 'b':
            spans.add(
              TextSpan(
                text: child.textContent,
                style: style?.copyWith(fontWeight: FontWeight.bold),
              ),
            );
            break;
          case 'em':
          case 'i':
            spans.add(
              TextSpan(
                text: child.textContent,
                style: style?.copyWith(fontStyle: FontStyle.italic),
              ),
            );
            break;
          case 'code':
            spans.add(
              TextSpan(
                text: child.textContent,
                style: style?.copyWith(
                  fontFamily: 'IBMPlexMono',
                  backgroundColor: theme.colorScheme.surface.withAlpha(26),
                ),
              ),
            );
            break;
          default:
            spans.add(TextSpan(text: child.textContent, style: style));
        }
      }
    }

    return SelectableText.rich(TextSpan(children: spans));
  }
}

class _ThinkingIndicator extends StatefulWidget {
  const _ThinkingIndicator({required this.localizations, required this.style});

  final AppLocalizations localizations;
  final TextStyle? style;

  @override
  State<_ThinkingIndicator> createState() => _ThinkingIndicatorState();
}

class _ThinkingIndicatorState extends State<_ThinkingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<int> _dotAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _dotAnimation = IntTween(begin: 0, end: 3).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotAnimation,
      builder: (context, child) {
        final dots = '.' * _dotAnimation.value;
        return SelectableText(
          '${widget.localizations.thinking}$dots',
          style: widget.style?.copyWith(
            fontStyle: FontStyle.italic,
            color: widget.style?.color?.withAlpha(179),
          ),
        );
      },
    );
  }
}
