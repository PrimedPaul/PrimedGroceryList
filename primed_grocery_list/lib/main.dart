import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/shopping_item_list_model.dart';
import 'models/theme_notifier.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create both models and load their saved data before the UI starts.
  final groceryModel = ShoppingItemListNotifier();
  final themeNotifier = ThemeNotifier();
  await Future.wait([groceryModel.load(), themeNotifier.load()]);

  // MultiProvider lets us supply multiple notifiers to the widget tree so any
  // screen can access them via context.watch / context.read.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ShoppingItemListNotifier>.value(value: groceryModel),
        ChangeNotifierProvider<ThemeNotifier>.value(value: themeNotifier),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Watch ThemeNotifier so the whole app re-themes when the user changes colour.
    final theme = context.watch<ThemeNotifier>().themeData;
    return MaterialApp(
      title: 'Primed Grocery',
      theme: theme,
      home: const HomeScreen(),
    );
  }
}
