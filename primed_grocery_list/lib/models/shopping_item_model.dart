import 'dart:convert';

// All unit types the user can assign to an item's quantity.
// 'qty' is the default (plain number, no label shown).
const List<String> kSupportedUnits = [
  'qty', 'dozen', 'half-dozen', 'g', 'kg', 'mg', 'ml', 'L', 'lb', 'oz',
];

class ShoppingItem {
  final String id;
  String name;
  bool bought;
  int quantity;
  // Unit for the quantity (e.g. 'kg', 'dozen'). Defaults to 'qty' (plain number).
  String unit;

  ShoppingItem({
    required this.id,
    required this.name,
    this.bought = false,
    this.quantity = 1,
    this.unit = 'qty',
  });

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        bought: json['bought'] as bool? ?? false,
        quantity: json['quantity'] as int? ?? 1,
        // Fallback to 'qty' so old saved data (without this field) still loads correctly.
        unit: json['unit'] as String? ?? 'qty',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bought': bought,
        'quantity': quantity,
        'unit': unit,
      };

  static List<ShoppingItem> listFromJson(String jsonStr) {
    try {
      final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
      return data
          .map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static String listToJson(List<ShoppingItem> items) =>
      json.encode(items.map((e) => e.toJson()).toList());
}
