import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_theme.dart';
import '../models/challenge.dart';
import '../models/store_item.dart';
import '../models/game_config.dart';

class PlayerProgressService extends ChangeNotifier {
  static const Set<String> _defaultOwnedItems = {
    kDefaultThemeId,
    'skin_default',
    'trail_classic',
    'victory_confetti',
  };

  int coins = GameConfig.startingCoins;
  int gems = GameConfig.startingGems;

  int totalLevelsCompleted = 0;
  int totalStarsEarned = 0;
  int currentStreak = 7;
  int longestStreak = 12;
  int totalPlayTimeSeconds = 0;
  int hintsUsed = 0;
  int hintsRemaining = GameConfig.startingHints;

  bool dailyChestClaimed = false;

  String playerName = 'Player 1';
  bool hasSetPlayerName = false;
  int playerLevel = 5;
  int xp = 340;
  int xpToNextLevel = 500;

  bool hasRated = false;
  int unratedWinStreak = 0; // Tracks consecutive wins since last prompt backoff

  Set<String> ownedItems = {..._defaultOwnedItems};
  String activeThemeId = kDefaultThemeId;
  String equippedSkin = 'skin_default';
  String equippedTrail = 'trail_classic';
  String equippedVictory = 'victory_confetti';

  List<Challenge> dailyChallenges = [];
  List<Challenge> weeklyChallenges = [];
  DateTime? lastDailyChallengeRefresh;
  DateTime? lastWeeklyChallengeRefresh;

  Map<String, bool> achievements = {};
  Map<String, int> levelStars = {};

  final Set<String> _weeklyDifficultyProgress = {};
  int _weeklyComboStreak = 0;
  bool _initialized = false;

  AppThemeData get activeTheme => themeById(activeThemeId);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await _loadData();
    await _ensureChallenges();
    notifyListeners();
  }

  bool spendCoins(int amount) {
    if (!_spendCurrency(CurrencyType.coins, amount)) return false;
    _saveData();
    notifyListeners();
    return true;
  }

  bool spendGems(int amount) {
    if (!_spendCurrency(CurrencyType.gems, amount)) return false;
    _saveData();
    notifyListeners();
    return true;
  }

  void addCoins(int amount) {
    coins += amount;
    _saveData();
    notifyListeners();
  }

  void addGems(int amount) {
    gems += amount;
    _saveData();
    notifyListeners();
  }

  void addHints(int amount) {
    hintsRemaining += amount;
    _saveData();
    notifyListeners();
  }

  bool purchaseItem(StoreItem item) {
    if (!item.isConsumable && isOwned(item.id)) return false;
    if (!_spendCurrency(item.currency, item.price)) return false;

    if (item.isConsumable) {
      hintsRemaining += item.hintAmount;
    } else {
      ownedItems.add(_normalizeOwnedId(item.id));
      equipItem(item, save: false, notify: false);
    }

    _saveData();
    notifyListeners();
    return true;
  }

  bool isOwned(String itemId) {
    final id = _normalizeOwnedId(itemId);
    return ownedItems.contains(id) ||
        _defaultOwnedItems.contains(id) ||
        id == 'victory_confetti';
  }

  bool isItemOwned(StoreItem item) {
    if (item.isConsumable) return false;
    return isOwned(item.id);
  }

  bool isEquipped(StoreItem item) {
    switch (item.category) {
      case StoreCategory.themes:
        return activeThemeId == normalizeThemeId(item.id);
      case StoreCategory.mascotSkins:
        return equippedSkin == normalizeSkinId(item.id);
      case StoreCategory.trailEffects:
        return equippedTrail == item.id;
      case StoreCategory.victoryEffects:
        return equippedVictory == item.id;
      case StoreCategory.hintPacks:
        return false;
    }
  }

  void equipItem(StoreItem item, {bool save = true, bool notify = true}) {
    if (item.isConsumable || !isOwned(item.id)) return;

    switch (item.category) {
      case StoreCategory.themes:
        activeThemeId = normalizeThemeId(item.id);
        break;
      case StoreCategory.mascotSkins:
        equippedSkin = normalizeSkinId(item.id);
        break;
      case StoreCategory.trailEffects:
        equippedTrail = item.id;
        break;
      case StoreCategory.victoryEffects:
        equippedVictory = item.id;
        break;
      case StoreCategory.hintPacks:
        break;
    }

    if (save) _saveData();
    if (notify) notifyListeners();
  }

  void onLevelCompleted({
    required int levelId,
    required int starsEarned,
    required bool usedHints,
    required int timeTakenSeconds,
    required String difficulty,
  }) {
    totalLevelsCompleted++;
    
    final levelKey = '${difficulty}_$levelId';
    final previousStars = levelStars[levelKey] ?? 0;
    if (starsEarned > previousStars) {
      totalStarsEarned += (starsEarned - previousStars);
      levelStars[levelKey] = starsEarned;
    }

    totalPlayTimeSeconds += timeTakenSeconds;

    final xpGain = 50 + (starsEarned * 20);
    xp += xpGain;
    while (xp >= xpToNextLevel) {
      xp -= xpToNextLevel;
      playerLevel++;
      xpToNextLevel = (xpToNextLevel * 1.2).toInt();
    }

    coins += 50 + (starsEarned * 30);
    _weeklyComboStreak++;

    _updateChallengeProgress(
      usedHints: usedHints,
      timeTakenSeconds: timeTakenSeconds,
      difficulty: difficulty,
    );

    _saveData();
    notifyListeners();
  }

  void recordLevelReset() {
    if (_weeklyComboStreak == 0) return;
    _weeklyComboStreak = 0;
    _saveData();
  }

  bool useHint() {
    if (hintsRemaining <= 0) return false;
    hintsRemaining--;
    hintsUsed++;
    _weeklyComboStreak = 0;
    _saveData();
    notifyListeners();
    return true;
  }

  Future<void> _ensureChallenges() async {
    final now = DateTime.now();
    var changed = false;

    final refreshDaily =
        lastDailyChallengeRefresh == null ||
        now.difference(lastDailyChallengeRefresh!).inHours >= 24;
    if (refreshDaily || dailyChallenges.isEmpty) {
      _generateDailyChallenges();
      lastDailyChallengeRefresh = now;
      dailyChestClaimed = false;
      changed = true;
    }

    final refreshWeekly =
        lastWeeklyChallengeRefresh == null ||
        now.difference(lastWeeklyChallengeRefresh!).inDays >= 7;
    if (refreshWeekly || weeklyChallenges.isEmpty) {
      _generateWeeklyChallenges();
      lastWeeklyChallengeRefresh = now;
      _weeklyDifficultyProgress.clear();
      _weeklyComboStreak = 0;
      changed = true;
    }

    if (changed) await _saveData();
  }

  void _generateDailyChallenges() {
    dailyChallenges = [
      Challenge(
        id: 'daily_1',
        title: 'Puzzle Starter',
        description: 'Complete 3 levels today',
        type: ChallengeType.completeNLevels,
        frequency: ChallengeFrequency.daily,
        targetValue: 3,
        rewards: [const ChallengeReward(type: RewardType.coins, amount: 150)],
        iconEmoji: 'P',
      ),
      Challenge(
        id: 'daily_2',
        title: 'No Peeking',
        description: 'Finish a level without hints',
        type: ChallengeType.finishWithoutHints,
        frequency: ChallengeFrequency.daily,
        targetValue: 1,
        rewards: [
          const ChallengeReward(type: RewardType.coins, amount: 100),
          const ChallengeReward(type: RewardType.gems, amount: 1),
        ],
        iconEmoji: 'N',
      ),
      Challenge(
        id: 'daily_3',
        title: 'Speed Run',
        description: 'Complete a level in under 60 seconds',
        type: ChallengeType.finishUnderTime,
        frequency: ChallengeFrequency.daily,
        targetValue: 1,
        rewards: [const ChallengeReward(type: RewardType.coins, amount: 200)],
        iconEmoji: 'S',
      ),
    ];
  }

  void _generateWeeklyChallenges() {
    weeklyChallenges = [
      Challenge(
        id: 'weekly_1',
        title: 'Dedicated Solver',
        description: 'Complete 20 levels this week',
        type: ChallengeType.completeNLevels,
        frequency: ChallengeFrequency.weekly,
        targetValue: 20,
        rewards: [
          const ChallengeReward(type: RewardType.coins, amount: 500),
          const ChallengeReward(type: RewardType.gems, amount: 5),
        ],
        iconEmoji: 'W',
      ),
      Challenge(
        id: 'weekly_2',
        title: 'Hard Mode Hero',
        description: 'Complete 5 expert levels',
        type: ChallengeType.finishHardLevel,
        frequency: ChallengeFrequency.weekly,
        targetValue: 5,
        rewards: [const ChallengeReward(type: RewardType.gems, amount: 10)],
        iconEmoji: 'H',
      ),
      Challenge(
        id: 'weekly_3',
        title: 'Combo Master',
        description: 'Complete 5 levels in a row without resetting',
        type: ChallengeType.comboStreak,
        frequency: ChallengeFrequency.weekly,
        targetValue: 5,
        rewards: [
          const ChallengeReward(type: RewardType.coins, amount: 300),
          const ChallengeReward(type: RewardType.gems, amount: 3),
        ],
        iconEmoji: 'C',
      ),
      Challenge(
        id: 'weekly_4',
        title: 'All Rounder',
        description: 'Complete a level in each difficulty',
        type: ChallengeType.completeAllDifficulties,
        frequency: ChallengeFrequency.weekly,
        targetValue: 3,
        rewards: [
          const ChallengeReward(type: RewardType.coins, amount: 400),
          const ChallengeReward(type: RewardType.gems, amount: 4),
        ],
        iconEmoji: 'A',
      ),
    ];
  }

  void _updateChallengeProgress({
    required bool usedHints,
    required int timeTakenSeconds,
    required String difficulty,
  }) {
    for (var i = 0; i < dailyChallenges.length; i++) {
      final challenge = dailyChallenges[i];
      if (challenge.isClaimed) continue;

      var newValue = challenge.currentValue;
      switch (challenge.type) {
        case ChallengeType.completeNLevels:
          newValue = (challenge.currentValue + 1).clamp(
            0,
            challenge.targetValue,
          );
          break;
        case ChallengeType.finishWithoutHints:
          if (!usedHints) newValue = 1;
          break;
        case ChallengeType.finishUnderTime:
          if (timeTakenSeconds < 60) newValue = 1;
          break;
        default:
          break;
      }

      dailyChallenges[i] = challenge.copyWith(
        currentValue: newValue,
        isCompleted: newValue >= challenge.targetValue,
      );
    }

    _weeklyDifficultyProgress.add(difficulty);

    for (var i = 0; i < weeklyChallenges.length; i++) {
      final challenge = weeklyChallenges[i];
      if (challenge.isClaimed) continue;

      var newValue = challenge.currentValue;
      switch (challenge.type) {
        case ChallengeType.completeNLevels:
          newValue = (challenge.currentValue + 1).clamp(
            0,
            challenge.targetValue,
          );
          break;
        case ChallengeType.finishHardLevel:
          if (difficulty == 'expert') {
            newValue = (challenge.currentValue + 1).clamp(
              0,
              challenge.targetValue,
            );
          }
          break;
        case ChallengeType.comboStreak:
          newValue = _weeklyComboStreak.clamp(0, challenge.targetValue);
          break;
        case ChallengeType.completeAllDifficulties:
          newValue = _weeklyDifficultyProgress.length.clamp(
            0,
            challenge.targetValue,
          );
          break;
        default:
          break;
      }

      weeklyChallenges[i] = challenge.copyWith(
        currentValue: newValue,
        isCompleted: newValue >= challenge.targetValue,
      );
    }
  }

  List<ChallengeReward> claimChallenge(String challengeId) {
    final claimedDaily = _claimFromList(dailyChallenges, challengeId);
    if (claimedDaily != null) {
      _saveData();
      notifyListeners();
      return claimedDaily;
    }

    final claimedWeekly = _claimFromList(weeklyChallenges, challengeId);
    if (claimedWeekly != null) {
      _saveData();
      notifyListeners();
      return claimedWeekly;
    }

    return const [];
  }

  List<ChallengeReward>? claimDailyChest() {
    if (dailyChestClaimed) return null;
    final allDone = dailyChallenges.isNotEmpty &&
        dailyChallenges.every((c) => c.isClaimed);
    if (!allDone) return null;

    dailyChestClaimed = true;
    coins += GameConfig.dailyChestCoins;
    gems += GameConfig.dailyChestGems;
    _saveData();
    notifyListeners();

    return [
      const ChallengeReward(type: RewardType.coins, amount: GameConfig.dailyChestCoins),
      const ChallengeReward(type: RewardType.gems, amount: GameConfig.dailyChestGems),
    ];
  }

  List<ChallengeReward>? _claimFromList(
    List<Challenge> challenges,
    String challengeId,
  ) {
    for (var i = 0; i < challenges.length; i++) {
      final challenge = challenges[i];
      final canClaim =
          challenge.id == challengeId &&
          challenge.isCompleted &&
          !challenge.isClaimed;
      if (!canClaim) continue;

      for (final reward in challenge.rewards) {
        switch (reward.type) {
          case RewardType.coins:
            coins += reward.amount;
            break;
          case RewardType.gems:
            gems += reward.amount;
            break;
          case RewardType.streakProgress:
            currentStreak += reward.amount;
            longestStreak = longestStreak < currentStreak
                ? currentStreak
                : longestStreak;
            break;
        }
      }

      challenges[i] = challenge.copyWith(isClaimed: true);
      return challenge.rewards;
    }
    return null;
  }

  int get completedDailyChallenges =>
      dailyChallenges.where((challenge) => challenge.isCompleted).length;

  int get completedWeeklyChallenges =>
      weeklyChallenges.where((challenge) => challenge.isCompleted).length;

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    coins = prefs.getInt('pp_coins') ?? GameConfig.startingCoins;
    gems = prefs.getInt('pp_gems') ?? GameConfig.startingGems;
    totalLevelsCompleted = prefs.getInt('pp_levels') ?? 0;
    totalStarsEarned = prefs.getInt('pp_stars') ?? 0;
    currentStreak = prefs.getInt('pp_streak') ?? 7;
    longestStreak = prefs.getInt('pp_longest_streak') ?? 12;
    totalPlayTimeSeconds = prefs.getInt('pp_playtime') ?? 0;
    hintsRemaining = prefs.getInt('pp_hints') ?? GameConfig.startingHints;
    hintsUsed = prefs.getInt('pp_hints_used') ?? 0;
    dailyChestClaimed = prefs.getBool('pp_daily_chest') ?? false;
    playerName = prefs.getString('pp_name') ?? 'Player 1';
    hasSetPlayerName = prefs.containsKey('pp_name');
    hasRated = prefs.getBool('pp_has_rated') ?? false;
    unratedWinStreak = prefs.getInt('pp_unrated_streak') ?? 0;
    playerLevel = prefs.getInt('pp_level') ?? 5;
    xp = prefs.getInt('pp_xp') ?? 340;
    xpToNextLevel = prefs.getInt('pp_xp_next') ?? 500;
    activeThemeId = normalizeThemeId(
      prefs.getString('pp_active_theme') ?? prefs.getString('pp_theme'),
    );
    equippedSkin = normalizeSkinId(prefs.getString('pp_skin'));
    equippedTrail = prefs.getString('pp_trail') ?? 'trail_classic';
    equippedVictory = prefs.getString('pp_victory') ?? 'victory_confetti';
    _weeklyComboStreak = prefs.getInt('pp_weekly_combo_streak') ?? 0;
    _weeklyDifficultyProgress
      ..clear()
      ..addAll(prefs.getStringList('pp_weekly_difficulties') ?? const []);

    final savedOwnedItems = prefs.getStringList('pp_owned') ?? const <String>[];
    ownedItems = {
      ..._defaultOwnedItems,
      ...savedOwnedItems,
    }.map(_normalizeOwnedId).toSet();
    ownedItems.removeWhere((id) => id.startsWith('hints_'));

    if (!isOwned(activeThemeId)) activeThemeId = kDefaultThemeId;
    if (!isOwned(equippedSkin)) equippedSkin = 'skin_default';
    if (!isOwned(equippedVictory)) equippedVictory = 'victory_confetti';

    final lastDaily =
        prefs.getString('pp_last_daily_refresh') ??
        prefs.getString('pp_last_refresh');
    final lastWeekly = prefs.getString('pp_last_weekly_refresh');
    lastDailyChallengeRefresh = lastDaily == null
        ? null
        : DateTime.tryParse(lastDaily);
    lastWeeklyChallengeRefresh = lastWeekly == null
        ? null
        : DateTime.tryParse(lastWeekly);

    dailyChallenges = _decodeChallenges(
      prefs.getString('pp_daily_challenges'),
      fallbackFrequency: ChallengeFrequency.daily,
    );
    weeklyChallenges = _decodeChallenges(
      prefs.getString('pp_weekly_challenges'),
      fallbackFrequency: ChallengeFrequency.weekly,
    );

    final achievementsJson = prefs.getString('pp_achievements');
    if (achievementsJson != null) {
      try {
        final decoded = jsonDecode(achievementsJson);
        if (decoded is Map<String, dynamic>) {
          achievements = decoded.map(
            (key, value) => MapEntry(key, value == true),
          );
        }
      } catch (_) {
        achievements = {};
      }
    }
    
    final savedLevelStars = prefs.getString('pp_level_stars');
    if (savedLevelStars != null) {
      try {
        final decoded = jsonDecode(savedLevelStars);
        if (decoded is Map<String, dynamic>) {
          levelStars = decoded.map((key, value) => MapEntry(key, value as int));
        }
      } catch (_) {
        levelStars = {};
      }
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pp_coins', coins);
    await prefs.setInt('pp_gems', gems);
    await prefs.setInt('pp_levels', totalLevelsCompleted);
    await prefs.setInt('pp_stars', totalStarsEarned);
    await prefs.setInt('pp_streak', currentStreak);
    await prefs.setInt('pp_longest_streak', longestStreak);
    await prefs.setInt('pp_playtime', totalPlayTimeSeconds);
    await prefs.setInt('pp_hints', hintsRemaining);
    await prefs.setInt('pp_hints_used', hintsUsed);
    await prefs.setBool('pp_daily_chest', dailyChestClaimed);
    await prefs.setString('pp_name', playerName);
    await prefs.setBool('pp_has_rated', hasRated);
    await prefs.setInt('pp_unrated_streak', unratedWinStreak);
    await prefs.setInt('pp_level', playerLevel);
    await prefs.setInt('pp_xp', xp);
    await prefs.setInt('pp_xp_next', xpToNextLevel);
    await prefs.setString('pp_active_theme', activeThemeId);
    await prefs.setString('pp_skin', equippedSkin);
    await prefs.setString('pp_trail', equippedTrail);
    await prefs.setString('pp_victory', equippedVictory);
    await prefs.setStringList('pp_owned', ownedItems.toList()..sort());
    await prefs.setInt('pp_weekly_combo_streak', _weeklyComboStreak);
    await prefs.setStringList(
      'pp_weekly_difficulties',
      _weeklyDifficultyProgress.toList()..sort(),
    );
    await prefs.setString(
      'pp_daily_challenges',
      jsonEncode(
        dailyChallenges.map((challenge) => challenge.toJson()).toList(),
      ),
    );
    await prefs.setString(
      'pp_weekly_challenges',
      jsonEncode(
        weeklyChallenges.map((challenge) => challenge.toJson()).toList(),
      ),
    );
    await prefs.setString('pp_achievements', jsonEncode(achievements));
    await prefs.setString('pp_level_stars', jsonEncode(levelStars));

    if (lastDailyChallengeRefresh != null) {
      await prefs.setString(
        'pp_last_daily_refresh',
        lastDailyChallengeRefresh!.toIso8601String(),
      );
    }
    if (lastWeeklyChallengeRefresh != null) {
      await prefs.setString(
        'pp_last_weekly_refresh',
        lastWeeklyChallengeRefresh!.toIso8601String(),
      );
    }
  }

  List<Challenge> _decodeChallenges(
    String? encoded, {
    required ChallengeFrequency fallbackFrequency,
  }) {
    if (encoded == null || encoded.isEmpty) return [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(Challenge.fromJson)
          .where((challenge) => challenge.frequency == fallbackFrequency)
          .toList();
    } catch (_) {
      return [];
    }
  }

  bool _spendCurrency(CurrencyType currency, int amount) {
    switch (currency) {
      case CurrencyType.coins:
        if (coins < amount) return false;
        coins -= amount;
        return true;
      case CurrencyType.gems:
        if (gems < amount) return false;
        gems -= amount;
        return true;
    }
  }

  String _normalizeOwnedId(String id) {
    if (id == 'default') return 'skin_default';
    if (id == 'classic') return kDefaultThemeId;
    if (id == 'theme_classic') return kDefaultThemeId;
    if (id.startsWith('theme_')) return normalizeThemeId(id);
    if (id.startsWith('skin_')) return normalizeSkinId(id);
    return id;
  }

  String normalizeSkinId(String? id) {
    if (id == null || id.isEmpty || id == 'default') return 'skin_default';
    if (id.startsWith('skin_')) return id;
    return 'skin_$id';
  }

  String formatPlayTime() {
    final hours = totalPlayTimeSeconds ~/ 3600;
    final minutes = (totalPlayTimeSeconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  void updatePlayerName(String newName) {
    playerName = newName;
    hasSetPlayerName = true;
    _saveData();
    notifyListeners();
  }

  void incrementUnratedWinStreak() {
    if (hasRated) return;
    unratedWinStreak++;
    _saveData();
    notifyListeners();
  }

  void resetUnratedWinStreak() {
    unratedWinStreak = 0;
    _saveData();
    notifyListeners();
  }

  void markHasRated() {
    hasRated = true;
    unratedWinStreak = 0;
    _saveData();
    notifyListeners();
  }
}
