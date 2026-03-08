import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shopping_item.dart';

class ShoppingListModel extends ChangeNotifier {
  static const _storageKey = 'shopping_items_v1';
  List<ShoppingItem> items = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final s = prefs.getString(_storageKey);
    if (s != null && s.isNotEmpty) {
      items = ShoppingItem.listFromJson(s);
    } else {
      items = [];
    }
    notifyListeners();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, ShoppingItem.listToJson(items));
  }

  Future<void> add(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    items.add(ShoppingItem(id: id, name: name));
    await save();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    items.removeWhere((i) => i.id == id);
    await save();
    notifyListeners();
  }

  Future<void> toggleBought(String id) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      items[idx].bought = !items[idx].bought;
      await save();
      notifyListeners();
    }
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    await save();
    notifyListeners();
  }
}
