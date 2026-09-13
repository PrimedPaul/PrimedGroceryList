import 'package:shared_preferences/shared_preferences.dart';

/// Manages the first-use tutorial state using SharedPreferences.
/// This lets us remember whether the user has already seen the tutorial
/// across app restarts.
class TutorialService {
  // The key used to store the tutorial-shown flag in SharedPreferences.
  static const _key = 'tutorial_shown';

  /// Returns true if the tutorial has NOT been shown yet.
  /// On first install, the key won't exist, so this returns true.
  static Future<bool> shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key) ?? false);
  }

  /// Marks the tutorial as shown so it won't appear again automatically.
  /// Call this after the user completes or skips the tutorial.
  static Future<void> markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Resets the tutorial flag so it will appear again on next launch.
  /// Called from the "Show Tutorial Again" setting.
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
