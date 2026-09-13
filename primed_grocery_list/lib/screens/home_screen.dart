import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/theme_notifier.dart';
import '../models/shopping_item_list_model.dart';
import 'shopping_list_screen.dart';
import 'open_shopping_list_screen.dart';
import 'name_shopping_list_screen.dart';
import 'settings_screen.dart';
import '../services/tutorial_service.dart';
import 'tutorial_sheet.dart';

// HomeScreen is a StatefulWidget so it can run a one-time check after the
// first frame to show the tutorial on first install.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Wait until the first frame is drawn before showing the bottom sheet —
    // the Navigator isn't ready until the widget tree is fully mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final should = await TutorialService.shouldShow();
      // Re-check mounted after the async gap; the widget could have been
      // removed from the tree while we were waiting.
      if (should && mounted) {
        await showTutorialSheet(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // context.read is fine here because HomeScreen doesn't need to rebuild
    // when the model changes — it only triggers navigation actions.
    final model = context.read<ShoppingItemListNotifier>();

    return Scaffold(
      backgroundColor: context.watch<ThemeNotifier>().seedColor,
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
          // Settings button floated in the top-right corner over the hero image.
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.settings_outlined, color: Colors.white),
                tooltip: 'Settings',
                onPressed: () async {
                  final showTutorial = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                  if (showTutorial == true && context.mounted) {
                    await showTutorialSheet(context);
                  }
                },
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 1),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Primed',
                      style: GoogleFonts.nunito(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        shadows: [
                          const Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Color(0x55000000),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Grocery List',
                      style: GoogleFonts.nunito(
                        fontSize: 40,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        color: Colors.white,
                        letterSpacing: 2,
                        shadows: [
                          const Shadow(
                            offset: Offset(2, 2),
                            blurRadius: 4,
                            color: Color(0x55000000),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Spacer(flex: 1),
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
                            final name =
                                await Navigator.of(context).push<String?>(
                              MaterialPageRoute(
                                  builder: (_) =>
                                      const ShoppingListNameScreen()),
                            );
                            if (name != null && context.mounted) {
                              // Use context.read inside a callback — we don't
                              // want to subscribe, just perform an action.
                              model.createNewList(name);
                              await model.save();
                              if (context.mounted) {
                                Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => const ShoppingListScreen(),
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
                              builder: (_) => const OpenShoppingListScreen(),
                            ));
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                // Bottom section: subtle coffee button pinned to the bottom.
                // Expanded so the outer Column gives it bounded height, which
                // allows the inner Spacer to push the button to the bottom.
                Expanded(
                  child: Column(
                    children: [
                      const Spacer(),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.coffee_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        label: const Text(
                          'Buy Me a Coffee',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                        onPressed: () async {
                          final uri = Uri.parse(AppConfig.kBuyMeCoffeeUrl);
                          if (await canLaunchUrl(uri)) {
                            await launchUrl(
                              uri,
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                    ],
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
