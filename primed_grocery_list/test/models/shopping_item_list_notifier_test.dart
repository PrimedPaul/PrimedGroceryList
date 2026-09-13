// Unit tests for ShoppingItemListNotifier.
//
// ShoppingItemListNotifier uses SharedPreferences internally (in save() and
// load()).  We call SharedPreferences.setMockInitialValues({}) in setUp() so
// every test starts with a clean, in-memory store and no real disk I/O happens.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:primed_grocery_list/models/shopping_item_list_model.dart';

void main() {
  // Reset SharedPreferences to a fresh empty state before every test so tests
  // are fully independent of each other.
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // Helper: create a notifier that already has one active list with two items.
  Future<ShoppingItemListNotifier> notifierWithList() async {
    final notifier = ShoppingItemListNotifier();
    notifier.createNewList('Groceries'); // also sets the list as active
    await notifier.add('Milk');
    await notifier.add('Eggs');
    return notifier;
  }

  // ---------------------------------------------------------------------------
  // createNewList
  // ---------------------------------------------------------------------------
  group('createNewList', () {
    test('adds a list and makes it the active list', () {
      final notifier = ShoppingItemListNotifier();
      final list = notifier.createNewList('Test List');

      expect(notifier.lists.length, 1);
      expect(notifier.lists.first.name, 'Test List');
      // The newly created list should immediately be the active one.
      expect(notifier.activeListId, equals(list.id));
    });

    test('each call adds another list', () {
      final notifier = ShoppingItemListNotifier();
      notifier.createNewList('List A');
      notifier.createNewList('List B');

      expect(notifier.lists.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteList
  // ---------------------------------------------------------------------------
  group('deleteList', () {
    test('removes the list with the given id', () async {
      final notifier = ShoppingItemListNotifier();
      final list = notifier.createNewList('To Delete');
      expect(notifier.lists.length, 1);

      await notifier.deleteList(list.id);
      expect(notifier.lists, isEmpty);
    });

    test('activeListId becomes null when the only list is deleted', () async {
      final notifier = ShoppingItemListNotifier();
      final list = notifier.createNewList('Only List');

      await notifier.deleteList(list.id);
      expect(notifier.activeListId, isNull);
    });

    test('activeList switches to first remaining list when active is deleted',
        () async {
      final notifier = ShoppingItemListNotifier();
      final a = notifier.createNewList('A');
      notifier.createNewList('B'); // active becomes B

      // Delete B (the currently active list) — active should fall back to A.
      await notifier.deleteList(notifier.activeListId!);
      expect(notifier.activeListId, equals(a.id));
    });
  });

  // ---------------------------------------------------------------------------
  // setActiveList
  // ---------------------------------------------------------------------------
  group('setActiveList', () {
    test('switches the active list to the specified id', () async {
      final notifier = ShoppingItemListNotifier();
      final a = notifier.createNewList('A');
      final b = notifier.createNewList('B'); // active is now B

      // Switch back to A.
      await notifier.setActiveList(a.id);
      expect(notifier.activeListId, equals(a.id));
      // Silence the "b is unused" warning — we only needed its creation side-effect.
      expect(b.name, isNotEmpty);
    });

    test('does nothing if the id does not exist', () async {
      final notifier = ShoppingItemListNotifier();
      notifier.createNewList('A');
      final originalActiveId = notifier.activeListId;

      await notifier.setActiveList('nonexistent-id');
      // Active list should not have changed.
      expect(notifier.activeListId, equals(originalActiveId));
    });
  });

  // ---------------------------------------------------------------------------
  // renameList
  // ---------------------------------------------------------------------------
  group('renameList', () {
    test('updates the name of the specified list', () async {
      final notifier = ShoppingItemListNotifier();
      final list = notifier.createNewList('Old Name');

      await notifier.renameList(list.id, 'New Name');
      expect(notifier.lists.first.name, 'New Name');
    });

    test('does nothing if the id does not exist', () async {
      final notifier = ShoppingItemListNotifier();
      notifier.createNewList('My List');

      // Should complete without throwing.
      await notifier.renameList('bad-id', 'X');
      expect(notifier.lists.first.name, 'My List');
    });
  });

  // ---------------------------------------------------------------------------
  // add
  // ---------------------------------------------------------------------------
  group('add', () {
    test('appends an item to the active list', () async {
      final notifier = await notifierWithList();
      // notifierWithList already added Milk and Eggs.
      expect(notifier.items.length, 2);

      await notifier.add('Bread');
      expect(notifier.items.length, 3);
      expect(notifier.items.last.name, 'Bread');
    });

    test('inserts at a specific index when index is provided', () async {
      final notifier = await notifierWithList(); // [Milk, Eggs]

      await notifier.add('Bread', index: 1); // insert between Milk and Eggs
      expect(notifier.items[1].name, 'Bread');
      expect(notifier.items[2].name, 'Eggs');
    });

    test('does nothing when there is no active list', () async {
      final notifier = ShoppingItemListNotifier();
      // No list created → _activeListId is null.
      await notifier.add('Ghost Item');
      expect(notifier.items, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // remove
  // ---------------------------------------------------------------------------
  group('remove', () {
    test('removes the item with the given id', () async {
      final notifier = await notifierWithList(); // [Milk, Eggs]
      final milkId = notifier.items.first.id;

      await notifier.remove(milkId);
      expect(notifier.items.length, 1);
      expect(notifier.items.first.name, 'Eggs');
    });

    test('does nothing for an unknown id', () async {
      final notifier = await notifierWithList();
      await notifier.remove('bad-id');
      expect(notifier.items.length, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // toggleBought
  // ---------------------------------------------------------------------------
  group('toggleBought', () {
    test('flips bought from false to true', () async {
      final notifier = await notifierWithList();
      final item = notifier.items.first;
      expect(item.bought, isFalse); // default

      await notifier.toggleBought(item.id);
      expect(notifier.items.first.bought, isTrue);
    });

    test('flips bought from true back to false', () async {
      final notifier = await notifierWithList();
      final item = notifier.items.first;

      await notifier.toggleBought(item.id); // → true
      await notifier.toggleBought(item.id); // → false again
      expect(notifier.items.first.bought, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // updateQuantity
  // ---------------------------------------------------------------------------
  group('updateQuantity', () {
    test('sets the quantity to the given value', () async {
      final notifier = await notifierWithList();
      final itemId = notifier.items.first.id;

      await notifier.updateQuantity(itemId, 5);
      expect(notifier.items.first.quantity, 5);
    });

    test('clamps negative values to 0', () async {
      final notifier = await notifierWithList();
      final itemId = notifier.items.first.id;

      await notifier.updateQuantity(itemId, -10);
      expect(notifier.items.first.quantity, 0);
    });

    test('clamps values above 999 to 999', () async {
      final notifier = await notifierWithList();
      final itemId = notifier.items.first.id;

      await notifier.updateQuantity(itemId, 5000);
      expect(notifier.items.first.quantity, 999);
    });
  });

  // ---------------------------------------------------------------------------
  // updateUnit
  // ---------------------------------------------------------------------------
  group('updateUnit', () {
    test('updates, persists, and timestamps an item unit', () async {
      final notifier = await notifierWithList();
      final itemId = notifier.items.first.id;
      notifier.activeList!.lastUpdated = null;

      await notifier.updateUnit(itemId, 'kg');

      expect(notifier.items.first.unit, equals('kg'));
      expect(notifier.activeList?.lastUpdated, isNotNull);

      final reloaded = ShoppingItemListNotifier();
      await reloaded.load();
      expect(reloaded.items.first.unit, equals('kg'));
    });
  });

  // ---------------------------------------------------------------------------
  // reorder
  // ---------------------------------------------------------------------------
  group('reorder', () {
    test('moves item forward in the list', () async {
      final notifier = await notifierWithList(); // [Milk(0), Eggs(1)]
      await notifier.add('Bread'); // [Milk(0), Eggs(1), Bread(2)]

      // Move Milk (index 0) to after Bread → [Eggs, Bread, Milk]
      // Flutter's ReorderableListView passes newIndex = oldIndex+3 when
      // dragging to the end of a 3-item list, so we replicate that here.
      await notifier.reorder(0, 3);
      expect(notifier.items[0].name, 'Eggs');
      expect(notifier.items[1].name, 'Bread');
      expect(notifier.items[2].name, 'Milk');
    });

    test('moves item backward in the list', () async {
      final notifier = await notifierWithList(); // [Milk(0), Eggs(1)]
      await notifier.add('Bread'); // [Milk(0), Eggs(1), Bread(2)]

      // Move Bread (index 2) to position 0 → [Bread, Milk, Eggs]
      await notifier.reorder(2, 0);
      expect(notifier.items[0].name, 'Bread');
      expect(notifier.items[1].name, 'Milk');
      expect(notifier.items[2].name, 'Eggs');
    });
  });

  // ---------------------------------------------------------------------------
  // clearAllBought
  // ---------------------------------------------------------------------------
  group('clearAllBought', () {
    test('sets all items back to bought=false', () async {
      final notifier = await notifierWithList();

      // Mark all items as bought.
      for (final item in notifier.items) {
        await notifier.toggleBought(item.id);
      }
      expect(notifier.items.every((i) => i.bought), isTrue);

      // Now clear them all.
      await notifier.clearAllBought();
      expect(notifier.items.every((i) => !i.bought), isTrue);
    });

    test('does nothing when there are no items', () async {
      final notifier = ShoppingItemListNotifier();
      notifier.createNewList('Empty');
      // Should complete without throwing.
      await notifier.clearAllBought();
      expect(notifier.items, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // restoreItem
  // ---------------------------------------------------------------------------
  group('restoreItem', () {
    test('re-inserts item at the specified index', () async {
      final notifier = await notifierWithList(); // [Milk, Eggs]
      final milkId = notifier.items.first.id;

      // Remove Milk, then restore it at index 1 (between nothing and Eggs).
      final milk = notifier.items.first;
      await notifier.remove(milkId); // [Eggs]
      await notifier.restoreItem(milk, index: 0); // back to [Milk, Eggs]

      expect(notifier.items.length, 2);
      expect(notifier.items[0].name, 'Milk');
    });

    test('appends item when no index is given', () async {
      final notifier = await notifierWithList(); // [Milk, Eggs]
      final milk = notifier.items.first;
      await notifier.remove(milk.id); // [Eggs]

      await notifier.restoreItem(milk); // append → [Eggs, Milk]
      expect(notifier.items.last.name, 'Milk');
    });
  });

  // ---------------------------------------------------------------------------
  // lastUpdated — set by mutating methods
  // ---------------------------------------------------------------------------
  group('lastUpdated', () {
    test('is null before any mutation', () {
      final notifier = ShoppingItemListNotifier();
      notifier.createNewList('Fresh List');
      // No items have been added or changed yet.
      expect(notifier.activeList?.lastUpdated, isNull);
    });

    test('is set after add', () async {
      final notifier = ShoppingItemListNotifier();
      notifier.createNewList('Test');
      final before = DateTime.now();
      await notifier.add('Apple');
      final after = DateTime.now();

      final ts = notifier.activeList?.lastUpdated;
      expect(ts, isNotNull);
      // The timestamp should fall within the window of this test.
      expect(ts!.isAfter(before) || ts.isAtSameMomentAs(before), isTrue);
      expect(ts.isBefore(after) || ts.isAtSameMomentAs(after), isTrue);
    });

    test('is set after remove', () async {
      final notifier = await notifierWithList(); // [Milk, Eggs]
      // Reset lastUpdated so we can confirm remove sets it freshly.
      notifier.activeList!.lastUpdated = null;

      await notifier.remove(notifier.items.first.id);
      expect(notifier.activeList?.lastUpdated, isNotNull);
    });

    test('is set after toggleBought', () async {
      final notifier = await notifierWithList();
      notifier.activeList!.lastUpdated = null;

      await notifier.toggleBought(notifier.items.first.id);
      expect(notifier.activeList?.lastUpdated, isNotNull);
    });
  });
}
