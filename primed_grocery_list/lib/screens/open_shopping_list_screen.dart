import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item_list_model.dart';
import 'shopping_list_screen.dart';
import 'name_shopping_list_screen.dart';
import 'settings_screen.dart';

// OpenShoppingListScreen is now a StatelessWidget.
// context.watch() in build() replaces the old addListener/removeListener
// pattern — Provider automatically rebuilds the widget when the model changes.
class OpenShoppingListScreen extends StatelessWidget {
  const OpenShoppingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // context.watch subscribes to changes so the list rebuilds when lists
    // are added or deleted.
    final model = context.watch<ShoppingItemListNotifier>();
    final lists = model.lists;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Shopping Lists'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: lists.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('No lists yet — create one!'),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.create),
                    label: const Text('Create New List'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                    ),
                    onPressed: () async {
                      final name = await Navigator.of(context).push<String?>(
                        MaterialPageRoute(
                          builder: (_) => const ShoppingListNameScreen(),
                        ),
                      );
                      if (name != null && context.mounted) {
                        // context.read in a callback — no rebuild subscription needed.
                        final m = context.read<ShoppingItemListNotifier>();
                        m.createNewList(name);
                        await m.save();
                        if (context.mounted) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => const ShoppingListScreen(),
                          ));
                        }
                      }
                    },
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: lists.length,
              itemBuilder: (context, index) {
                final list = lists[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    title: Text(list.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${list.items.length} item${list.items.length != 1 ? 's' : ''}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Delete List?'),
                            content: Text('Are you sure you want to delete "${list.name}"?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await context.read<ShoppingItemListNotifier>().deleteList(list.id);
                        }
                      },
                    ),
                    onTap: () async {
                      await context.read<ShoppingItemListNotifier>().setActiveList(list.id);
                      if (context.mounted) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => const ShoppingListScreen(),
                        ));
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
