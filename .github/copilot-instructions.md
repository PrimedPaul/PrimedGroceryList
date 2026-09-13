# Primed Grocery List: Agent Instructions

## Project Shape

- The Flutter project lives in [`primed_grocery_list/`](../primed_grocery_list/).
- The app entry point is [`lib/main.dart`](../primed_grocery_list/lib/main.dart). It loads persisted state before `runApp` and injects the notifiers with `MultiProvider`.
- Models, application state, and list persistence are intentionally centered in [`lib/models/`](../primed_grocery_list/lib/models/). Do not introduce a second state-management pattern without a clear need.
- Screens are in [`lib/screens/`](../primed_grocery_list/lib/screens/); feature-specific preference helpers are static services in [`lib/services/`](../primed_grocery_list/lib/services/).
- Read [`PLAN.md`](../PLAN.md) for the current feature status and future work. Read [`primed_grocery_list/README.md`](../primed_grocery_list/README.md) for the user-facing quick start.

## Working Rules

- Keep changes focused and consistent with the existing Provider architecture. Use `context.watch<T>()` for state needed by `build` and `context.read<T>()` for event-handler mutations.
- `ShoppingItemListNotifier` owns list and item mutations, JSON serialization, and `SharedPreferences` persistence. Mutations should persist before notifying listeners, and should update `lastUpdated` when list contents change.
- `ThemeNotifier` owns the persisted theme seed color. `TutorialService` and `RatingService` own only their respective preference flags and counters.
- The alpha persistence contract uses the `shopping_lists_v1` key. Do not change it for routine features or refactors; a future schema version requires an explicit migration.
- `ShoppingItem.unit` defaults to `qty` so older saved items continue to load. Preserve that fallback when changing serialization.
- Keep async widget code lifecycle-safe: use `mounted` or `context.mounted` after an `await`, and defer dialogs or bottom sheets started during `initState` with `WidgetsBinding.instance.addPostFrameCallback`.
- The rating flow is Android/iOS-only: count explicit completed shopping trips, defer "Maybe Later" by three more completions, and keep unsupported platforms free of native-review calls.
- Display the installed app version through `package_info_plus`; do not hard-code release versions in widgets.
- Prefer small, readable widgets and targeted rebuilds. Dispose timers, controllers, and other owned resources.
- Add or update tests with behavior changes. Keep model/notifier tests in [`test/models/`](../primed_grocery_list/test/models/), service tests in [`test/services/`](../primed_grocery_list/test/services/), and widget coverage in [`test/widget_test.dart`](../primed_grocery_list/test/widget_test.dart). Reset `SharedPreferences` with `setMockInitialValues({})` in tests.

## Validation

Run commands from `primed_grocery_list/`:

```text
flutter pub get
dart format lib/ test/
flutter analyze
flutter test
```

For a manual platform check, use `flutter run`. Do not modify generated `build/` output. Before release work, review the platform identifiers and signing configuration; they are still development defaults.

GitHub Actions runs from `primed_grocery_list/` and is pinned to Flutter `3.41.2`; update the action SHA and Flutter version together in a deliberate maintenance PR.
