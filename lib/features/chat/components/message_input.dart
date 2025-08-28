import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:simple_ai_dnd_chat_app/features/chat/chat_cubit.dart';
import 'package:simple_ai_dnd_chat_app/localizations/app_localizations.dart';

class MessageInput extends StatefulWidget {
  const MessageInput({
    required this.controller,
    required this.onSend,
    required this.isLoading,
    required this.isDisabled,
    this.onClear,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isLoading;
  final bool isDisabled;
  final VoidCallback? onClear;

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

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent && event.logicalKey == LogicalKeyboardKey.enter) {
      if (HardwareKeyboard.instance.isShiftPressed) {
        return KeyEventResult.ignored;
      }

      if (_canSend) {
        widget.onSend();
        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = AppLocalizations.of(context)!;

    return SafeArea(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          _buildInputContainer(theme, localizations),
          _buildSendButton(theme),
        ],
      ),
    );
  }

  Widget _buildInputContainer(ThemeData theme, AppLocalizations localizations) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            theme.scaffoldBackgroundColor.withAlpha(0),
            theme.scaffoldBackgroundColor,
            theme.scaffoldBackgroundColor,
            theme.scaffoldBackgroundColor,
            theme.scaffoldBackgroundColor,
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildTextField(theme, localizations),
          _buildClearChatButton(theme, localizations),
        ],
      ),
    );
  }

  Widget _buildTextField(ThemeData theme, AppLocalizations localizations) {
    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: TextField(
        controller: widget.controller,
        maxLines: 4,
        minLines: 1,
        textCapitalization: TextCapitalization.sentences,
        onTapOutside: (_) => FocusScope.of(context).unfocus(),
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.newline,
        decoration: _buildInputDecoration(theme, localizations),
        style: theme.textTheme.bodyMedium,
        enabled: !widget.isLoading,
      ),
    );
  }

  InputDecoration _buildInputDecoration(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    final borderSide = BorderSide(
      color: theme.colorScheme.outlineVariant.withAlpha(120),
    );
    final borderRadius = BorderRadius.circular(18);

    return InputDecoration(
      hintText: localizations.typeMessage,
      hintStyle: theme.textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurface.withAlpha(153),
      ),
      border: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: borderSide,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: borderSide,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: borderSide,
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: borderSide,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: borderSide,
      ),
      disabledBorder: OutlineInputBorder(
        borderRadius: borderRadius,
        borderSide: borderSide,
      ),
      contentPadding: const EdgeInsets.only(
        left: 16,
        right: 48,
        top: 12,
        bottom: 12,
      ),
    );
  }

  Widget _buildClearChatButton(
    ThemeData theme,
    AppLocalizations localizations,
  ) {
    return BlocSelector<ChatCubit, ChatState, bool>(
      selector: (state) =>
          state.loading || state.generatingResponse || state.messages.isEmpty,
      builder: (context, disabled) {
        return Container(
          padding: const EdgeInsets.only(top: 10),
          child: GestureDetector(
            onTap: disabled ? null : widget.onClear?.call,
            child: Text(
              localizations.clearChat,
              style: theme.textTheme.bodySmall?.copyWith(
                decoration: TextDecoration.underline,
                color: disabled
                    ? theme.colorScheme.onSurface.withAlpha(128)
                    : theme.colorScheme.primary,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendButton(ThemeData theme) {
    return Positioned(
      right: 16,
      bottom: 49,
      child: Material(
        color: _canSend
            ? theme.colorScheme.primary
            : theme.colorScheme.outline.withAlpha(77),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: _canSend ? widget.onSend : null,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            child: _buildSendButtonContent(theme),
          ),
        ),
      ),
    );
  }

  Widget _buildSendButtonContent(ThemeData theme) {
    if (widget.isLoading) {
      return SizedBox(
        width: 14,
        height: 14,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            _canSend && !widget.isDisabled
                ? theme.colorScheme.onPrimary
                : theme.colorScheme.onSurface.withAlpha(128),
          ),
        ),
      );
    }

    return Icon(
      Icons.arrow_upward,
      size: 18,
      color: _canSend
          ? theme.colorScheme.onPrimary
          : theme.colorScheme.onSurface.withAlpha(128),
    );
  }
}
