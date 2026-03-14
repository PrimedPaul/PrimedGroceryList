import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Item definition moved here so we don't have to keep a separate file.
// The previous version imported `shopping_item.dart`, which was missing
// and caused compile errors.
class ShoppingItem {
  final String id;
  String name;
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

class ShoppingList {
  final String id;
  String name;
  List<ShoppingItem> items;

  ShoppingList({
    required this.id,
    required this.name,
    List<ShoppingItem>? items,
  }) : items = items ?? [];

  factory ShoppingList.fromJson(Map<String, dynamic> json) => ShoppingList(
        id: json['id'] as String,
        name: json['name'] as String,
        items: json['items'] != null
            ? ShoppingItem.listFromJson(json['items'] as String)
            : [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': ShoppingItem.listToJson(items),
      };

  static List<ShoppingList> listFromJson(String jsonStr) {
    try {
      final List<dynamic> data = json.decode(jsonStr) as List<dynamic>;
      return data
          .map((e) => ShoppingList.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  static String listToJson(List<ShoppingList> lists) =>
      json.encode(lists.map((e) => e.toJson()).toList());
}

class ShoppingListModel extends ChangeNotifier {
  static const _storageKey = 'shopping_lists_v2';
  static const _activeKey = 'shopping_lists_active';
  List<ShoppingList> lists = []; 
  String? _activeListId;
  int _idCounter = 0;

  String _newId() {
    _idCounter += 1;
    return '${DateTime.now().microsecondsSinceEpoch}_$_idCounter';
  }

  String? get activeListId => _activeListId;

  ShoppingList? get activeList {
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
      lists = ShoppingList.listFromJson(s);
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
    await prefs.setString(_storageKey, ShoppingList.listToJson(lists));
    if (_activeListId != null) {
      await prefs.setString(_activeKey, _activeListId!);
    } else {
      await prefs.remove(_activeKey);
    }
  }

  ShoppingList createNewList(String name) {
    final id = _newId();
    final newList = ShoppingList(id: id, name: name);
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
    await save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    if (_activeListId == null) return;
    final list = lists.firstWhere((l) => l.id == _activeListId);
    list.items.removeWhere((i) => i.id == id);
    await save();
    notifyListeners();
  }

  Future<void> toggleBought(String id) async {
    if (_activeListId == null) return;
    final list = lists.firstWhere((l) => l.id == _activeListId);
    final idx = list.items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      list.items[idx].bought = !list.items[idx].bought;
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
    await save();
    notifyListeners();
  }
}
