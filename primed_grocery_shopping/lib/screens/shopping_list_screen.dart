import 'package:flutter/material.dart';
import '../models/shopping_list_model.dart';
// AddItemScreen is defined at the bottom of this file so we don't have
// to depend on a separate file that may be missing.


class ShoppingListScreen extends StatefulWidget {
  final ShoppingListModel model;
  const ShoppingListScreen({super.key, required this.model});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // track which view is active; editing by default
  bool _editingView = true;
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
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _editingView = editing;
    });
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    final deletedIndex = widget.model.items.indexOf(item);
    await widget.model.remove(item.id);
    if (!mounted) return;

    final deletedItem = item;
    final deletedItemId = item.id;

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${item.name}'),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await widget.model.restoreItem(deletedItem, index: deletedIndex);
            if (!mounted) return;
            if (_newItemId == deletedItemId) {
              setState(() {
                _newItemId = null;
              });
            }
          },
        ),
      ),
    );
  }

  Widget _buildList() {
    final items = widget.model.items;
    return ReorderableListView.builder(
      itemCount: items.length,
      autoScrollerVelocityScalar: 50.0,
      onReorder: (oldIndex, newIndex) =>
          widget.model.reorder(oldIndex, newIndex),
      itemBuilder: (context, index) =>
          _buildItem(items[index], isReorderable: true, index: index),
    );
  }

  Widget _buildItem(ShoppingItem item, {required bool isReorderable, required int index}) {
    // Enable swipe actions in both modes: delete in edit mode, mark as bought in shopping mode
    final dismissDirection = DismissDirection.endToStart;
    final confirmDismiss = (DismissDirection direction) async {
      if (!_editingView) {
        await widget.model.toggleBought(item.id);
        return false;
      }
      return true;
    };
    final onDismissed =
        _editingView ? (DismissDirection direction) => _deleteItem(item) : null;
    final background = _editingView
        ? Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red,
            child: const Icon(Icons.delete, color: Colors.white),
          )
        : Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.green,
            child: const Icon(Icons.check, color: Colors.white),
          );
    final itemDecoration = _isPlacingNewItem && item.id == _newItemId
        ? BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            border: Border.all(color: Colors.blue, width: 2),
          )
        : (!_editingView && item.bought)
            ? BoxDecoration(
                color: Colors.green.withOpacity(0.2),
              )
            : null;
    final child = Container(
      decoration: itemDecoration,
      child: ListTile(
        leading: null,
        title: Text(item.name,
            style: TextStyle(
                decoration: (!_editingView && item.bought) ? TextDecoration.lineThrough : null,
                color: item.bought ? Colors.black87 : null)),
        trailing: isReorderable
            ? ReorderableDragStartListener(
                index: index,
                child: const Icon(Icons.drag_handle),
              )
            : const Icon(Icons.drag_handle),
      ),
    );
    return Dismissible(
      key: ValueKey(item.id),
      direction: dismissDirection,
      confirmDismiss: confirmDismiss,
      onDismissed: onDismissed,
      background: background,
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.model.items;
    final listName = widget.model.activeList?.name ?? 'Shopping List';
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(listName)),
        body: Stack(
          children: [
            items.isEmpty
                ? const Center(child: Text('No items yet — add one!'))
                : _buildList(),
            Positioned(
              left: 16,
              bottom: 16,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: ToggleButtons(
                  isSelected: [_editingView, !_editingView],
                  onPressed: (index) => _toggleView(index == 0),
                  borderRadius: BorderRadius.circular(28),
                  renderBorder: false,
                  constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                  children: const [
                    Icon(Icons.edit, semanticLabel: 'Edit mode'),
                    Icon(Icons.shopping_cart, semanticLabel: 'Shopping mode'),
                  ],
                ),
              ),
            ),
            if (_editingView)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  tooltip: _isPlacingNewItem ? 'Done placing item' : 'Add item',
                  onPressed: _isPlacingNewItem
                      ? () {
                          setState(() {
                            _isPlacingNewItem = false;
                            _newItemId = null;
                          });
                        }
                      : () async {
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
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
                            // Auto-clear the highlight after a delay
                            Future.delayed(const Duration(seconds: 5), () {
                              if (mounted && _isPlacingNewItem) {
                                setState(() {
                                  _isPlacingNewItem = false;
                                  _newItemId = null;
                                });
                              }
                            });
                          }
                        },
                  child: Icon(_isPlacingNewItem ? Icons.check : Icons.add),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


// ---------------------------------------------------------------------------
// Helper screen for entering a new item name.  Placed in the same file so we
// don't depend on an external asset that might be missing when the repo is
// restored.

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // select all text when the screen appears (even though the field is
    // initially empty, this matches the pattern we used for naming lists)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _controller.text.length,
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      Navigator.of(context).pop(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Item name',
                hintText: 'e.g., Milk',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}
