import 'package:flutter/material.dart';
import '../models/shopping_list_model.dart';
import 'shopping_list_screen.dart';
import 'name_shopping_list_screen.dart';

class OpenShoppingListScreen extends StatefulWidget {
  final ShoppingListModel model;
  const OpenShoppingListScreen({super.key, required this.model});

  @override
  State<OpenShoppingListScreen> createState() => _OpenShoppingListScreenState();
}

class _OpenShoppingListScreenState extends State<OpenShoppingListScreen> {
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

  @override
  Widget build(BuildContext context) {
    final lists = widget.model.lists;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Shopping Lists')),
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
                        widget.model.createNewList(name);
                        await widget.model.save();
                        if (context.mounted) {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => ShoppingListScreen(model: widget.model),
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
                        if (confirm == true && mounted) {
                          await widget.model.deleteList(list.id);
                        }
                      },
                    ),
                    onTap: () async {
                      await widget.model.setActiveList(list.id);
                      if (context.mounted) {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ShoppingListScreen(model: widget.model),
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
