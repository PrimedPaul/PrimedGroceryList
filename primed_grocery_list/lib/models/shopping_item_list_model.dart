import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shopping_item_model.dart';

class ShoppingItemList {
  final String id;
  String name;
  List<ShoppingItem> items;

  /// The last time this list was modified (items added, removed, or changed).
  /// Null until the list is first mutated after creation.
  DateTime? lastUpdated;

  ShoppingItemList({
    required this.id,
    required this.name,
    List<ShoppingItem>? items,
    this.lastUpdated, // optional; defaults to null
  }) : items = items ?? [];

  factory ShoppingItemList.fromJson(Map<String, dynamic> json) => ShoppingItemList(
        id: json['id'] as String,
        name: json['name'] as String,
        items: json['items'] != null
            ? ShoppingItem.listFromJson(json['items'] as String)
            : [],
        // Parse the ISO-8601 timestamp if present; returns null if missing or invalid.
        lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? ''),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': ShoppingItem.listToJson(items),
        // Only include lastUpdated in JSON when it has been set.
        if (lastUpdated != null) 'lastUpdated': lastUpdated!.toIso8601String(),
      };

  static List<ShoppingItemList> listFromJson(String jsonStr) {
    try {
      final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
      return data
          .map((e) => ShoppingItemList.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static String listToJson(List<ShoppingItemList> lists) =>
      json.encode(lists.map((e) => e.toJson()).toList());
}

class ShoppingItemListNotifier extends ChangeNotifier {
  static const _storageKey = 'shopping_lists_v1';
  static const _activeKey = 'shopping_lists_active';
  List<ShoppingItemList> lists = []; 
  String? _activeListId;
  int _idCounter = 0;

  String _newId() {
    _idCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  String? get activeListId => _activeListId;

  ShoppingItemList? get activeList {
    if (_activeListId == null) return null;
    try {
      return lists.firstWhere((l) => l.id == _activeListId);
    } catch (_) {
      return lists.isNotEmpty ? lists.first : null;
    }
  }

  List<ShoppingItem> get items => activeList?.items ?? [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_storageKey);
    if (s != null && s.isNotEmpty) {
      lists = ShoppingItemList.listFromJson(s);
    } else {
      lists = [];
    }
    _activeListId = prefs.getString(_activeKey);
    if (_activeListId == null && lists.isNotEmpty) {
      _activeListId = lists.first.id;
    }
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, ShoppingItemList.listToJson(lists));
    if (_activeListId != null) {
      await prefs.setString(_activeKey, _activeListId!);
    } else {
      await prefs.remove(_activeKey);
    }
  }

  ShoppingItemList createNewList(String name) {
    final id = _newId();
    final newList = ShoppingItemList(id: id, name: name);
    lists.add(newList);
    _activeListId = id;
    return newList;
  }

  Future<void> deleteList(String id) async {
    lists.removeWhere((l) => l.id == id);
    if (_activeListId == id) {
      _activeListId = lists.isEmpty ? null : lists.first.id;
    }
    await save();
    notifyListeners();
  }

  Future<void> setActiveList(String id) async {
    if (lists.any((l) => l.id == id)) {
      _activeListId = id;
      await save();
      notifyListeners();
    }
  }

  Future<void> renameList(String id, String newName) async {
    final idx = lists.indexWhere((l) => l.id == id);
    if (idx != -1) {
      lists[idx].name = newName;
      await save();
      notifyListeners();
    }
  }

  Future<void> add(String name, {int? index}) async {
    if (_activeListId == null) return;
    final list = lists.firstWhere((l) => l.id == _activeListId);
    final id = _newId();
    final item = ShoppingItem(id: id, name: name);
    if (index != null && index >= 0 && index <= list.items.length) {
      list.items.insert(index, item);
    } else {
      list.items.add(item);
    }
    list.lastUpdated = DateTime.now(); // record when the list was last changed
    await save();
    notifyListeners();
  }

  Future<void> restoreItem(ShoppingItem item, {int? index}) async {
    if (_activeListId == null) return;
    final list = lists.firstWhere((l) => l.id == _activeListId);
    if (index != null && index >= 0 && index <= list.items.length) {
      list.items.insert(index, item);
    } else {
      list.items.add(item);
    }
    list.lastUpdated = DateTime.now();
    await save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    if (_activeListId == null) return;
    final list = lists.firstWhere((l) => l.id == _activeListId);
    list.items.removeWhere((i) => i.id == id);
    list.lastUpdated = DateTime.now();
    await save();
    notifyListeners();
  }

  Future<void> toggleBought(String id) async {
    if (_activeListId == null) return;
    final list = lists.firstWhere((l) => l.id == _activeListId);
    final idx = list.items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      list.items[idx].bought = !list.items[idx].bought;
      list.lastUpdated = DateTime.now();
      await save();
      notifyListeners();
    }
  }

  Future<void> updateQuantity(String id, int quantity) async {
    if (_activeListId == null) return;
    final list = lists.firstWhere((l) => l.id == _activeListId);
    final idx = list.items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      list.items[idx].quantity = quantity.clamp(0, 999);
      list.lastUpdated = DateTime.now();
      await save();
      notifyListeners();
    }
  }

  /// Updates the unit label (e.g. 'kg', 'dozen') for a single item.
  Future<void> updateUnit(String id, String unit) async {
    if (_activeListId == null) return;
    final list = lists.firstWhere((l) => l.id == _activeListId);
    final idx = list.items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      list.items[idx].unit = unit;
      list.lastUpdated = DateTime.now();
      await save();
      notifyListeners();
    }
  }

  Future<void> clearAllBought() async {
    if (_activeListId == null) return;
    final list = lists.firstWhere((l) => l.id == _activeListId);
    for (final item in list.items) {
      item.bought = false;
    }
    list.lastUpdated = DateTime.now();
    await save();
    notifyListeners();
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (_activeListId == null) return;
    final list = lists.firstWhere((l) => l.id == _activeListId);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = list.items.removeAt(oldIndex);
    list.items.insert(newIndex, item);
    list.lastUpdated = DateTime.now();
    await save();
    notifyListeners();
  }
}
