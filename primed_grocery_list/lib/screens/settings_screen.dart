import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config.dart';
import '../models/theme_notifier.dart';
import '../services/completion_service.dart';
import '../services/tutorial_service.dart';
import 'tutorial_sheet.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Holds the AI re-ordering preference loaded from SharedPreferences.
  // Starts false until _loadAiReorderPreference() completes.
  bool _aiReorderEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAiReorderPreference();
  }

  // Loads the saved preference asynchronously and rebuilds when it arrives.
  Future<void> _loadAiReorderPreference() async {
    final enabled = await CompletionService.getAiReorderEnabled();
    // Guard against the widget being disposed while we awaited.
    if (mounted) setState(() => _aiReorderEnabled = enabled);
  }

  // Helper that renders a muted section header above a group of tiles.
  Widget _sectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  // Opens the Buy Me a Coffee URL in the device's default browser.
  // Falls back to a SnackBar if the URL cannot be launched.
  Future<void> _launchCoffeeUrl(BuildContext context) async {
    final uri = Uri.parse(AppConfig.kBuyMeCoffeeUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // context.mounted guards against using a stale context after the await.
      if (context.mounted) {
        _showSnackBar(context, 'Could not open link');
      }
    }
  }

  // Shows a short SnackBar message using the nearest Scaffold messenger.
  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _sectionHeader(context, 'Appearance'),
          ListTile(
            title: const Text('Theme'),
            subtitle: const Text('Choose app colour'),
            trailing: const Icon(Icons.chevron_right),
            // Opens the theme picker screen where the user can choose a colour.
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const _ThemePickerScreen()),
            ),
          ),

          // ── Onboarding ──────────────────────────────────────────────────
          _sectionHeader(context, 'Onboarding'),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('Show Tutorial Again'),
            // Resets the "shown" flag and immediately opens the tutorial sheet.
            onTap: () async {
              await TutorialService.reset();
              if (context.mounted) {
                // Close settings so the tutorial appears over HomeScreen.
                Navigator.of(context).pop();
                await showTutorialSheet(context);
              }
            },
          ),

          // ── Shopping ──────────────────────────────────────────────────
          _sectionHeader(context, 'Shopping'),
          // Toggle for AI-powered list re-ordering after each shopping trip.
          SwitchListTile(
            secondary: const Icon(Icons.auto_fix_high_outlined),
            title: const Text('AI Re-ordering'),
            subtitle: const Text(
              'Automatically re-order your list after each shopping trip',
            ),
            value: _aiReorderEnabled,
            onChanged: (value) async {
              // Update UI immediately, then persist the preference.
              setState(() => _aiReorderEnabled = value);
              await CompletionService.setAiReorderEnabled(value);
            },
          ),
          // Info tile that explains what AI re-ordering does.
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About AI Re-ordering'),
            onTap: () => showDialog<void>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('AI Re-ordering'),
                content: const Text(
                  'When enabled, Primed will automatically re-order your shopping list '
                  'based on your shopping patterns — putting frequently bought-together '
                  'items near each other.\n\n'
                  'This feature is coming soon!',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: const Text('Got it'),
                  ),
                ],
              ),
            ),
          ),

          // ── Support ─────────────────────────────────────────────────────
          _sectionHeader(context, 'Support'),
          ListTile(
            leading: const Icon(Icons.coffee_outlined),
            title: const Text('Buy Me a Coffee ☕'),
            // Opens the Buy Me a Coffee page in the device browser.
            onTap: () => _launchCoffeeUrl(context),
          ),

          // ── About ───────────────────────────────────────────────────────
          _sectionHeader(context, 'About'),
          const ListTile(
            title: Text('Version'),
            subtitle: Text('0.1.0'),
            // No action needed — purely informational.
          ),
        ],
      ),
    );
  }
}

/// A simple screen showing colour swatches the user can pick from.
class _ThemePickerScreen extends StatelessWidget {
  const _ThemePickerScreen();

  @override
  Widget build(BuildContext context) {
    final notifier = context.watch<ThemeNotifier>();
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Theme')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: kThemeOptions.map((option) {
          final isSelected = notifier.seedColor == option.color;
          return ListTile(
            leading: CircleAvatar(backgroundColor: option.color),
            title: Text(option.label),
            // Show a checkmark next to the currently selected colour.
            trailing: isSelected
                ? Icon(Icons.check, color: Theme.of(context).colorScheme.primary)
                : null,
            onTap: () => context.read<ThemeNotifier>().setColor(option.color),
          );
        }).toList(),
      ),
    );
  }
}
