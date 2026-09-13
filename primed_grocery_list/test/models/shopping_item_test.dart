// Unit tests for the ShoppingItem model.
//
// These tests verify:
//  - Default field values when constructing a ShoppingItem
//  - JSON serialisation (toJson) and deserialisation (fromJson)
//  - The static helper listFromJson with valid and invalid input

import 'package:flutter_test/flutter_test.dart';
import 'package:primed_grocery_list/models/shopping_item_model.dart';

void main() {
  // ---------------------------------------------------------------------------
  // Constructor / default values
  // ---------------------------------------------------------------------------
  group('ShoppingItem — default values', () {
    test('bought defaults to false', () {
      final item = ShoppingItem(id: '1', name: 'Milk');
      expect(item.bought, isFalse);
    });

    test('quantity defaults to 1', () {
      final item = ShoppingItem(id: '1', name: 'Milk');
      expect(item.quantity, equals(1));
    });

    test('provided values are stored correctly', () {
      final item = ShoppingItem(id: 'abc', name: 'Eggs', bought: true, quantity: 6);
      expect(item.id, 'abc');
      expect(item.name, 'Eggs');
      expect(item.bought, isTrue);
      expect(item.quantity, 6);
    });
  });

  // ---------------------------------------------------------------------------
  // toJson / fromJson round-trip
  // ---------------------------------------------------------------------------
  group('ShoppingItem — toJson / fromJson', () {
    test('round-trip preserves all fields', () {
      final original = ShoppingItem(id: 'x1', name: 'Bread', bought: true, quantity: 3);
      final json = original.toJson();
      final restored = ShoppingItem.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.name, equals(original.name));
      expect(restored.bought, equals(original.bought));
      expect(restored.quantity, equals(original.quantity));
    });

    test('fromJson uses default bought=false when key is absent', () {
      // Simulate JSON that was saved without the 'bought' key (legacy data).
      final json = {'id': 'y1', 'name': 'Butter', 'quantity': 2};
      final item = ShoppingItem.fromJson(json);
      expect(item.bought, isFalse);
    });

    test('fromJson uses default quantity=1 when key is absent', () {
      final json = {'id': 'y2', 'name': 'Cheese', 'bought': false};
      final item = ShoppingItem.fromJson(json);
      expect(item.quantity, equals(1));
    });
  });

  // ---------------------------------------------------------------------------
  // listFromJson — valid input
  // ---------------------------------------------------------------------------
  group('ShoppingItem.listFromJson — valid JSON', () {
    test('parses a list of two items correctly', () {
      // Build a JSON string the same way the app would persist it.
      final items = [
        ShoppingItem(id: 'a', name: 'Apple', bought: false, quantity: 4),
        ShoppingItem(id: 'b', name: 'Banana', bought: true, quantity: 2),
      ];
      final jsonStr = ShoppingItem.listToJson(items);
      final result = ShoppingItem.listFromJson(jsonStr);

      expect(result.length, 2);
      expect(result[0].id, 'a');
      expect(result[0].name, 'Apple');
      expect(result[1].bought, isTrue);
    });

    test('returns an empty list for an empty JSON array', () {
      final result = ShoppingItem.listFromJson('[]');
      expect(result, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // listFromJson — invalid / malformed input
  // ---------------------------------------------------------------------------
  group('ShoppingItem.listFromJson — invalid JSON', () {
    test('returns [] for a completely empty string', () {
      expect(ShoppingItem.listFromJson(''), isEmpty);
    });

    test('returns [] for non-JSON garbage', () {
      expect(ShoppingItem.listFromJson('not json at all'), isEmpty);
    });

    test('returns [] for a JSON object instead of an array', () {
      // The method expects a JSON array; an object should be handled gracefully.
      expect(ShoppingItem.listFromJson('{"id":"1"}'), isEmpty);
    });
  });
}
