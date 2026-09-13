import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks how many times the user has entered shopping mode and
/// decides when to prompt them for a review.
class RatingService {
  static const _sessionKey = 'shopping_sessions_count';
  static const _declinedKey = 'rating_declined';
  static const _nextPromptKey = 'rating_next_prompt_session';
  static const int _promptAfterSessions = 3;
  @visibleForTesting
  static bool? debugIsSupportedPlatform;

  static bool get isSupportedPlatform =>
      debugIsSupportedPlatform ??
      (!kIsWeb &&
          (defaultTargetPlatform == TargetPlatform.android ||
              defaultTargetPlatform == TargetPlatform.iOS));

  /// Called when the user completes a shopping trip.
  /// Returns true when the rating prompt should be shown.
  static Future<bool> recordCompletedShoppingSession() async {
    if (!isSupportedPlatform) return false;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_declinedKey) ?? false) return false;
    final count = (prefs.getInt(_sessionKey) ?? 0) + 1;
    await prefs.setInt(_sessionKey, count);
    final nextPrompt = prefs.getInt(_nextPromptKey) ?? _promptAfterSessions;
    return count >= nextPrompt;
  }

  /// Call when the user taps "Rate Now".
  static Future<void> requestReview() async {
    if (!isSupportedPlatform) return;
    final inAppReview = InAppReview.instance;
    try {
      if (await inAppReview.isAvailable()) {
        await inAppReview.requestReview();
      } else {
        await inAppReview.openStoreListing();
      }
    } on MissingPluginException {
      return;
    }
  }

  /// Defers the next prompt until three more completed shopping trips.
  static Future<void> deferReview() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt(_sessionKey) ?? 0;
    await prefs.setInt(_nextPromptKey, count + _promptAfterSessions);
  }

  /// Call when the user taps "Don't Ask Again".
  static Future<void> declineForever() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_declinedKey, true);
  }
}
