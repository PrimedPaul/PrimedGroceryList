// Widget tests for the Primed Grocery List app.
//
// Each test pumps a minimal widget tree that includes:
//  - ChangeNotifierProvider<ShoppingItemListNotifier> (required by every screen)
//  - MaterialApp (required for navigation and theming)
//
// SharedPreferences.setMockInitialValues({}) is called before each test so
// load() / save() never touch real disk storage.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:primed_grocery_list/app_theme.dart';
import 'package:primed_grocery_list/models/shopping_item_list_model.dart';
import 'package:primed_grocery_list/models/theme_notifier.dart';
import 'package:primed_grocery_list/screens/home_screen.dart';
import 'package:primed_grocery_list/screens/open_shopping_list_screen.dart';

// ---------------------------------------------------------------------------
// Helper — builds the standard app wrapper used by every test in this file.
//
// We supply BOTH providers that the real app uses (ShoppingItemListNotifier
// and ThemeNotifier) so screens like HomeScreen that call
// context.watch<ThemeNotifier>() don't throw a ProviderNotFoundException.
// ---------------------------------------------------------------------------
Widget _buildApp(ShoppingItemListNotifier groceryModel) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<ShoppingItemListNotifier>.value(
          value: groceryModel),
      // ThemeNotifier starts with its default colour — no need to load prefs.
      ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
    ],
    child: MaterialApp(
      title: 'Primed Grocery',
      theme: AppTheme.theme,
      home: const HomeScreen(),
    ),
  );
}

void main() {
  // Reset SharedPreferences to an empty in-memory state before each test.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ---------------------------------------------------------------------------
  // Smoke test
  // ---------------------------------------------------------------------------
  testWidgets('App smoke test — home screen renders',
      (WidgetTester tester) async {
    final model = ShoppingItemListNotifier();

    await tester.pumpWidget(_buildApp(model));
    await tester.pump();

    // The home screen should show the app name and the create-list button.
    expect(find.text('Primed'), findsOneWidget);
    expect(find.text('Create New List'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // "Open Shopping List" button is visible on home screen
  // ---------------------------------------------------------------------------
  testWidgets('Home screen shows "Open Shopping List" button',
      (WidgetTester tester) async {
    final model = ShoppingItemListNotifier();

    await tester.pumpWidget(_buildApp(model));
    await tester.pump();

    // The OutlinedButton.icon that opens the list-of-lists screen.
    expect(find.text('Open Shopping List'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Tapping "Open Shopping List" navigates to the shopping-lists screen
  // ---------------------------------------------------------------------------
  testWidgets(
      'Tapping "Open Shopping List" shows the "Your Shopping Lists" screen',
      (WidgetTester tester) async {
    final model = ShoppingItemListNotifier();

    await tester.pumpWidget(_buildApp(model));
    await tester.pump();

    // Directly invoke the OutlinedButton's onPressed callback.
    // We use this instead of tester.tap() because the large translucent
    // shopping-cart icon in the HomeScreen Stack can interfere with pointer
    // hit-testing in the headless test environment.
    final button = tester.widget<OutlinedButton>(find.byType(OutlinedButton));
    button.onPressed!();

    // Pump the page-route push and let the transition animation finish.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // OpenShoppingListScreen uses 'Your Shopping Lists' as its AppBar title.
    expect(find.text('Your Shopping Lists'), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // "Show Tutorial Again" from the list-of-lists screen opens the tutorial
  // ---------------------------------------------------------------------------
  testWidgets(
      'Settings "Show Tutorial Again" opens the tutorial from the lists screen',
      (WidgetTester tester) async {
    final model = ShoppingItemListNotifier();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ShoppingItemListNotifier>.value(value: model),
          ChangeNotifierProvider<ThemeNotifier>(create: (_) => ThemeNotifier()),
        ],
        child: MaterialApp(
          theme: AppTheme.theme,
          home: const OpenShoppingListScreen(),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('Show Tutorial Again'), findsOneWidget);

    await tester.tap(find.text('Show Tutorial Again'));
    await tester.pumpAndSettle();

    // The tutorial sheet's first page should now be visible.
    expect(find.text('Welcome to Primed Grocery!'), findsOneWidget);
  });
}
