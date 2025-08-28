import 'package:flutter/material.dart';
import 'package:simple_ai_dnd_chat_app/app/colors.dart';

abstract class AppTheme {
  static final instance = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: _colorScheme.surface,
    colorScheme: _colorScheme,
    textTheme: _textTheme,
  );

  static const _colorScheme = ColorScheme.dark(
    primary: AppColors.stone50,
    onPrimary: AppColors.stone900,
    secondary: AppColors.stone500,
    onSecondary: AppColors.stone50,
    tertiary: AppColors.stone700,
    onTertiary: AppColors.stone100,
    surface: AppColors.stone900,
    onSurface: AppColors.stone100,
    surfaceContainerHighest: AppColors.stone800,
    outline: AppColors.stone300,
    outlineVariant: AppColors.stone600,
  );

  static final _textTheme = Typography.material2021().white.copyWith(
    bodyLarge: const TextStyle(
      fontFamily: 'IBMPlexSans',
      color: AppColors.stone100,
      height: 1.6,
    ),
    bodyMedium: const TextStyle(
      fontFamily: 'IBMPlexSans',
      color: AppColors.stone100,
      height: 1.6,
    ),
    bodySmall: const TextStyle(
      fontFamily: 'IBMPlexSans',
      color: AppColors.stone100,
      height: 1.6,
    ),
    headlineLarge: const TextStyle(
      fontFamily: 'IBMPlexSans',
      color: AppColors.stone100,
      height: 1.6,
    ),
    headlineMedium: const TextStyle(
      fontFamily: 'IBMPlexSans',
      color: AppColors.stone100,
      height: 1.6,
    ),
    headlineSmall: const TextStyle(
      fontFamily: 'IBMPlexSans',
      color: AppColors.stone100,
      height: 1.6,
    ),
    titleLarge: const TextStyle(
      fontFamily: 'IBMPlexSans',
      color: AppColors.stone100,
      height: 1.6,
    ),
    titleMedium: const TextStyle(
      fontFamily: 'IBMPlexSans',
      color: AppColors.stone100,
      height: 1.6,
    ),
    titleSmall: const TextStyle(
      fontFamily: 'IBMPlexSans',
      color: AppColors.stone100,
      height: 1.6,
    ),
    labelLarge: const TextStyle(
      fontFamily: 'IBMPlexSans',
      color: AppColors.stone100,
      height: 1.6,
    ),
    labelMedium: const TextStyle(
      fontFamily: 'IBMPlexSans',
      color: AppColors.stone100,
      height: 1.6,
    ),
    labelSmall: const TextStyle(
      fontFamily: 'IBMPlexSans',
      color: AppColors.stone100,
      height: 1.6,
    ),
  );
}
