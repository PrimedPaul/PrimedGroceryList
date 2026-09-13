import 'package:shared_preferences/shared_preferences.dart';

/// Manages AI re-ordering preferences using SharedPreferences.
/// This lets us remember whether the user has seen the AI re-order prompt
/// and whether they have enabled AI re-ordering, across app restarts.
class CompletionService {
  // The key used to store whether the first-time AI re-order prompt has been shown.
  static const _promptShownKey = 'ai_reorder_prompt_shown';

  // The key used to store the user's AI re-ordering enabled/disabled preference.
  static const _enabledKey = 'ai_reorder_enabled';

  /// Returns true if the first-time AI re-order prompt has already been shown.
  /// On first install the key won't exist, so this returns false.
  static Future<bool> hasShownAiReorderPrompt() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_promptShownKey) ?? false;
  }

  /// Marks the first-time prompt as shown so it won't appear again.
  /// Call this after the prompt is displayed to the user.
  static Future<void> markAiReorderPromptShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_promptShownKey, true);
  }

  /// Returns whether AI re-ordering is enabled.
  /// Defaults to false if the user has never set a preference.
  static Future<bool> getAiReorderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enabledKey) ?? false;
  }

  /// Saves the user's AI re-ordering preference.
  /// Pass true to enable AI re-ordering, false to disable it.
  static Future<void> setAiReorderEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
}
