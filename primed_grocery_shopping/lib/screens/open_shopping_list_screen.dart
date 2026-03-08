import 'package:flutter/material.dart';
import '../models/shopping_list_model.dart';
import '../models/shopping_item.dart';
import 'add_item_screen.dart';

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
    const imageUrl = 'https://images.unsplash.com/photo-1506806732259-39c2d0268443?auto=format&fit=crop&w=1200&q=80';
    final items = widget.model.items;

    return Scaffold(
      appBar: AppBar(title: const Text('Open Shopping List')),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(imageUrl, fit: BoxFit.cover),
          SafeArea(
            child: items.isEmpty
                ? const Center(child: Text('No items yet — add one!'))
                : ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final ShoppingItem item = items[index];
                      return ListTile(
                        leading: Checkbox(
                          value: item.bought,
                          onChanged: (_) => widget.model.toggleBought(item.id),
                        ),
                        title: Text(item.name,
                            style: TextStyle(
                                decoration: item.bought ? TextDecoration.lineThrough : null)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete),
                          onPressed: () => widget.model.remove(item.id),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final name = await Navigator.of(context).push<String?>(
            MaterialPageRoute(builder: (_) => const AddItemScreen()),
          );
          if (name != null && name.isNotEmpty) {
            await widget.model.add(name);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
