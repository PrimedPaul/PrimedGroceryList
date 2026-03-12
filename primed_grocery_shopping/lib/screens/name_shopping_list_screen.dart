import 'package:flutter/material.dart';

class ShoppingListNameScreen extends StatefulWidget {
  final String? initialName;

  const ShoppingListNameScreen({super.key, this.initialName});

  @override
  State<ShoppingListNameScreen> createState() => _ShoppingListNameScreenState();
}

class _ShoppingListNameScreenState extends State<ShoppingListNameScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    final name = widget.initialName ?? 'New Shopping List';
    _controller = TextEditingController(text: name);
    // Select all text
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
      appBar: AppBar(title: const Text('Name Your List')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'List name',
                hintText: 'e.g., Weekly Groceries',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
