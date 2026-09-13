# Primed Grocery List — Implementation Plan

> **Status key:** ✅ Done · 🔄 In Progress · ⏳ Pending · 🚫 Blocked

---

## Current State Summary

The app has a solid foundation:
- **Models**: `ShoppingItem` (id, name, bought, quantity), `ShoppingItemList` (id, name, items)
- **State**: `provider` package — `MultiProvider` with `ShoppingItemListNotifier` + `ThemeNotifier`
- **Storage**: `shared_preferences` with `shopping_lists_v1` key
- **Screens**: Home, ShoppingList (edit + shopping mode), OpenList, NameList
- **Features**: Create/open/delete lists, add/remove/reorder items, quantity counter, animated swipe-to-strikethrough, reset cart

---

## MVP Tasks

### ✅ 1. Bug Fixes & Code Cleanup
- Fix double `save()` call in `ShoppingItemListNotifier.setActiveList()`
- Clean up deprecated `add_item_screen.dart` stub file
- Fix broken `widget_test.dart` (references non-existent `ShoppingListModel`)

### ✅ 2. State Management Migration (Provider)
Migrate from manual constructor-passing to the `provider` package.
- Add `provider` to `pubspec.yaml`
- Wrap app with `ChangeNotifierProvider<ShoppingItemListNotifier>` in `main.dart`
- Replace constructor `model:` parameters with `context.watch` / `context.read` across all screens

### ✅ 3. Proper Application Testing
- **Unit tests** for `ShoppingItem` (serialization, defaults)
- **Unit tests** for `ShoppingItemList` (serialization, from/toJson)
- **Unit tests** for `ShoppingItemListNotifier` (add, remove, toggleBought, updateQuantity, reorder, createNewList, deleteList, setActiveList, clearAllBought)
- **Widget tests** for `HomeScreen`, `ShoppingListScreen`, `OpenShoppingListScreen`
- *Depends on: State Management Migration*

### ✅ 4. Units Feature (Long-press Quantity)
Allow each shopping item to have a unit type.
- Add `unit` field (String, default `'qty'`) to `ShoppingItem` — backward-compatible (no schema bump)
- Supported units: `qty`, `dozen`, `half-dozen`, `g`, `kg`, `mg`, `ml`, `L`, `lb`, `oz`
- **Long press** on the quantity badge in edit mode → bottom sheet unit picker
- Display unit abbreviation next to quantity value (e.g. "2 kg", "1 doz", "3")

### ✅ 5. Application Settings Menu
New settings screen accessible via a gear icon in all main screens.

Settings sections:
- **Appearance**: Theme selector
- **Onboarding**: "Show tutorial again" button
- **Support**: Buy Me a Coffee link
- **About**: App version

### ✅ 6. Theme Settings
In Settings → Appearance:
- Preset seed color palette (Green, Orange, Blue, Purple, Pink, Teal)
- Stored in `shared_preferences` (`app_theme_color`)
- Reactive: updates whole app immediately
- Default: Green (to match app icon `#4CAF50`)

### ✅ 7. Buy Me a Coffee Button ☕
- Button on Home Screen (bottom) and in Settings → Support
- Opens buymeacoffee.com URL via `url_launcher`
- Single config constant in `lib/config.dart` — **update `AppConfig.kBuyMeCoffeeUrl` with your username**

### ✅ 8. Feedback / App Rating Prompt
- After 3 shopping sessions, show bottom sheet: *"Enjoying Primed Grocery? ⭐"*
- Options: "Rate Now" (native `in_app_review`) · "Maybe Later" · "Don't Ask Again"
- Track count in `shared_preferences` (`shopping_sessions_count`, `rating_declined`)

### ✅ 9. Application Tutorial (First Use)
- Guided 6-page `PageView` bottom sheet on first launch
- Steps: Welcome → Create list → Add items → Edit mode → Shopping mode → Done
- **Settings → "Show Tutorial Again"** resets the flag and shows immediately

---

## Further Down the Road

| Feature | Notes |
|---|---|
| Shopping complete animation | Display a celebratory animation when shopping is complete (eg when all items stricken in shopping mode) |
| Display last time shopping list was edited | At bottom of screen, show last updated status message at bottom of list when in edit mode only and hide in shopping mode |
| AI-suggested reordering | After shopping is complete and the animation is played (eg all items stricken in shopping mode), through a dialogue, ask the user if they want to enable item re-ordering when shopping is completed. Suggest optimized order (e.g. by aisle/category). The AI-suggested reordering feature can be enabled/disabled in application settings |
| Shopping list history | Archive completed lists, browse past trips |
| Shopping list sharing | Share list via link or QR code |
| Secure online storage | Firebase Firestore sync, account/auth |
| Data governance | Privacy controls, export/delete my data |

---

## Dependency Map

```
bug-fixes          (independent)
state-management   (independent)
    └── testing
    └── settings-screen
        ├── theme-settings
        ├── coffee-button
        └── tutorial
units-feature      (independent)
rating-prompt      (independent)
```
