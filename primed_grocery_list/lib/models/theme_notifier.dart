import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The set of available theme colours the user can choose from.
/// Each entry is a display name + the corresponding Color value.
const List<({String label, Color color})> kThemeOptions = [
  (label: 'Green',  color: Color(0xFF4CAF50)),  // default — matches app icon
  (label: 'Orange', color: Colors.orange),
  (label: 'Blue',   color: Colors.blue),
  (label: 'Purple', color: Colors.purple),
  (label: 'Pink',   color: Colors.pink),
  (label: 'Teal',   color: Colors.teal),
];

/// Manages the app's current theme colour and persists it across launches.
class ThemeNotifier extends ChangeNotifier {
  static const _key = 'app_theme_color';

  // Default to green to match the app icon.
  Color _seedColor = const Color(0xFF4CAF50);

  Color get seedColor => _seedColor;

  /// Builds a [ThemeData] using the current seed colour.
  ThemeData get themeData => ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor),
        useMaterial3: true,
      );

  /// Loads the saved colour from SharedPreferences on app start.
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getInt(_key);
    if (value != null) {
      _seedColor = Color(value);
      notifyListeners();
    }
  }

  /// Updates the seed colour and persists the choice.
  Future<void> setColor(Color color) async {
    _seedColor = color;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    // toARGB32() is the modern replacement for the deprecated .value getter.
    await prefs.setInt(_key, color.toARGB32());
  }
}
