import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'models/shopping_list_model.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final model = ShoppingListModel();
  await model.load();
  runApp(MyApp(model: model));
}

class MyApp extends StatelessWidget {
  final ShoppingListModel model;
  const MyApp({super.key, required this.model});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Primed Grocery',
      theme: AppTheme.theme,
      home: AppShell(model: model),
    );
  }
}

class AppShell extends StatefulWidget {
  final ShoppingListModel model;
  const AppShell({super.key, required this.model});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: HomeScreen(model: widget.model),
    );
  }
}
