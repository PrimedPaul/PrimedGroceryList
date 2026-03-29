import 'package:flutter/material.dart';

/// This file is intentionally minimal.  The real [AddItemScreen]
/// implementation was moved into `shopping_list_screen.dart` so that
/// the app would compile even if the separate file was lost during a
/// power outage or repository sync.
///
/// Keeping this stub around prevents any stray imports from blowing up
/// the build; it simply renders an empty box.

@Deprecated('Use the AddItemScreen defined in shopping_list_screen.dart')
class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) Navigator.of(context).pop(text);
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
              decoration: const InputDecoration(labelText: 'Item name'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
