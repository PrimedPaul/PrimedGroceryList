import 'dart:convert';

class ShoppingItem {
  final String id;
  final String name;
  bool bought;

  ShoppingItem({required this.id, required this.name, this.bought = false});

  factory ShoppingItem.fromJson(Map<String, dynamic> json) => ShoppingItem(
        id: json['id'] as String,
        name: json['name'] as String,
        bought: json['bought'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'bought': bought,
      };

  static List<ShoppingItem> listFromJson(String jsonStr) {
    final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
    return data.map((e) => ShoppingItem.fromJson(e as Map<String, dynamic>)).toList();
  }

  static String listToJson(List<ShoppingItem> items) => json.encode(items.map((e) => e.toJson()).toList());
}
