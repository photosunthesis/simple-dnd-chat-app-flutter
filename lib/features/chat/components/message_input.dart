import 'package:flutter/material.dart';
import '../../../localizations/app_localizations.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({
    required this.controller,
    required this.onSend,
    required this.isLoading,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;

  @override
  State<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends State<MessageInput> {
  bool _hasText = false;
  bool get _canSend => !widget.isLoading && _hasText;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.trim().isNotEmpty;
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.trim().isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outline.withAlpha(51)),
        ),
      ),
      child: SafeArea(
        child: Container(
          constraints: const BoxConstraints(minHeight: 40, maxHeight: 120),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: theme.colorScheme.outline.withAlpha(77)),
          ),
          child: Stack(
            alignment: Alignment.bottomRight,
            children: [
              TextField(
                controller: widget.controller,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: localizations.typeMessage,
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(153),
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.only(
                    left: 16,
                    right: 48,
                    top: 12,
                    bottom: 12,
                  ),
                ),
                style: theme.textTheme.bodyMedium,
                enabled: !widget.isLoading,
              ),
              Positioned(
                right: 6,
                bottom: 8,
                child: Material(
                  color: _canSend
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline.withAlpha(77),
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: _canSend ? widget.onSend : null,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      child: widget.isLoading
                          ? SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _canSend
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.onSurface.withAlpha(
                                          128,
                                        ),
                                ),
                              ),
                            )
                          : Icon(
                              Icons.arrow_upward,
                              size: 18,
                              color: _canSend
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface.withAlpha(128),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
