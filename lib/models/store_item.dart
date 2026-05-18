enum StoreCategory {
  themes,
  mascotSkins,
  hintPacks,
  trailEffects,
  victoryEffects,
}

enum CurrencyType { coins, gems }

class StoreItem {
  final String id;
  final String name;
  final String description;
  final StoreCategory category;
  final int price;
  final CurrencyType currency;
  final bool isOwned;
  final bool isEquipped;
  final String? previewEmoji;

  const StoreItem({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.price,
    required this.currency,
    this.isOwned = false,
    this.isEquipped = false,
    this.previewEmoji,
  });

  StoreItem copyWith({bool? isOwned, bool? isEquipped}) {
    return StoreItem(
      id: id,
      name: name,
      description: description,
      category: category,
      price: price,
      currency: currency,
      isOwned: isOwned ?? this.isOwned,
      isEquipped: isEquipped ?? this.isEquipped,
      previewEmoji: previewEmoji,
    );
  }

  bool get isConsumable => category == StoreCategory.hintPacks;

  int get hintAmount {
    switch (id) {
      case 'hints_5':
        return 5;
      case 'hints_15':
        return 15;
      case 'hints_50':
        return 50;
      default:
        return 0;
    }
  }
}

const List<StoreItem> kDefaultStoreItems = [
  // Themes
  StoreItem(
    id: 'theme_neon',
    name: 'Neon Theme',
    description: 'Glow in the dark vibes',
    category: StoreCategory.themes,
    price: 500,
    currency: CurrencyType.coins,
    previewEmoji: '🌟',
  ),
  StoreItem(
    id: 'theme_minimal',
    name: 'Minimal Theme',
    description: 'Clean and distraction-free',
    category: StoreCategory.themes,
    price: 300,
    currency: CurrencyType.coins,
    previewEmoji: '⬜',
  ),
  StoreItem(
    id: 'theme_candy',
    name: 'Candy Theme',
    description: 'Sweet pastel colors',
    category: StoreCategory.themes,
    price: 400,
    currency: CurrencyType.coins,
    previewEmoji: '🍬',
  ),
  StoreItem(
    id: 'theme_space',
    name: 'Space Theme',
    description: 'Explore the cosmos',
    category: StoreCategory.themes,
    price: 600,
    currency: CurrencyType.coins,
    previewEmoji: '🚀',
  ),
  StoreItem(
    id: 'theme_dark',
    name: 'Dark Theme',
    description: 'Easy on the eyes',
    category: StoreCategory.themes,
    price: 350,
    currency: CurrencyType.coins,
    previewEmoji: '🌙',
  ),
  StoreItem(
    id: 'theme_aurora',
    name: 'Aurora Theme',
    description: 'Luminous polar-night colors',
    category: StoreCategory.themes,
    price: 750,
    currency: CurrencyType.coins,
    previewEmoji: 'A',
  ),
  // Mascot Skins
  StoreItem(
    id: 'skin_ninja',
    name: 'Ninja Cat',
    description: 'Silent but deadly',
    category: StoreCategory.mascotSkins,
    price: 5,
    currency: CurrencyType.gems,
    previewEmoji: '🥷',
  ),
  StoreItem(
    id: 'skin_space',
    name: 'Space Cat',
    description: 'To infinity and beyond',
    category: StoreCategory.mascotSkins,
    price: 8,
    currency: CurrencyType.gems,
    previewEmoji: '👨‍🚀',
  ),
  StoreItem(
    id: 'skin_royal',
    name: 'Royal Cat',
    description: 'Fit for a king',
    category: StoreCategory.mascotSkins,
    price: 10,
    currency: CurrencyType.gems,
    previewEmoji: '👑',
  ),
  StoreItem(
    id: 'skin_cyber',
    name: 'Cyber Cat',
    description: 'From the future',
    category: StoreCategory.mascotSkins,
    price: 12,
    currency: CurrencyType.gems,
    previewEmoji: '🤖',
  ),
  StoreItem(
    id: 'skin_sleepy',
    name: 'Sleepy Cat',
    description: 'Always napping',
    category: StoreCategory.mascotSkins,
    price: 3,
    currency: CurrencyType.gems,
    previewEmoji: '😴',
  ),
  // Hint Packs
  StoreItem(
    id: 'hints_5',
    name: '5 Hints',
    description: 'A small hint pack',
    category: StoreCategory.hintPacks,
    price: 100,
    currency: CurrencyType.coins,
    previewEmoji: '💡',
  ),
  StoreItem(
    id: 'hints_15',
    name: '15 Hints',
    description: 'A medium hint pack',
    category: StoreCategory.hintPacks,
    price: 250,
    currency: CurrencyType.coins,
    previewEmoji: '💡',
  ),
  StoreItem(
    id: 'hints_50',
    name: '50 Hints',
    description: 'The big hint bundle',
    category: StoreCategory.hintPacks,
    price: 2,
    currency: CurrencyType.gems,
    previewEmoji: '💡',
  ),
  // Trail Effects
  StoreItem(
    id: 'trail_glow',
    name: 'Glow Trail',
    description: 'Leaves a glowing path',
    category: StoreCategory.trailEffects,
    price: 200,
    currency: CurrencyType.coins,
    previewEmoji: '✨',
  ),
  StoreItem(
    id: 'trail_rainbow',
    name: 'Rainbow Trail',
    description: 'All the colors!',
    category: StoreCategory.trailEffects,
    price: 450,
    currency: CurrencyType.coins,
    previewEmoji: '🌈',
  ),
  StoreItem(
    id: 'trail_spark',
    name: 'Spark Trail',
    description: 'Electric sparks follow you',
    category: StoreCategory.trailEffects,
    price: 350,
    currency: CurrencyType.coins,
    previewEmoji: '⚡',
  ),
  StoreItem(
    id: 'trail_neon',
    name: 'Neon Path',
    description: 'Bright neon glow',
    category: StoreCategory.trailEffects,
    price: 6,
    currency: CurrencyType.gems,
    previewEmoji: '🔆',
  ),
  // Victory Effects
  StoreItem(
    id: 'victory_confetti',
    name: 'Confetti Burst',
    description: 'Classic confetti explosion',
    category: StoreCategory.victoryEffects,
    price: 0,
    currency: CurrencyType.coins,
    isOwned: true,
    isEquipped: true,
    previewEmoji: '🎊',
  ),
  StoreItem(
    id: 'victory_stars',
    name: 'Animated Stars',
    description: 'Stars rain from above',
    category: StoreCategory.victoryEffects,
    price: 300,
    currency: CurrencyType.coins,
    previewEmoji: '⭐',
  ),
  StoreItem(
    id: 'victory_fireworks',
    name: 'Fireworks',
    description: 'Spectacular fireworks show',
    category: StoreCategory.victoryEffects,
    price: 8,
    currency: CurrencyType.gems,
    previewEmoji: '🎆',
  ),
];
