import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../services/player_progress_service.dart';
import '../widgets/mascot_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Consumer<PlayerProgressService>(
          builder: (context, progress, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Header
                  Text(
                        'Profile',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.3, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 20),

                  // Avatar card
                  _buildAvatarCard(context, progress)
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 16),

                  // XP bar
                  _buildXpCard(context, progress)
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 16),

                  // Stats grid
                  _buildStatsGrid(context, progress)
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 16),

                  // Achievements
                  _buildAchievementsCard(context, progress)
                      .animate()
                      .fadeIn(delay: 400.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 16),

                  // Currency card
                  _buildCurrencyCard(context, progress)
                      .animate()
                      .fadeIn(delay: 500.ms, duration: 400.ms)
                      .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAvatarCard(
    BuildContext context,
    PlayerProgressService progress,
  ) {
    final theme = context.zipTheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.accent, theme.accentAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: theme.glow.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          MascotWidget(emotion: MascotEmotion.happy, size: 80)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -4,
                end: 4,
                duration: 2.seconds,
                curve: Curves.easeInOutSine,
              ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onTap: () => _showEditNameModal(context, progress),
                  child: Row(
                    children: [
                      Text(
                        progress.playerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.edit_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Level ${progress.playerLevel} Puzzler',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.local_fire_department_rounded,
                      color: Color(0xFFFFC107),
                      size: 18,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${progress.currentStreak} day streak',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildXpCard(BuildContext context, PlayerProgressService progress) {
    final theme = context.zipTheme;
    final pct = progress.xp / progress.xpToNextLevel;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Experience',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${progress.xp} / ${progress.xpToNextLevel} XP',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: pct),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 12,
                backgroundColor: theme.surfaceAlt,
                valueColor: AlwaysStoppedAnimation<Color>(theme.accent),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${progress.xpToNextLevel - progress.xp} XP to Level ${progress.playerLevel + 1}',
            style: TextStyle(
              color: theme.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, PlayerProgressService progress) {
    final theme = context.zipTheme;
    final stats = [
      _StatItem(
        label: 'Levels Done',
        value: '${progress.totalLevelsCompleted}',
        icon: Icons.check_circle_rounded,
        color: theme.success,
      ),
      _StatItem(
        label: 'Stars Earned',
        value: '${progress.totalStarsEarned}',
        icon: Icons.star_rounded,
        color: theme.warning,
      ),
      _StatItem(
        label: 'Best Streak',
        value: '${progress.longestStreak}d',
        icon: Icons.local_fire_department_rounded,
        color: theme.accentAlt,
      ),
      _StatItem(
        label: 'Play Time',
        value: progress.formatPlayTime(),
        icon: Icons.timer_rounded,
        color: theme.accent,
      ),
      _StatItem(
        label: 'Hints Used',
        value: '${progress.hintsUsed}',
        icon: Icons.lightbulb_rounded,
        color: theme.accent,
      ),
      _StatItem(
        label: 'Hints Left',
        value: '${progress.hintsRemaining}',
        icon: Icons.lightbulb_outline_rounded,
        color: theme.textSecondary,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: stats.length,
      itemBuilder: (context, i) {
        return _StatCard(stat: stats[i], index: i);
      },
    );
  }

  Widget _buildAchievementsCard(
    BuildContext context,
    PlayerProgressService progress,
  ) {
    final theme = context.zipTheme;
    final badges = [
      _Badge(
        emoji: '🧩',
        label: 'First Solve',
        unlocked: progress.totalLevelsCompleted >= 1,
      ),
      _Badge(
        emoji: '🔥',
        label: '7-Day Streak',
        unlocked: progress.currentStreak >= 7,
      ),
      _Badge(
        emoji: '⭐',
        label: '50 Stars',
        unlocked: progress.totalStarsEarned >= 50,
      ),
      _Badge(emoji: '💪', label: 'Hard Mode', unlocked: false),
      _Badge(
        emoji: '🏆',
        label: '100 Levels',
        unlocked: progress.totalLevelsCompleted >= 100,
      ),
      _Badge(emoji: '🚀', label: 'Speed Run', unlocked: false),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Achievements',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: badges.asMap().entries.map((e) {
              return _BadgeWidget(badge: e.value).animate().scale(
                delay: (e.key * 60).ms,
                duration: 300.ms,
                curve: Curves.easeOutBack,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencyCard(
    BuildContext context,
    PlayerProgressService progress,
  ) {
    final theme = context.zipTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _CurrencyRow(
              icon: Icons.monetization_on,
              color: theme.warning,
              label: 'Coins',
              value: '${progress.coins}',
            ),
          ),
          Container(width: 1, height: 40, color: theme.surfaceAlt),
          Expanded(
            child: _CurrencyRow(
              icon: Icons.diamond_rounded,
              color: theme.accent,
              label: 'Gems',
              value: '${progress.gems}',
            ),
          ),
        ],
      ),
    );
  }

  void _showEditNameModal(BuildContext context, PlayerProgressService progress) {
    final theme = context.zipTheme;
    final controller = TextEditingController(text: progress.playerName);
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: theme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Edit Profile',
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Enter your player name (max 12 characters).',
                  style: TextStyle(
                    color: theme.textSecondary,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  maxLength: 12,
                  autofocus: true,
                  style: TextStyle(color: theme.textPrimary),
                  decoration: InputDecoration(
                    hintText: 'Player 1',
                    hintStyle: TextStyle(color: theme.textSecondary.withValues(alpha: 0.5)),
                    filled: true,
                    fillColor: theme.background,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      final name = controller.text.trim();
                      if (name.isNotEmpty) {
                        progress.updatePlayerName(name);
                      }
                      Navigator.of(context).pop();
                    },
                    child: const Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

class _StatItem {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class _StatCard extends StatelessWidget {
  final _StatItem stat;
  final int index;
  const _StatCard({required this.stat, required this.index});

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Container(
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(stat.icon, color: stat.color, size: 22),
          ),
          const SizedBox(height: 6),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: 800 + index * 100),
            curve: Curves.easeOutCubic,
            builder: (_, t, __) {
              return Text(
                stat.value,
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              );
            },
          ),
          Text(
            stat.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: theme.mutedText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge {
  final String emoji;
  final String label;
  final bool unlocked;
  const _Badge({
    required this.emoji,
    required this.label,
    required this.unlocked,
  });
}

class _BadgeWidget extends StatelessWidget {
  final _Badge badge;
  const _BadgeWidget({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Opacity(
      opacity: badge.unlocked ? 1.0 : 0.35,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: badge.unlocked
                  ? theme.warning.withOpacity(0.12)
                  : theme.surfaceAlt,
              shape: BoxShape.circle,
              border: Border.all(
                color: badge.unlocked ? theme.warning : theme.surfaceAlt,
                width: 2,
              ),
            ),
            child: Center(
              child: Text(badge.emoji, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              badge.label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CurrencyRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;

  const _CurrencyRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: theme.mutedText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
