import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../models/challenge.dart';
import '../services/player_progress_service.dart';
import '../widgets/mascot_widget.dart';
import '../widgets/bouncing_button.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({Key? key}) : super(key: key);

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Consumer<PlayerProgressService>(
          builder: (context, progress, _) {
            final allDailyDone = progress.dailyChallenges.every(
              (c) => c.isCompleted && c.isClaimed,
            );
            final mascotEmotion = allDailyDone
                ? MascotEmotion.cheer
                : MascotEmotion.happy;

            return Column(
              children: [
                // Header
                _buildHeader(progress, mascotEmotion)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.3, end: 0, curve: Curves.easeOutCubic),

                // Tab bar
                _buildTabBar().animate().fadeIn(
                  delay: 150.ms,
                  duration: 300.ms,
                ),

                // Content
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _DailyChallengesTab(progress: progress),
                      _WeeklyChallengesTab(progress: progress),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(PlayerProgressService progress, MascotEmotion emotion) {
    final theme = context.zipTheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Challenges',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${progress.completedDailyChallenges}/${progress.dailyChallenges.length} daily done',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          MascotWidget(emotion: emotion, size: 70)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -4,
                end: 4,
                duration: 2.seconds,
                curve: Curves.easeInOutSine,
              ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    final theme = context.zipTheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: theme.accent,
          borderRadius: BorderRadius.circular(24),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: Colors.white,
        unselectedLabelColor: theme.mutedText,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: 'Daily'),
          Tab(text: 'Weekly'),
        ],
      ),
    );
  }
}

// ── Daily Tab ──────────────────────────────────────────────────────────────

class _DailyChallengesTab extends StatelessWidget {
  final PlayerProgressService progress;
  const _DailyChallengesTab({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        // Streak card
        _StreakCard(progress: progress)
            .animate()
            .fadeIn(delay: 100.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

        const SizedBox(height: 20),

        Text(
          'Today\'s Challenges',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),

        ...progress.dailyChallenges.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child:
                _ChallengeCard(
                      challenge: entry.value,
                      onClaim: () => _claimChallengeReward(
                        context,
                        progress,
                        entry.value.id,
                      ),
                    )
                    .animate()
                    .fadeIn(delay: (200 + entry.key * 80).ms)
                    .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
          );
        }),

        const SizedBox(height: 8),
        _RewardChestCard(progress: progress)
            .animate()
            .fadeIn(delay: 500.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
      ],
    );
  }
}

// ── Weekly Tab ─────────────────────────────────────────────────────────────

class _WeeklyChallengesTab extends StatelessWidget {
  final PlayerProgressService progress;
  const _WeeklyChallengesTab({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      children: [
        // Weekly progress summary
        _WeeklyProgressCard(progress: progress)
            .animate()
            .fadeIn(delay: 100.ms)
            .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

        const SizedBox(height: 20),

        Text(
          'Weekly Missions',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),

        ...progress.weeklyChallenges.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child:
                _ChallengeCard(
                      challenge: entry.value,
                      onClaim: () => _claimChallengeReward(
                        context,
                        progress,
                        entry.value.id,
                      ),
                      isWeekly: true,
                    )
                    .animate()
                    .fadeIn(delay: (200 + entry.key * 80).ms)
                    .slideX(begin: 0.15, end: 0, curve: Curves.easeOutCubic),
          );
        }),
      ],
    );
  }
}

// ── Streak Card ────────────────────────────────────────────────────────────

void _claimChallengeReward(
  BuildContext context,
  PlayerProgressService progress,
  String challengeId,
) {
  final rewards = progress.claimChallenge(challengeId);
  if (rewards.isEmpty) return;
  final theme = context.zipTheme;
  final rewardText = rewards
      .map((reward) {
        switch (reward.type) {
          case RewardType.coins:
            return '+${reward.amount} coins';
          case RewardType.gems:
            return '+${reward.amount} gems';
          case RewardType.streakProgress:
            return '+${reward.amount} streak';
        }
      })
      .join('  ');

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        'Reward claimed: $rewardText',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      backgroundColor: theme.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      duration: const Duration(seconds: 2),
    ),
  );
}

class _StreakCard extends StatelessWidget {
  final PlayerProgressService progress;
  const _StreakCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.warning, theme.danger],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.warning.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
            size: 40,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Streak',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${progress.currentStreak} days',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Best',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                '${progress.longestStreak}d',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Weekly Progress Card ───────────────────────────────────────────────────

class _WeeklyProgressCard extends StatelessWidget {
  final PlayerProgressService progress;
  const _WeeklyProgressCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    final done = progress.completedWeeklyChallenges;
    final total = progress.weeklyChallenges.length;
    final pct = total > 0 ? done / total : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.accent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Weekly Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '$done/$total',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: Colors.white24,
              valueColor: AlwaysStoppedAnimation<Color>(theme.warning),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete all missions for a gem bonus!',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Challenge Card ─────────────────────────────────────────────────────────

class _ChallengeCard extends StatelessWidget {
  final Challenge challenge;
  final VoidCallback onClaim;
  final bool isWeekly;

  const _ChallengeCard({
    required this.challenge,
    required this.onClaim,
    this.isWeekly = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    final bool canClaim = challenge.isCompleted && !challenge.isClaimed;
    final bool isDone = challenge.isClaimed;

    Color borderColor = theme.surfaceAlt;
    if (canClaim) borderColor = theme.success;
    if (isDone) borderColor = theme.surfaceAlt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: canClaim ? theme.success.withOpacity(0.12) : theme.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(challenge.iconEmoji, style: const TextStyle(fontSize: 28)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      challenge.title,
                      style: TextStyle(
                        color: isDone ? theme.mutedText : theme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        decoration: isDone ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    Text(
                      challenge.description,
                      style: TextStyle(
                        color: theme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (canClaim)
                BouncingButton(
                      onPressed: onClaim,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: theme.success,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Claim!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.05, 1.05),
                      duration: 800.ms,
                    ),
              if (isDone)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.success.withOpacity(0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.check, color: theme.success, size: 18),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: challenge.progress,
              minHeight: 8,
              backgroundColor: theme.surfaceAlt,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone
                    ? theme.mutedText
                    : canClaim
                    ? theme.success
                    : isWeekly
                    ? theme.accent
                    : theme.warning,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${challenge.currentValue}/${challenge.targetValue}',
                style: TextStyle(
                  color: theme.mutedText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              // Rewards preview
              Row(
                children: challenge.rewards.map((r) {
                  final isCoins = r.type == RewardType.coins;
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Row(
                      children: [
                        Icon(
                          isCoins
                              ? Icons.monetization_on
                              : Icons.diamond_rounded,
                          color: isCoins ? theme.warning : theme.accent,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          '+${r.amount}',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Reward Chest Card ──────────────────────────────────────────────────────

class _RewardChestCard extends StatelessWidget {
  final PlayerProgressService progress;
  const _RewardChestCard({required this.progress});

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    final allDone =
        progress.dailyChallenges.isNotEmpty &&
        progress.dailyChallenges.every((c) => c.isClaimed);
    final completedCount = progress.completedDailyChallenges;
    final total = progress.dailyChallenges.length;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: allDone
              ? [theme.warning, theme.accentAlt]
              : [theme.surfaceAlt, theme.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: allDone ? theme.warning.withOpacity(0.3) : theme.shadow,
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(allDone ? '🎁' : '📦', style: const TextStyle(fontSize: 44))
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(
                begin: -0.05,
                end: 0.05,
                duration: 1.5.seconds,
                curve: Curves.easeInOut,
              ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone ? 'Reward Chest!' : 'Daily Chest',
                  style: TextStyle(
                    color: allDone ? Colors.white : theme.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  allDone
                      ? 'All challenges done! Claim your reward.'
                      : 'Complete all $total challenges to unlock.',
                  style: TextStyle(
                    color: allDone ? Colors.white70 : theme.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!allDone) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: total > 0 ? completedCount / total : 0,
                      minHeight: 6,
                      backgroundColor: theme.surface,
                      valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (allDone)
            BouncingButton(
              onPressed: () {},
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Open!',
                  style: TextStyle(
                    color: theme.warning,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
