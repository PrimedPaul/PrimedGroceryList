import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/shopping_list_model.dart';
// AddItemScreen is defined at the bottom of this file so we don't have
// to depend on a separate file that may be missing.


class ShoppingListScreen extends StatefulWidget {
  final ShoppingListModel model;
  const ShoppingListScreen({super.key, required this.model});

  @override
  State<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends State<ShoppingListScreen> {
  // track which view is active; editing by default
  bool _editingView = true;
  bool _isPlacingNewItem = false;
  String? _newItemId;
  Timer? _snackBarTimer;
  ui.Image? _strikethroughImage;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_onModel);
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
    widget.model.removeListener(_onModel);
    _strikethroughImage?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onModel() => setState(() {});

  void _toggleView(bool editing) {
    _snackBarTimer?.cancel();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    setState(() {
      _editingView = editing;
    });
  }

  Future<void> _deleteItem(ShoppingItem item) async {
    final deletedIndex = widget.model.items.indexOf(item);
    await widget.model.remove(item.id);
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
            await widget.model.restoreItem(deletedItem, index: deletedIndex);
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
    final items = widget.model.items;
    return ReorderableListView.builder(
      scrollController: _scrollController,
      padding: const EdgeInsets.only(bottom: 88),
      itemCount: items.length,
      autoScrollerVelocityScalar: 50.0,
      onReorder: (oldIndex, newIndex) =>
          widget.model.reorder(oldIndex, newIndex),
      itemBuilder: (context, index) =>
          _buildItem(items[index], isReorderable: true, index: index),
    );
  }

  Widget _buildItem(ShoppingItem item, {required bool isReorderable, required int index}) {
    if (!_editingView) {
      return _ShoppingModeItem(
        key: ValueKey(item.id),
        item: item,
        index: index,
        strikethroughImage: _strikethroughImage,
        onToggle: () => widget.model.toggleBought(item.id),
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
          trailing: isReorderable
              ? ReorderableDragStartListener(
                  index: index,
                  child: const Icon(Icons.drag_handle),
                )
              : const Icon(Icons.drag_handle),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = widget.model.items;
    final listName = widget.model.activeList?.name ?? 'Shopping List';
    return PopScope(
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          _snackBarTimer?.cancel();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
        }
      },
      child: Scaffold(
        appBar: AppBar(title: Text(listName)),
        body: Stack(
          children: [
            items.isEmpty
                ? const Center(child: Text('No items yet — add one!'))
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
                  constraints: const BoxConstraints(minWidth: 56, minHeight: 56),
                  children: const [
                    Icon(Icons.edit, semanticLabel: 'Edit mode'),
                    Icon(Icons.shopping_cart, semanticLabel: 'Shopping mode'),
                  ],
                ),
              ),
            ),
            if (!_editingView)
              Positioned(
                right: 16,
                bottom: 16,
                child: FloatingActionButton(
                  tooltip: 'Reset cart',
                  onPressed: () async {
                    final markedCount =
                        widget.model.items.where((i) => i.bought).length;
                    if (markedCount > 1) {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Reset cart?'),
                          content: Text(
                              'This will unmark all $markedCount checked items.'),
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
                    await widget.model.clearAllBought();
                  },
                  child: const Icon(Icons.refresh),
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
                          final name = await Navigator.of(context).push<String?>(
                            MaterialPageRoute(
                                builder: (_) => const AddItemScreen()),
                          );
                          if (name != null && name.isNotEmpty) {
                            await widget.model.add(name);
                            final newItem = widget.model.items.last;
                            setState(() {
                              _isPlacingNewItem = true;
                              _newItemId = newItem.id;
                            });
                            // Only move to middle when the list overflows the screen.
                            // Check after the frame so the scroll extent is up to date.
                            WidgetsBinding.instance.addPostFrameCallback((_) async {
                              if (!mounted) return;
                              final overflows = _scrollController.hasClients &&
                                  _scrollController.position.maxScrollExtent > 0;
                              if (overflows) {
                                final currentIndex = widget.model.items.length - 1;
                                final middleIndex = widget.model.items.length ~/ 2;
                                if (currentIndex != middleIndex) {
                                  await widget.model.reorder(currentIndex, middleIndex);
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
    _fingerAnim = Tween<double>(begin: _fingerFrac, end: target)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
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
          final frac = _animController.isAnimating ? _fingerAnim.value : _fingerFrac;
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
                trailing: ReorderableDragStartListener(
                  index: widget.index,
                  child: const Icon(Icons.drag_handle),
                ),
              ),
              if (showLine)
                Positioned.fill(
                  child: ClipRect(
                    clipper: _TwoEdgeClipper(left: clipLeft, right: clipRight),
                    child: CustomPaint(
                      painter: _StrikethroughPainter(widget.strikethroughImage!),
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
