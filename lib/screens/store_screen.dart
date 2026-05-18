import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../models/store_item.dart';
import '../services/player_progress_service.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/mascot_widget.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({Key? key}) : super(key: key);

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _purchasedItemId;

  final List<_StoreTab> _tabs = const [
    _StoreTab(label: 'Themes', category: StoreCategory.themes, emoji: '🎨'),
    _StoreTab(label: 'Skins', category: StoreCategory.mascotSkins, emoji: '🐱'),
    _StoreTab(label: 'Hints', category: StoreCategory.hintPacks, emoji: '💡'),
    _StoreTab(
      label: 'Trails',
      category: StoreCategory.trailEffects,
      emoji: '✨',
    ),
    _StoreTab(
      label: 'Victory',
      category: StoreCategory.victoryEffects,
      emoji: '🎊',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handlePurchase(
    BuildContext context,
    StoreItem item,
    PlayerProgressService progress,
  ) {
    final theme = context.zipTheme;

    if (progress.isItemOwned(item)) {
      if (progress.isEquipped(item)) {
        _showFeedback(context, 'Already equipped', theme.textSecondary);
      } else {
        progress.equipItem(item);
        setState(() => _purchasedItemId = item.id);
        _showFeedback(context, 'Equipped!', theme.accent);
        Future.delayed(const Duration(milliseconds: 1200), () {
          if (mounted) setState(() => _purchasedItemId = null);
        });
      }
      return;
    }

    final bool canAfford = item.currency == CurrencyType.coins
        ? progress.coins >= item.price
        : progress.gems >= item.price;

    if (!canAfford) {
      _showFeedback(
        context,
        'Not enough ${item.currency == CurrencyType.coins ? "coins" : "gems"}!',
        theme.danger,
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _PurchaseDialog(
        item: item,
        onConfirm: () {
          Navigator.of(ctx).pop();
          final success = progress.purchaseItem(item);
          if (success) {
            setState(() => _purchasedItemId = item.id);
            final message = item.isConsumable
                ? '+${item.hintAmount} hints added!'
                : 'Purchased and equipped!';
            _showFeedback(context, message, theme.success);
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) setState(() => _purchasedItemId = null);
            });
          }
        },
      ),
    );
  }

  void _showFeedback(BuildContext context, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Consumer<PlayerProgressService>(
          builder: (context, progress, _) {
            return Column(
              children: [
                _buildHeader(progress)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.3, end: 0, curve: Curves.easeOutCubic),

                _buildTabBar().animate().fadeIn(
                  delay: 150.ms,
                  duration: 300.ms,
                ),

                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: _tabs.map((tab) {
                      final items = kDefaultStoreItems
                          .where((i) => i.category == tab.category)
                          .toList();
                      return _StoreGrid(
                        items: items,
                        progress: progress,
                        purchasedItemId: _purchasedItemId,
                        onTap: (item) =>
                            _handlePurchase(context, item, progress),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(PlayerProgressService progress) {
    final theme = context.zipTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Store',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'Customize your experience',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Currency display
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _CurrencyBadge(
                value: progress.coins,
                icon: Icons.monetization_on,
                color: theme.warning,
              ),
              const SizedBox(height: 6),
              _CurrencyBadge(
                value: progress.gems,
                icon: Icons.diamond_rounded,
                color: theme.accent,
              ),
              const SizedBox(height: 6),
              _CurrencyBadge(
                value: progress.hintsRemaining,
                icon: Icons.lightbulb_rounded,
                color: theme.accentAlt,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = context.zipTheme;
    return SizedBox(
      height: 52,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _tabs.length,
        itemBuilder: (context, i) {
          final isSelected = _tabController.index == i;
          return GestureDetector(
            onTap: () {
              _tabController.animateTo(i);
              setState(() {});
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? theme.accent : theme.surface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: isSelected
                        ? theme.accent.withOpacity(0.3)
                        : theme.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(_tabs[i].emoji, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    _tabs[i].label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ── Store Grid ─────────────────────────────────────────────────────────────

class _StoreGrid extends StatelessWidget {
  final List<StoreItem> items;
  final PlayerProgressService progress;
  final String? purchasedItemId;
  final ValueChanged<StoreItem> onTap;

  const _StoreGrid({
    required this.items,
    required this.progress,
    required this.purchasedItemId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.82,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final owned = progress.isItemOwned(item);
        final equipped = progress.isEquipped(item);
        final justPurchased = purchasedItemId == item.id;

        return _StoreCard(
              item: item,
              isOwned: owned,
              isEquipped: equipped,
              justPurchased: justPurchased,
              onTap: () => onTap(item),
            )
            .animate()
            .fadeIn(delay: (i * 60).ms, duration: 300.ms)
            .scale(
              begin: const Offset(0.9, 0.9),
              delay: (i * 60).ms,
              duration: 300.ms,
              curve: Curves.easeOutBack,
            );
      },
    );
  }
}

// ── Store Card ─────────────────────────────────────────────────────────────

class _StoreCard extends StatelessWidget {
  final StoreItem item;
  final bool isOwned;
  final bool isEquipped;
  final bool justPurchased;
  final VoidCallback onTap;

  const _StoreCard({
    required this.item,
    required this.isOwned,
    required this.isEquipped,
    required this.justPurchased,
    required this.onTap,
  });

  Widget _buildPreview(BuildContext context, StoreItem item) {
    final theme = context.zipTheme;
    if (item.category == StoreCategory.themes) {
      final previewTheme = themeById(item.id);
      return Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              previewTheme.background,
              previewTheme.boardBackground,
              previewTheme.pathEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: previewTheme.glow.withOpacity(0.3),
              blurRadius: 12,
            ),
          ],
        ),
        child: Align(
          alignment: Alignment.bottomRight,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: previewTheme.accent,
              shape: BoxShape.circle,
              border: Border.all(color: previewTheme.surface, width: 2),
            ),
          ),
        ),
      );
    }

    if (item.category == StoreCategory.mascotSkins) {
      return MascotWidget(
        emotion: MascotEmotion.happy,
        size: 46,
        skinId: item.id,
      );
    }

    if (item.category == StoreCategory.hintPacks) {
      return Stack(
        alignment: Alignment.center,
        children: [
          Icon(Icons.lightbulb_rounded, color: theme.warning, size: 42),
          Positioned(
            right: 4,
            bottom: 6,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: theme.accent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '+${item.hintAmount}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Text(
      item.previewEmoji ?? '*',
      style: TextStyle(fontSize: 34, color: theme.textPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    Color borderColor = theme.surfaceAlt;
    if (isOwned) borderColor = theme.success;
    if (isEquipped) borderColor = theme.accent;
    if (justPurchased) borderColor = theme.warning;

    return BouncingButton(
      onPressed: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: borderColor, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: justPurchased
                  ? theme.warning.withOpacity(0.22)
                  : isEquipped
                  ? theme.glow.withOpacity(0.18)
                  : theme.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji preview
            Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: theme.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(child: _buildPreview(context, item)) /*
                child: Text(
                  item.previewEmoji ?? '🎮',
                  style: const TextStyle(fontSize: 36),
                ),
              ), */,
                )
                .animate(
                  target: justPurchased ? 1 : 0,
                  onPlay: justPurchased ? (c) => c.repeat(reverse: true) : null,
                )
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 400.ms,
                ),

            const SizedBox(height: 10),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                item.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 4),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                item.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: theme.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),

            const SizedBox(height: 10),

            // Price / owned badge
            if (isEquipped)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: theme.accent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Equipped',
                      style: TextStyle(
                        color: theme.accent,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else if (isOwned)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.success.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, color: theme.success, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Owned',
                      style: TextStyle(
                        color: theme.success,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              )
            else if (item.price == 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: theme.success.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Free',
                  style: TextStyle(
                    color: theme.success,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: item.currency == CurrencyType.coins
                      ? theme.warning.withOpacity(0.14)
                      : theme.accent.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      item.currency == CurrencyType.coins
                          ? Icons.monetization_on
                          : Icons.diamond_rounded,
                      color: item.currency == CurrencyType.coins
                          ? theme.warning
                          : theme.accent,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${item.price}',
                      style: TextStyle(
                        color: item.currency == CurrencyType.coins
                            ? theme.warning
                            : theme.accent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Purchase Dialog ────────────────────────────────────────────────────────

class _PurchaseDialog extends StatelessWidget {
  final StoreItem item;
  final VoidCallback onConfirm;

  const _PurchaseDialog({required this.item, required this.onConfirm});

  Widget _buildDialogPreview(BuildContext context) {
    final theme = context.zipTheme;
    if (item.category == StoreCategory.mascotSkins) {
      return MascotWidget(
        emotion: MascotEmotion.happy,
        size: 78,
        skinId: item.id,
      );
    }
    if (item.category == StoreCategory.themes) {
      final previewTheme = themeById(item.id);
      return Container(
        width: 82,
        height: 82,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              previewTheme.background,
              previewTheme.boardBackground,
              previewTheme.pathEnd,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: previewTheme.glow.withOpacity(0.28),
              blurRadius: 18,
            ),
          ],
        ),
      );
    }
    if (item.category == StoreCategory.hintPacks) {
      return Icon(Icons.lightbulb_rounded, color: theme.warning, size: 58);
    }
    return Text(
      item.previewEmoji ?? '*',
      style: TextStyle(fontSize: 52, color: theme.textPrimary),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Center(
      child:
          Container(
                margin: const EdgeInsets.symmetric(horizontal: 40),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: theme.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: theme.shadow.withOpacity(0.9),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.previewEmoji ?? '🎮',
                      style: const TextStyle(fontSize: 52),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      item.name,
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item.currency == CurrencyType.coins
                              ? Icons.monetization_on
                              : Icons.diamond_rounded,
                          color: item.currency == CurrencyType.coins
                              ? theme.warning
                              : theme.accent,
                          size: 22,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${item.price} ${item.currency == CurrencyType.coins ? "coins" : "gems"}',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: BouncingButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: theme.surfaceAlt,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  'Cancel',
                                  style: TextStyle(
                                    color: theme.textSecondary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: BouncingButton(
                            onPressed: onConfirm,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: theme.accent,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.accent.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text(
                                  'Buy',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
              .animate()
              .fadeIn(duration: 250.ms)
              .scale(
                begin: const Offset(0.85, 0.85),
                curve: Curves.easeOutBack,
              ),
    );
  }
}

// ── Currency Badge ─────────────────────────────────────────────────────────

class _CurrencyBadge extends StatelessWidget {
  final int value;
  final IconData icon;
  final Color color;

  const _CurrencyBadge({
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$value',
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 5),
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 12),
          ),
        ],
      ),
    );
  }
}

class _StoreTab {
  final String label;
  final StoreCategory category;
  final String emoji;
  const _StoreTab({
    required this.label,
    required this.category,
    required this.emoji,
  });
}
