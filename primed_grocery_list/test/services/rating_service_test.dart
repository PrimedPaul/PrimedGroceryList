import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:primed_grocery_list/services/rating_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    RatingService.debugIsSupportedPlatform = true;
  });

  tearDown(() {
    RatingService.debugIsSupportedPlatform = null;
  });

  test('Maybe Later schedules the next prompt after three more sessions',
      () async {
    expect(await RatingService.recordCompletedShoppingSession(), isFalse);
    expect(await RatingService.recordCompletedShoppingSession(), isFalse);
    expect(await RatingService.recordCompletedShoppingSession(), isTrue);

    await RatingService.deferReview();

    expect(await RatingService.recordCompletedShoppingSession(), isFalse);
    expect(await RatingService.recordCompletedShoppingSession(), isFalse);
    expect(await RatingService.recordCompletedShoppingSession(), isTrue);
  });

  test('declining a review prevents future prompts', () async {
    await RatingService.declineForever();
    expect(await RatingService.recordCompletedShoppingSession(), isFalse);
  });
}
