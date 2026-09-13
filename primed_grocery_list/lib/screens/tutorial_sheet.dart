import 'package:flutter/material.dart';
import '../services/tutorial_service.dart';

/// Holds the content for a single tutorial page.
class _TutorialPage {
  final IconData icon;
  final String title;
  final String description;

  const _TutorialPage({
    required this.icon,
    required this.title,
    required this.description,
  });
}

/// The six tutorial pages shown in order.
const _pages = [
  _TutorialPage(
    icon: Icons.shopping_cart_outlined,
    title: 'Welcome to Primed Grocery!',
    description:
        'Manage all your shopping lists in one place. Quick to edit, easy to use while shopping.',
  ),
  _TutorialPage(
    icon: Icons.create_outlined,
    title: 'Create a List',
    description:
        'Tap "Create New List" on the home screen to start a new shopping list. '
        'Give it a name and you\'re ready to go.',
  ),
  _TutorialPage(
    icon: Icons.add_circle_outline,
    title: 'Add Items',
    description:
        'In edit mode, tap the ➕ button to add an item. '
        'Use +/− to set the quantity, and long-press the quantity to choose a unit (kg, g, dozen…).',
  ),
  _TutorialPage(
    icon: Icons.edit_outlined,
    title: 'Edit Your List',
    description:
        'Swipe an item left to delete it. Drag the handle on the right to reorder. '
        'Tap undo in the snack bar if you delete by mistake.',
  ),
  _TutorialPage(
    icon: Icons.shopping_cart,
    title: 'Shopping Mode',
    description:
        'Tap the cart icon (bottom-left) to switch to shopping mode. '
        'Swipe an item right-to-left to draw a strikethrough — swipe again to unmark it.',
  ),
  _TutorialPage(
    icon: Icons.check_circle_outline,
    title: 'You\'re All Set!',
    description: 'That\'s everything you need to know. Happy shopping! 🛒',
  ),
];

/// Shows the tutorial as a tall modal bottom sheet.
///
/// Awaits dismissal (whether the user completes, taps "Skip", or swipes down),
/// then marks the tutorial as shown so it won't appear automatically again.
Future<void> showTutorialSheet(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    // isScrollControlled lets the sheet grow taller than 50 % of the screen.
    isScrollControlled: true,
    // useSafeArea keeps the sheet away from the camera notch / status bar.
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => const _TutorialSheetContent(),
  );

  // Mark shown regardless of how the sheet was closed (completed, skipped,
  // or swiped down) so it doesn't pop up again automatically next time.
  await TutorialService.markShown();
}

// ─────────────────────────────────────────────────────────────────────────────
// Internal stateful widget that manages the PageView and button state.
// ─────────────────────────────────────────────────────────────────────────────

class _TutorialSheetContent extends StatefulWidget {
  const _TutorialSheetContent();

  @override
  State<_TutorialSheetContent> createState() => _TutorialSheetContentState();
}

class _TutorialSheetContentState extends State<_TutorialSheetContent> {
  // Controls the PageView so we can call nextPage() programmatically.
  final _controller = PageController();

  // Tracks which page is currently visible so we can update the dots and
  // show the correct button label.
  int _currentPage = 0;

  @override
  void dispose() {
    // Always dispose controllers to free resources.
    _controller.dispose();
    super.dispose();
  }

  /// Advances to the next page, or closes the sheet on the last page.
  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      // Last page — "Let's go!" closes the bottom sheet.
      Navigator.of(context).pop();
    }
  }

  /// Closes the sheet immediately (called by the "Skip" button).
  void _skip() => Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) {
    final isLast = _currentPage == _pages.length - 1;
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      // 75 % of screen height gives enough room for content without being
      // a full-screen takeover.
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          // ── Drag handle ────────────────────────────────────────────────
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Page content ───────────────────────────────────────────────
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: _pages.length,
              // Rebuild to update dots and button label whenever the page changes.
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) {
                final page = _pages[i];
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Large icon representing this step.
                      Icon(page.icon, size: 80, color: colorScheme.primary),
                      const SizedBox(height: 24),
                      // Bold title.
                      Text(
                        page.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Short description (2–3 sentences).
                      Text(
                        page.description,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Colors.black54,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ── Page indicator dots ────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_pages.length, (i) {
              // The active dot is wider to indicate current position.
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _currentPage == i ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == i
                      ? colorScheme.primary
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),

          // ── Navigation buttons ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // "Skip" is shown on all pages except the last.
                if (!isLast)
                  TextButton(
                    onPressed: _skip,
                    child: const Text('Skip'),
                  )
                else
                  // Empty box keeps the "Next / Let's go!" button right-aligned.
                  const SizedBox.shrink(),

                ElevatedButton(
                  onPressed: _next,
                  child: Text(isLast ? "Let's go!" : 'Next'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
