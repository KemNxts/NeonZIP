enum ChallengeType {
  completeNLevels,
  finishWithoutHints,
  finishUnderTime,
  finishHardLevel,
  comboStreak,
  completeAllDifficulties,
  collectStars,
}

enum ChallengeFrequency { daily, weekly }

enum RewardType { coins, gems, streakProgress }

class ChallengeReward {
  final RewardType type;
  final int amount;
  const ChallengeReward({required this.type, required this.amount});

  Map<String, dynamic> toJson() => {'type': type.name, 'amount': amount};

  factory ChallengeReward.fromJson(Map<String, dynamic> json) {
    return ChallengeReward(
      type: RewardType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => RewardType.coins,
      ),
      amount: (json['amount'] as num?)?.toInt() ?? 0,
    );
  }
}

class Challenge {
  final String id;
  final String title;
  final String description;
  final ChallengeType type;
  final ChallengeFrequency frequency;
  final int targetValue;
  int currentValue;
  bool isCompleted;
  bool isClaimed;
  final List<ChallengeReward> rewards;
  final String iconEmoji;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.frequency,
    required this.targetValue,
    this.currentValue = 0,
    this.isCompleted = false,
    this.isClaimed = false,
    required this.rewards,
    required this.iconEmoji,
  });

  double get progress =>
      (currentValue / targetValue).clamp(0.0, 1.0).toDouble();

  Challenge copyWith({int? currentValue, bool? isCompleted, bool? isClaimed}) {
    return Challenge(
      id: id,
      title: title,
      description: description,
      type: type,
      frequency: frequency,
      targetValue: targetValue,
      currentValue: currentValue ?? this.currentValue,
      isCompleted: isCompleted ?? this.isCompleted,
      isClaimed: isClaimed ?? this.isClaimed,
      rewards: rewards,
      iconEmoji: iconEmoji,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'type': type.name,
    'frequency': frequency.name,
    'targetValue': targetValue,
    'currentValue': currentValue,
    'isCompleted': isCompleted,
    'isClaimed': isClaimed,
    'rewards': rewards.map((reward) => reward.toJson()).toList(),
    'iconEmoji': iconEmoji,
  };

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      type: ChallengeType.values.firstWhere(
        (value) => value.name == json['type'],
        orElse: () => ChallengeType.completeNLevels,
      ),
      frequency: ChallengeFrequency.values.firstWhere(
        (value) => value.name == json['frequency'],
        orElse: () => ChallengeFrequency.daily,
      ),
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 1,
      currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
      isClaimed: json['isClaimed'] as bool? ?? false,
      rewards: (json['rewards'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ChallengeReward.fromJson)
          .toList(),
      iconEmoji: json['iconEmoji'] as String? ?? '',
    );
  }
}
