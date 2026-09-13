// Unit tests for the ShoppingItemList model.
//
// These tests verify:
//  - toJson / fromJson round-trip for a single list
//  - listFromJson / listToJson helpers with multiple lists
//  - Graceful handling of invalid JSON (returns [])

import 'package:flutter_test/flutter_test.dart';
import 'package:primed_grocery_list/models/shopping_item_model.dart';
import 'package:primed_grocery_list/models/shopping_item_list_model.dart';

void main() {
  // Helper that builds a ShoppingItemList with a couple of items.
  ShoppingItemList makeList({
    String id = 'list1',
    String name = 'Weekly Shop',
    List<ShoppingItem>? items,
  }) {
    return ShoppingItemList(
      id: id,
      name: name,
      items: items ??
          [
            ShoppingItem(id: 'i1', name: 'Milk', quantity: 2),
            ShoppingItem(id: 'i2', name: 'Eggs', bought: true, quantity: 12),
          ],
    );
  }

  // ---------------------------------------------------------------------------
  // Single-list round-trip
  // ---------------------------------------------------------------------------
  group('ShoppingItemList — toJson / fromJson', () {
    test('round-trip preserves id, name and items', () {
      final original = makeList();
      // toJson encodes the item list as a JSON string inside the map.
      final json = original.toJson();
      final restored = ShoppingItemList.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.items.length, equals(original.items.length));
    });

    test('round-trip preserves item fields', () {
      final original = makeList();
      final restored = ShoppingItemList.fromJson(original.toJson());

      final item = restored.items[1]; // 'Eggs'
      expect(item.name, 'Eggs');
      expect(item.bought, isTrue);
      expect(item.quantity, 12);
    });

    test('fromJson handles missing items key (treats as empty list)', () {
      // A JSON map with no 'items' key — items should default to [].
      final json = {'id': 'empty', 'name': 'Empty List'};
      final list = ShoppingItemList.fromJson(json);
      expect(list.items, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // Multiple-list helpers
  // ---------------------------------------------------------------------------
  group('ShoppingItemList — listFromJson / listToJson', () {
    test('round-trip with multiple lists', () {
      final lists = [
        makeList(id: 'l1', name: 'List 1'),
        makeList(id: 'l2', name: 'List 2', items: [
          ShoppingItem(id: 'j1', name: 'Juice'),
        ]),
      ];

      final jsonStr = ShoppingItemList.listToJson(lists);
      final restored = ShoppingItemList.listFromJson(jsonStr);

      expect(restored.length, 2);
      expect(restored[0].id, 'l1');
      expect(restored[1].name, 'List 2');
      expect(restored[1].items.length, 1);
      expect(restored[1].items[0].name, 'Juice');
    });

    test('listFromJson with an empty array returns []', () {
      expect(ShoppingItemList.listFromJson('[]'), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // listFromJson — invalid input
  // ---------------------------------------------------------------------------
  group('ShoppingItemList.listFromJson — invalid JSON', () {
    test('returns [] for an empty string', () {
      expect(ShoppingItemList.listFromJson(''), isEmpty);
    });

    test('returns [] for garbage input', () {
      expect(ShoppingItemList.listFromJson('??bad??'), isEmpty);
    });

    test('returns [] for a JSON object instead of array', () {
      expect(ShoppingItemList.listFromJson('{"id":"1"}'), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // lastUpdated — JSON round-trip
  // ---------------------------------------------------------------------------
  group('ShoppingItemList — lastUpdated round-trip', () {
    test('lastUpdated is preserved through toJson / fromJson', () {
      final now = DateTime.now().toUtc();
      final original = makeList();
      original.lastUpdated = now;

      final restored = ShoppingItemList.fromJson(original.toJson());

      expect(restored.lastUpdated, isNotNull);
      // ISO-8601 round-trip may lose sub-microsecond precision; compare to millisecond.
      expect(
        restored.lastUpdated!.millisecondsSinceEpoch,
        equals(now.millisecondsSinceEpoch),
      );
    });

    test('lastUpdated is null when not set', () {
      final original = makeList(); // lastUpdated not set → null
      final restored = ShoppingItemList.fromJson(original.toJson());
      expect(restored.lastUpdated, isNull);
    });
  });
}
