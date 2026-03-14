import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../app_theme.dart';
import '../models/shopping_list_model.dart';
import 'shopping_list_screen.dart';
import 'open_shopping_list_screen.dart';
import 'name_shopping_list_screen.dart';

class HomeScreen extends StatelessWidget {
  final ShoppingListModel model;
  const HomeScreen({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.seedColor,
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -30,
            left: 0,
            right: 0,
            child: Center(
              child: Transform.rotate(
                angle: -35 * math.pi / 180,
                child: const Icon(
                  Icons.shopping_cart,
                  size: 500,
                  color: Color(0x33FFFFFF),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: MediaQuery.of(context).size.height / 2),
                Center(
                  child: IntrinsicWidth(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.create),
                        label: const Text('Create New List'),
                        style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16)),
                        onPressed: () async {
                          final name = await Navigator.of(context).push<String?>(
                            MaterialPageRoute(
                                builder: (_) => const ShoppingListNameScreen()),
                          );
                          if (name != null && context.mounted) {
                            model.createNewList(name);
                            await model.save();
                            if (context.mounted) {
                              Navigator.of(context).push(MaterialPageRoute(
                                builder: (_) => ShoppingListScreen(model: model),
                              ));
                            }
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open Shopping List'),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 14)),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => OpenShoppingListScreen(model: model),
                          ));
                        },
                      ),
                    ],
                  ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
