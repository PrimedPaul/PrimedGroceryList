import 'package:flutter/material.dart';
import '../models/shopping_list_model.dart';
import '../models/shopping_item.dart';
import 'add_item_screen.dart';

class ShoppingListScreen extends StatefulWidget {
  final ShoppingListModel model;
  const ShoppingListScreen({super.key, required this.model});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // track which view is active; editing by default
  bool _editingView = true;
  ShoppingItem? _lastDeletedItem;
  bool _isPlacingNewItem = false;
  String? _newItemId;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModel);
  }

  @override
  void dispose() {
    widget.model.removeListener(_onModel);
    super.dispose();
  }

  void _onModel() => setState(() {});

  void _toggleView(bool editing) {
    setState(() {
      _editingView = editing;
    });
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    setState(() {
      _lastDeletedItem = item;
      widget.model.remove(item.id);
    });
    final snackBar = SnackBar(
      content: Text('Deleted ${item.name}'),
      duration: const Duration(seconds: 4),
      action: SnackBarAction(
        label: 'Undo',
        onPressed: () async {
          if (_lastDeletedItem != null) {
            await widget.model.add(_lastDeletedItem!.name);
            setState(() => _lastDeletedItem = null);
          }
        },
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar).closed.then((reason) {
      if (reason != SnackBarClosedReason.action) {
        setState(() => _lastDeletedItem = null);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.model.items;
    return Scaffold(
      appBar: AppBar(title: const Text('Shopping List')),
      body: items.isEmpty
          ? const Center(child: Text('No items yet — add one!'))
          : _isPlacingNewItem
              ? ReorderableListView.builder(
                  itemCount: items.length,
                  autoScrollerVelocityScalar: 50.0,
                  onReorder: (oldIndex, newIndex) =>
                      widget.model.reorder(oldIndex, newIndex),
                  itemBuilder: (context, index) {
                    final ShoppingItem item = items[index];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: item.id == _newItemId ? DismissDirection.none : DismissDirection.endToStart,
                      onDismissed: (direction) => _deleteItem(item),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.red,
                        child: const Icon(Icons.delete, color: Colors.white),
                      ),
                      child: Container(
                        decoration: item.id == _newItemId
                            ? BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                border: Border.all(color: Colors.blue, width: 2),
                              )
                            : null,
                        child: ListTile(
                          leading: _editingView ? null : Checkbox(
                            value: item.bought,
                            onChanged: item.id == _newItemId
                                ? null
                                : (_) => widget.model.toggleBought(item.id),
                          ),
                          title: Text(item.name,
                              style: TextStyle(
                                  decoration: item.bought
                                      ? TextDecoration.lineThrough
                                      : null)),
                          trailing: const Icon(Icons.drag_handle),
                        ),
                      ),
                    );
                  },
                )
              : ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final ShoppingItem item = items[index];
                    return Dismissible(
                      key: ValueKey(item.id),
                      direction: _editingView ? (item.id == _newItemId ? DismissDirection.none : DismissDirection.endToStart) : DismissDirection.startToEnd,
                      onDismissed: _editingView ? (direction) => _deleteItem(item) : (direction) => widget.model.toggleBought(item.id),
                      background: _editingView
                          ? Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              color: Colors.red,
                              child: const Icon(Icons.delete, color: Colors.white),
                            )
                          : Container(
                              alignment: Alignment.centerLeft,
                              padding: const EdgeInsets.only(left: 20),
                              color: Colors.green,
                              child: const Icon(Icons.check, color: Colors.white),
                            ),
                      child: ListTile(
                        leading: _editingView ? null : Checkbox(
                          value: item.bought,
                          onChanged: (_) => widget.model.toggleBought(item.id),
                        ),
                        title: Text(item.name,
                            style: TextStyle(
                                decoration: item.bought
                                    ? TextDecoration.lineThrough
                                    : null)),
                        trailing: _editingView ? const Icon(Icons.drag_handle) : null,
                      ),
                    );
                  },
                ),
      floatingActionButton: _editingView
          ? FloatingActionButton(
              onPressed: _isPlacingNewItem
                  ? () => setState(() => _isPlacingNewItem = false)
                  : () async {
                      final name = await Navigator.of(context).push<String?>(
                        MaterialPageRoute(
                            builder: (_) => const AddItemScreen()),
                      );
                      if (name != null && name.isNotEmpty) {
                        await widget.model.add(name);
                        final newItem = widget.model.items.last;
                        setState(() {
                          _isPlacingNewItem = true;
                          _newItemId = newItem.id;
                        });
                        // Move to middle
                        final currentIndex = widget.model.items.length - 1;
                        final middleIndex = widget.model.items.length ~/ 2;
                        if (currentIndex != middleIndex) {
                          await widget.model.reorder(currentIndex, middleIndex);
                        }
                      }
                    },
              child: Icon(_isPlacingNewItem ? Icons.check : Icons.add),
            )
          : null,
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: ToggleButtons(
            isSelected: [_editingView, !_editingView],
            onPressed: (index) => _toggleView(index == 0),
            children: const [
              Icon(Icons.edit, semanticLabel: 'List editing view'),
              Icon(Icons.shopping_cart, semanticLabel: 'Shopping view'),
            ],
          ),
        ),
      ),
    );
  }
}
