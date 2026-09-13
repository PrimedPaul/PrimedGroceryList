import 'package:in_app_review/in_app_review.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Tracks how many times the user has entered shopping mode and
/// decides when to prompt them for a review.
class RatingService {
  static const _sessionKey = 'shopping_sessions_count';
  static const _declinedKey = 'rating_declined';
  // Show the prompt after this many shopping-mode entries.
  static const int _promptAfterSessions = 3;

  /// Called each time the user switches to shopping mode.
  /// Returns true when the rating prompt should be shown.
  static Future<bool> recordShoppingSession() async {
    final prefs = await SharedPreferences.getInstance();
    // If the user already declined, never prompt again.
    if (prefs.getBool(_declinedKey) ?? false) return false;
    final count = (prefs.getInt(_sessionKey) ?? 0) + 1;
    await prefs.setInt(_sessionKey, count);
    // Only prompt at exactly the threshold to avoid spamming.
    return count == _promptAfterSessions;
  }

  /// Call when the user taps "Rate Now".
  static Future<void> requestReview() async {
    final inAppReview = InAppReview.instance;
    if (await inAppReview.isAvailable()) {
      await inAppReview.requestReview();
    } else {
      // Fallback: open the store page directly.
      await inAppReview.openStoreListing();
    }
  }

  /// Call when the user taps "Don't Ask Again".
  static Future<void> declineForever() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_declinedKey, true);
  }
}
