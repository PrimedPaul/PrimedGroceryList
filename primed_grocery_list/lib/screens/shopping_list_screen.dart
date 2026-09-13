import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/shopping_item_list_model.dart';
import '../models/shopping_item_model.dart';
import '../services/rating_service.dart';
import 'settings_screen.dart';
import 'tutorial_sheet.dart';
// AddItemScreen is defined at the bottom of this file so we don't have
// to depend on a separate file that may be missing.

// ShoppingListScreen stays a StatefulWidget because it owns several pieces of
// local UI state (_editingView, _isPlacingNewItem, _snackBarTimer, etc.).
// The model is accessed via Provider instead of being passed as a constructor
// argument, removing the need for addListener / removeListener.
class ShoppingListScreen extends StatefulWidget {
  const ShoppingListScreen({super.key});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // track which view is active; editing by default
  bool _editingView = true;
  bool _isPlacingNewItem = false;
  // true while the shopping-complete celebration animation is playing
  bool _showCompletionOverlay = false;
  String? _newItemId;
  Timer? _snackBarTimer;
  ui.Image? _strikethroughImage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // No addListener needed — context.watch() in build() handles reactivity.
    _loadStrikethroughImage();
  }

  Future<void> _loadStrikethroughImage() async {
    final data = await rootBundle.load('assets/strikethrough.png');
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    if (mounted) setState(() => _strikethroughImage = frame.image);
  }

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    _strikethroughImage?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleView(bool editing) async {
    if (_editingView == editing) return;
    _snackBarTimer?.cancel();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _editingView = editing;
    });
  }

  /// Shows a bottom sheet asking the user to rate the app.
  Future<void> _showRatingPrompt() async {
    final choice = await showModalBottomSheet<_RatingChoice>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Enjoying Primed Grocery? ⭐',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'A quick rating helps others find the app!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.spaceEvenly,
              spacing: 8,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () =>
                      Navigator.of(ctx).pop(_RatingChoice.declineForever),
                  child: const Text("Don't Ask Again"),
                ),
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(_RatingChoice.later),
                  child: const Text('Maybe Later'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(_RatingChoice.rateNow),
                  child: const Text('Rate Now ⭐'),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    // Swiping the sheet away or pressing back counts as "Maybe Later".
    switch (choice ?? _RatingChoice.later) {
      case _RatingChoice.rateNow:
        await RatingService.requestReview();
      case _RatingChoice.later:
        await RatingService.deferReview();
      case _RatingChoice.declineForever:
        await RatingService.declineForever();
    }
  }

  /// Resets all bought flags without exiting shopping mode.
  /// Extracted so it can be called from the Complete Shopping FAB long-press.
  Future<void> _resetCart() async {
    final m = context.read<ShoppingItemListNotifier>();
    final markedCount = m.items.where((i) => i.bought).length;
    if (markedCount > 1) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Reset cart?'),
          content: Text('This will unmark all $markedCount checked items.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Reset'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await m.clearAllBought();
  }

  /// Called when the user taps the "Complete Shopping" FAB.
  Future<void> _handleCompleteShoppingTap() async {
    setState(() => _showCompletionOverlay = true);
  }

  /// Called by _CompletionOverlay when its animation finishes.
  Future<void> _onCompletionAnimationDone() async {
    if (!mounted) return;
    setState(() => _showCompletionOverlay = false);
    final m = context.read<ShoppingItemListNotifier>();
    await m.clearAllBought();
    if (!mounted) return;
    await _toggleView(true);
    final shouldPrompt = await RatingService.recordCompletedShoppingSession();
    if (shouldPrompt && mounted) _showRatingPrompt();
  }

  /// Formats a [DateTime] as a short human-readable age string.
  /// e.g. "just now", "5 min ago", "2 hr ago", "12/4/2025"
  String _formatLastUpdated(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'just now';
    if (diff.inMinutes < 60) {
      final m = diff.inMinutes;
      return '$m min ago';
    }
    if (diff.inHours < 24) {
      final h = diff.inHours;
      return '$h hr ago';
    }
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    // Use context.read for mutations — no rebuild subscription needed here.
    final model = context.read<ShoppingItemListNotifier>();
    final deletedIndex = model.items.indexOf(item);
    await model.remove(item.id);
    if (!mounted) return;

    final deletedItem = item;
    final deletedItemId = item.id;

    _snackBarTimer?.cancel();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted ${item.name}'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 80, left: 16, right: 16),
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            _snackBarTimer?.cancel();
            await context
                .read<ShoppingItemListNotifier>()
                .restoreItem(deletedItem, index: deletedIndex);
            if (!mounted) return;
            if (_newItemId == deletedItemId) {
              setState(() {
                _newItemId = null;
              });
            }
          },
        ),
      ),
    );
    _snackBarTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) ScaffoldMessenger.of(context).hideCurrentSnackBar();
    });
  }

  Widget _buildList() {
    final model = context.read<ShoppingItemListNotifier>();
    final allItems = model.items;
    final visibleItems = _editingView
        ? allItems
        : allItems.where((i) => i.quantity > 0).toList();
    return ReorderableListView.builder(
      scrollController: _scrollController,
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: visibleItems.length,
      autoScrollerVelocityScalar: 50.0,
      // ignore: deprecated_member_use
      onReorder: (oldIndex, newIndex) {
        if (_editingView) {
          model.reorder(oldIndex, newIndex);
        } else {
          final modelOldIndex = allItems.indexOf(visibleItems[oldIndex]);
          final int modelNewIndex;
          if (newIndex >= visibleItems.length) {
            modelNewIndex = allItems.indexOf(visibleItems.last) + 1;
          } else {
            modelNewIndex = allItems.indexOf(visibleItems[newIndex]);
          }
          model.reorder(modelOldIndex, modelNewIndex);
        }
      },
      itemBuilder: (context, index) => _buildItem(model, visibleItems[index],
          isReorderable: true, index: index),
    );
  }

  Widget _buildItem(ShoppingItemListNotifier model, ShoppingItem item,
      {required bool isReorderable, required int index}) {
    if (!_editingView) {
      return _ShoppingModeItem(
        key: ValueKey(item.id),
        item: item,
        index: index,
        strikethroughImage: _strikethroughImage,
        onToggle: () => model.toggleBought(item.id),
      );
    }

    // Edit mode: swipe left to delete
    final itemDecoration = _isPlacingNewItem && item.id == _newItemId
        ? BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            border: Border.all(color: Colors.blue, width: 2),
          )
        : null;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteItem(item),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: Container(
        decoration: itemDecoration,
        child: ListTile(
          title: Text(item.name),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ItemQuantityCounter(
                quantity: item.quantity,
                unit: item.unit,
                onDecrement: () => context
                    .read<ShoppingItemListNotifier>()
                    .updateQuantity(item.id, item.quantity - 1),
                onIncrement: () => context
                    .read<ShoppingItemListNotifier>()
                    .updateQuantity(item.id, item.quantity + 1),
                onUnitChanged: (newUnit) => context
                    .read<ShoppingItemListNotifier>()
                    .updateUnit(item.id, newUnit),
              ),
              const SizedBox(width: 4),
              if (isReorderable)
                ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                )
              else
                const Icon(Icons.drag_handle),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // context.watch triggers a rebuild whenever the model notifies listeners.
    final model = context.watch<ShoppingItemListNotifier>();
    final items = model.items;
    final listName = model.activeList?.name ?? 'Shopping List';
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _snackBarTimer?.cancel();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(listName),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
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
          ],
        ),
        body: Stack(
          children: [
            (items.isEmpty ||
                    (!_editingView && items.every((i) => i.quantity == 0)))
                ? Center(
                    child: Text(items.isEmpty
                        ? 'No items yet — add one!'
                        : 'No items to shop for'))
                : _buildList(),
            Positioned(
              left: 16,
              bottom: 16,
              child: Material(
                elevation: 6,
                borderRadius: BorderRadius.circular(28),
                clipBehavior: Clip.antiAlias,
                child: ToggleButtons(
                  isSelected: [_editingView, !_editingView],
                  onPressed: (index) => _toggleView(index == 0),
                  borderRadius: BorderRadius.circular(28),
                  renderBorder: false,
                  constraints:
                      const BoxConstraints(minWidth: 56, minHeight: 56),
                  children: const [
                    Icon(Icons.edit, semanticLabel: 'Edit mode'),
                    Icon(Icons.shopping_cart, semanticLabel: 'Shopping mode'),
                  ],
                ),
              ),
            ),
            // "Last updated" status — visible in edit mode only, sits in the
            // padding space above the FABs so it never overlaps list items.
            if (_editingView && model.activeList?.lastUpdated != null)
              Positioned(
                left: 0,
                right: 0,
                bottom: 76,
                child: IgnorePointer(
                  child: Center(
                    child: Text(
                      'Last updated ${_formatLastUpdated(model.activeList!.lastUpdated!)}',
                      style:
                          const TextStyle(color: Colors.black38, fontSize: 11),
                    ),
                  ),
                ),
              ),
            // "Complete Shopping" FAB — replaces the old reset-cart button.
            // Long-press to access the reset-cart action instead.
            if (!_editingView)
              Positioned(
                right: 16,
                bottom: 16,
                // GestureDetector wraps the FAB to capture long-press for reset.
                child: GestureDetector(
                  onLongPress: _resetCart,
                  child: FloatingActionButton(
                    tooltip: 'Complete Shopping\n(long-press to reset cart)',
                    onPressed: _handleCompleteShoppingTap,
                    child: const Icon(Icons.check_circle_outline),
                  ),
                ),
              ),
            if (_editingView)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  tooltip: _isPlacingNewItem ? 'Done placing item' : 'Add item',
                  onPressed: _isPlacingNewItem
                      ? () {
                          setState(() {
                            _isPlacingNewItem = false;
                            _newItemId = null;
                          });
                        }
                      : () async {
                          _snackBarTimer?.cancel();
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          // Capture the model before the async gap (Navigator.push await).
                          final m = context.read<ShoppingItemListNotifier>();
                          final name =
                              await Navigator.of(context).push<String?>(
                            MaterialPageRoute(
                                builder: (_) => const AddItemScreen()),
                          );
                          if (name != null && name.isNotEmpty) {
                            await m.add(name);
                            if (!mounted) return;
                            final newItem = m.items.last;
                            setState(() {
                              _isPlacingNewItem = true;
                              _newItemId = newItem.id;
                            });
                            // Only move to middle when the list overflows the screen.
                            // Check after the frame so the scroll extent is up to date.
                            WidgetsBinding.instance
                                .addPostFrameCallback((_) async {
                              if (!mounted) return;
                              final overflows = _scrollController.hasClients &&
                                  _scrollController.position.maxScrollExtent >
                                      0;
                              if (overflows) {
                                // context.read is safe here — addPostFrameCallback
                                // runs synchronously within the same frame boundary.
                                final notifier =
                                    context.read<ShoppingItemListNotifier>();
                                final currentIndex = notifier.items.length - 1;
                                final middleIndex = notifier.items.length ~/ 2;
                                if (currentIndex != middleIndex) {
                                  await notifier.reorder(
                                      currentIndex, middleIndex);
                                }
                              }
                            });
                            // Auto-clear the highlight after a delay
                            Future.delayed(const Duration(seconds: 5), () {
                              if (mounted && _isPlacingNewItem) {
                                setState(() {
                                  _isPlacingNewItem = false;
                                  _newItemId = null;
                                });
                              }
                            });
                          }
                        },
                  child: Icon(_isPlacingNewItem ? Icons.check : Icons.add),
                ),
              ),
            // Completion celebration overlay — shown on top of everything when
            // the user taps "Complete Shopping".
            if (_showCompletionOverlay)
              Positioned.fill(
                child: _CompletionOverlay(
                  onComplete: _onCompletionAnimationDone,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Paints the strikethrough brush-stroke image using BlendMode.multiply so
// white areas are transparent against the item background and dark stroke
// areas render black — without triggering a compositing save-layer.
class _StrikethroughPainter extends CustomPainter {
  final ui.Image image;
  const _StrikethroughPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..blendMode = BlendMode.multiply;
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(_StrikethroughPainter old) => old.image != image;
}

// ---------------------------------------------------------------------------
// Clips a widget between two fractional horizontal positions (0..1).
class _TwoEdgeClipper extends CustomClipper<Rect> {
  final double left;
  final double right;
  const _TwoEdgeClipper({required this.left, required this.right});

  @override
  Rect getClip(Size size) => Rect.fromLTRB(
        size.width * left.clamp(0.0, 1.0),
        0,
        size.width * right.clamp(0.0, 1.0),
        size.height,
      );

  @override
  bool shouldReclip(_TwoEdgeClipper old) =>
      old.left != left || old.right != right;
}

// ---------------------------------------------------------------------------
// A shopping-mode list item that lets the user literally draw the strikethrough
// line by swiping left (and erase it by swiping left again on a bought item).
class _ShoppingModeItem extends StatefulWidget {
  final ShoppingItem item;
  final int index;
  final ui.Image? strikethroughImage;
  final VoidCallback onToggle;

  const _ShoppingModeItem({
    super.key,
    required this.item,
    required this.index,
    required this.strikethroughImage,
    required this.onToggle,
  });

  @override
  State<_ShoppingModeItem> createState() => _ShoppingModeItemState();
}

class _ShoppingModeItemState extends State<_ShoppingModeItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fingerAnim;

  // Whether the user is currently dragging.
  bool _dragging = false;

  // Tracks the finger's fractional X position (0 = left edge, 1 = right edge)
  // during a drag gesture and snap-back/snap-forward animations.
  double _fingerFrac = 1.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fingerAnim = const AlwaysStoppedAnimation(1.0);
  }

  @override
  void didUpdateWidget(_ShoppingModeItem old) {
    super.didUpdateWidget(old);
    // When bought changes externally (e.g., reset cart) and we're idle, reset.
    if (old.item.bought != widget.item.bought &&
        !_animController.isAnimating &&
        !_dragging) {
      setState(() => _fingerFrac = 1.0);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  double _localFrac(double globalX) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return 1.0;
    final localX = box.globalToLocal(Offset(globalX, 0)).dx;
    return (localX / box.size.width).clamp(0.0, 1.0);
  }

  void _animateTo(double target, {VoidCallback? onComplete}) {
    _fingerAnim = Tween<double>(begin: _fingerFrac, end: target).animate(
        CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward(from: 0.0).then((_) {
      if (mounted) {
        setState(() => _fingerFrac = target);
        onComplete?.call();
      }
    });
  }

  void _onDragStart(DragStartDetails details) {
    _dragging = true;
    if (_animController.isAnimating) {
      _fingerFrac = _fingerAnim.value;
      _animController.stop();
    }
    setState(() => _fingerFrac = _localFrac(details.globalPosition.dx));
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() => _fingerFrac = _localFrac(details.globalPosition.dx));
  }

  void _onDragEnd(DragEndDetails details) {
    _dragging = false;
    const threshold = 0.4;
    if (_fingerFrac <= threshold) {
      // Snap to fully drawn, then toggle bought and reset frac so the
      // visual stays consistent after the state change.
      _animateTo(0.0, onComplete: () {
        widget.onToggle();
        // After toggle, bought has flipped. Reset to 1.0 so the clip
        // logic (which depends on the new bought value) shows the
        // correct state: fully drawn or fully erased.
        setState(() => _fingerFrac = 1.0);
      });
    } else {
      _animateTo(1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onHorizontalDragStart: _onDragStart,
      onHorizontalDragUpdate: _onDragUpdate,
      onHorizontalDragEnd: _onDragEnd,
      child: AnimatedBuilder(
        animation: _animController,
        builder: (context, _) {
          final frac =
              _animController.isAnimating ? _fingerAnim.value : _fingerFrac;
          final isBought = widget.item.bought;
          // Drawing (not bought): line reveals right-to-left → clip [frac, 1.0]
          //   frac=1.0 → empty, frac=0.0 → full line
          // Erasing (bought): line hides right-to-left → clip [0.0, frac]
          //   frac=1.0 → full line, frac=0.0 → empty
          final clipLeft = isBought ? 0.0 : frac;
          final clipRight = isBought ? frac : 1.0;
          final hasVisibleLine = clipRight > clipLeft;
          final showLine = widget.strikethroughImage != null && hasVisibleLine;
          return Stack(
            children: [
              ListTile(
                title: Text(
                  widget.item.name,
                  style: isBought
                      ? const TextStyle(
                          color: Colors.black38,
                          fontWeight: FontWeight.w400,
                        )
                      : null,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Builder(builder: (context) {
                      final primary = Theme.of(context).colorScheme.primary;
                      final showUnit = widget.item.unit != 'qty';
                      return Container(
                        constraints: const BoxConstraints(minWidth: 30),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        // Show unit label below the number when unit is not 'qty'.
                        child: showUnit
                            ? Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${widget.item.quantity}',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isBought ? Colors.black38 : primary,
                                    ),
                                  ),
                                  Text(
                                    widget.item.unit,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color:
                                          isBought ? Colors.black38 : primary,
                                    ),
                                  ),
                                ],
                              )
                            : Text(
                                '${widget.item.quantity}',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isBought ? Colors.black38 : primary,
                                ),
                              ),
                      );
                    }),
                    const SizedBox(width: 4),
                    ReorderableDragStartListener(
                      index: widget.index,
                      child: const Icon(Icons.drag_handle),
                    ),
                  ],
                ),
              ),
              if (showLine)
                Positioned.fill(
                  child: ClipRect(
                    clipper: _TwoEdgeClipper(left: clipLeft, right: clipRight),
                    child: CustomPaint(
                      painter:
                          _StrikethroughPainter(widget.strikethroughImage!),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Compact quantity counter displayed in edit-mode list tiles.
// Long-pressing the number badge opens a bottom sheet to pick a unit.
class _ItemQuantityCounter extends StatelessWidget {
  final int quantity;
  final String unit;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  // Called when the user picks a new unit from the bottom sheet.
  final ValueChanged<String> onUnitChanged;

  const _ItemQuantityCounter({
    required this.quantity,
    required this.unit,
    required this.onDecrement,
    required this.onIncrement,
    required this.onUnitChanged,
  });

  /// Opens a bottom sheet with a grid of unit chips to choose from.
  void _showUnitPicker(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select unit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              // Wrap lays chips in rows, wrapping to the next line as needed.
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kSupportedUnits.map((u) {
                  return ChoiceChip(
                    label: Text(u),
                    // Highlight the currently selected unit.
                    selected: u == unit,
                    onSelected: (_) {
                      onUnitChanged(u);
                      Navigator.of(sheetContext).pop();
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final showUnit = unit != 'qty';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CounterBtn(
            icon: Icons.remove, onTap: quantity > 0 ? onDecrement : null),
        // GestureDetector wraps the badge so long-press opens the unit picker.
        GestureDetector(
          onLongPress: () => _showUnitPicker(context),
          child: Container(
            constraints: const BoxConstraints(minWidth: 30),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            // Show unit label below the number when unit is not 'qty'.
            child: showUnit
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$quantity',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: primary,
                        ),
                      ),
                      Text(
                        unit,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: primary,
                        ),
                      ),
                    ],
                  )
                : Text(
                    '$quantity',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: primary,
                    ),
                  ),
          ),
        ),
        _CounterBtn(icon: Icons.add, onTap: onIncrement),
      ],
    );
  }
}

class _CounterBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CounterBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = onTap == null
        ? Theme.of(context).disabledColor
        : Theme.of(context).iconTheme.color;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Full-screen celebration overlay shown when the user completes a shopping trip.
// The animation starts automatically when the widget is inserted into the tree,
// and [onComplete] is called when the fade-out finishes so the caller can
// clean up state and reset the list.
class _CompletionOverlay extends StatefulWidget {
  const _CompletionOverlay({required this.onComplete});

  /// Called once when the animation finishes.
  final VoidCallback onComplete;

  @override
  State<_CompletionOverlay> createState() => _CompletionOverlayState();
}

class _CompletionOverlayState extends State<_CompletionOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  // Scale: pop from 0 → 1.15 → 1.0, then hold, then fade out.
  late final Animation<double> _scale;
  // Opacity: fully visible for the first 60 % of the animation, then fade.
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..addStatusListener((status) {
        // Fire onComplete as soon as the animation reaches the end.
        if (status == AnimationStatus.completed && mounted) {
          widget.onComplete();
        }
      });

    _scale = TweenSequence<double>([
      // Pop in with slight overshoot for a lively feel.
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: 1.15)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 28,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.15, end: 1.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 12,
      ),
      // Hold at full size before fading.
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
      // Keep size while the opacity animation fades the overlay out.
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 30),
    ]).animate(_ctrl);

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 60),
      TweenSequenceItem(
        tween:
            Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 40,
      ),
    ]).animate(_ctrl);

    // Start immediately when this widget first appears.
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) => Opacity(
        opacity: _opacity.value,
        child: Container(
          // Semi-transparent backdrop dims the list behind the card.
          color: Colors.black54,
          child: Center(
            child: ScaleTransition(
              scale: _scale,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 80,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Shopping complete!',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Great trip! 🛒',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.black54,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Helper screen for entering a new item name.  Placed in the same file so we
// don't depend on an external asset that might be missing when the repo is
// restored.

class AddItemScreen extends StatefulWidget {
  const AddItemScreen({super.key});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
    // select all text when the screen appears (even though the field is
    // initially empty, this matches the pattern we used for naming lists)
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
      appBar: AppBar(title: const Text('Add Item')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Item name',
                hintText: 'e.g., Milk',
              ),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RatingChoice { rateNow, later, declineForever }
