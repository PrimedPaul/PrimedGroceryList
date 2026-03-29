import 'package:flutter/material.dart';

/// Global theme configuration for the app.
/// Change [seedColor] to retheme the entire app.
class AppTheme {
  AppTheme._();

  static const Color seedColor = Colors.orange;

  static ThemeData get theme => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        useMaterial3: true,
      );
}
