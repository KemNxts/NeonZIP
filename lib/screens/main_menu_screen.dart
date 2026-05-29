import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../models/difficulty.dart';
import '../services/game_state_manager.dart';
import '../services/player_progress_service.dart';
import '../services/settings_service.dart';
import '../widgets/ambient_background.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/mascot_widget.dart';
import 'gameplay_screen.dart';
import 'level_select_screen.dart';
import 'store_screen.dart';
import 'main_shell.dart';


class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({Key? key}) : super(key: key);

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  int _tipIndex = 0;
  final List<String> _tips = [
    'Fill every cell — no gaps allowed!',
    'Visit numbered nodes in order.',
    'Drag back to undo your last move.',
    'Stuck? Use a hint to reveal the next step.',
    'Complete levels without hints for bonus coins!',
    'Try Expert mode for the ultimate challenge.',
  ];

  @override
  void initState() {
    super.initState();
    _rotateTips();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final progress = Provider.of<PlayerProgressService>(context, listen: false);
      if (!progress.hasSetPlayerName) {
        _showWelcomeNameModal(context, progress);
      }
    });
  }

  void _rotateTips() {
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _tipIndex = (_tipIndex + 1) % _tips.length);
      _rotateTips();
    });
  }

  void _navigateToGame(BuildContext context) async {
    final state = Provider.of<GameStateManager>(context, listen: false);
    state.audioEngine.playUIClick();
    await state.generateLevel(Difficulty.beginner);
    if (!mounted) return;
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameplayScreen(),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.05),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 380),
      ),
    );
  }

  void _navigateToLevelSelect(BuildContext context) {
    Provider.of<GameStateManager>(context, listen: false).audioEngine.playUIClick();
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LevelSelectScreen(),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(
            parent: anim,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 320),
      ),
    );
  }

  void _navigateToChallenges(BuildContext context) {
    Provider.of<GameStateManager>(context, listen: false).audioEngine.playUIClick();
    // Find the shell and switch to challenges tab
    final shellState = context.findAncestorStateOfType<MainShellState>();
    if (shellState != null) {
      shellState.switchTab(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: AmbientBackground(
        child: Consumer2<GameStateManager, PlayerProgressService>(
          builder: (context, gameState, progress, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),

                  // Top bar
                  _buildTopBar(progress)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: -0.4, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 20),

                  // Hero
                  _buildHeroSection(context)
                      .animate()
                      .fadeIn(delay: 150.ms, duration: 500.ms)
                      .slideY(begin: -0.15, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 28),

                  // Play button: gentle breathing scale + shimmer sweep.
                  _buildPlayButton(context)
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.025, 1.025),
                        duration: 2400.ms,
                        curve: Curves.easeInOutSine,
                      )
                      .shimmer(
                        duration: 2400.ms,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),

                  const SizedBox(height: 14),

                  // Daily Challenge
                  _buildSecondaryButton(
                    context: context,
                    text: 'Daily Challenge',
                    icon: Icons.calendar_month_rounded,
                    badgeText: progress.completedDailyChallenges < 3
                        ? '${3 - progress.completedDailyChallenges} left'
                        : '✓',
                    badgeColor: progress.completedDailyChallenges < 3
                        ? theme.danger
                        : theme.success,
                    onPressed: () => _navigateToChallenges(context),
                  ).animate().scale(
                    delay: 300.ms,
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

                  const SizedBox(height: 14),

                  // Level Select
                  _buildSecondaryButton(
                    context: context,
                    text: 'Level Select',
                    icon: Icons.grid_view_rounded,
                    onPressed: () => _navigateToLevelSelect(context),
                  ).animate().scale(
                    delay: 400.ms,
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  ),

                  const SizedBox(height: 24),

                  // Streak banner
                  _buildStreakBanner(context, progress)
                      .animate()
                      .fadeIn(delay: 500.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 16),

                  // Tip card
                  _buildTipCard(context)
                      .animate()
                      .fadeIn(delay: 650.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTopBar(PlayerProgressService progress) {
    final theme = context.zipTheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: theme.surfaceAlt,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.person, color: theme.mutedText),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  progress.playerName,
                  style: TextStyle(
                    color: theme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Level ${progress.playerLevel}',
                  style: TextStyle(
                    color: theme.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        Row(
          children: [
            _buildCurrencyChip(
              context,
              '${_formatNumber(progress.coins)}',
              theme.warning,
              Icons.monetization_on,
            ),
            const SizedBox(width: 8),
            _buildCurrencyChip(
              context,
              '${progress.gems}',
              theme.accent,
              Icons.diamond_rounded,
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.settings, color: theme.mutedText),
              onPressed: () => _showSettings(context),
            ),
          ],
        ),
      ],
    );
  }

  void _showSettings(BuildContext context) {
    Provider.of<GameStateManager>(context, listen: false).audioEngine.playUIClick();
    final theme = context.zipTheme;
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Settings',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Path Style',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Consumer<SettingsService>(
                builder: (context, settings, _) {
                  return Row(
                    children: [
                      Expanded(
                        child: _buildSettingOption(
                          context: context,
                          title: 'Classic',
                          isSelected: settings.pathStyle == PathStyle.classic,
                          onTap: () {
                            Provider.of<GameStateManager>(context, listen: false).audioEngine.playUIClick();
                            settings.setPathStyle(PathStyle.classic);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSettingOption(
                          context: context,
                          title: 'Terminal Dot',
                          isSelected: settings.pathStyle == PathStyle.terminalDot,
                          onTap: () {
                            Provider.of<GameStateManager>(context, listen: false).audioEngine.playUIClick();
                            settings.setPathStyle(PathStyle.terminalDot);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingOption({
    required BuildContext context,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = context.zipTheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.surfaceAlt : theme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? theme.accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? theme.accent : theme.textSecondary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrencyChip(
    BuildContext context,
    String value,
    Color color,
    IconData icon,
  ) {
    final theme = context.zipTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            value,
            style: TextStyle(
              color: theme.textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final theme = context.zipTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ZIP',
          style: TextStyle(
            color: theme.accent,
            fontSize: 64,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        Text(
          'PUZZLE',
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 52,
            fontWeight: FontWeight.w900,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Unzip the path,\nconnect all the dots!',
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 16,
            fontWeight: FontWeight.w500,
            height: 1.4,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () {
              Provider.of<GameStateManager>(context, listen: false).audioEngine.playUIClick();
              HapticFeedback.lightImpact();
              final shellState = context.findAncestorStateOfType<MainShellState>();
              if (shellState != null) {
                shellState.switchTab(2); // Wardrobe/Store tab
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreScreen()));
              }
            },
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                // Layered UI enhancement behind
                Positioned(
                  child: Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: theme.accent.withOpacity(0.4),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.08, 1.08), duration: 2.seconds),
                ),
                const MascotWidget(emotion: MascotEmotion.idle, size: 150),
                // Layered UI enhancement in front
                Positioned(
                  bottom: -15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: theme.shadow, blurRadius: 10, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.edit, size: 14, color: theme.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'Customize',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],

    );
  }

  Widget _buildPlayButton(BuildContext context) {
    final theme = context.zipTheme;
    return BouncingButton(
      onPressed: () => _navigateToGame(context),
      child: Container(
        height: 70,
        decoration: BoxDecoration(
          color: theme.success,
          borderRadius: BorderRadius.circular(35),
          boxShadow: [
            BoxShadow(
              color: theme.success.withOpacity(0.35),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Play Game',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required BuildContext context,
    required String text,
    required IconData icon,
    required VoidCallback onPressed,
    String? badgeText,
    Color badgeColor = const Color(0xFFF43F5E),
  }) {
    final theme = context.zipTheme;
    return BouncingButton(
      onPressed: onPressed,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(34),
          boxShadow: [
            BoxShadow(
              color: theme.shadow,
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: theme.textSecondary, size: 26),
            const SizedBox(width: 14),
            Text(
              text,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Spacer(),
            if (badgeText != null)
              Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      badgeText,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.08, 1.08),
                    duration: 900.ms,
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakBanner(
    BuildContext context,
    PlayerProgressService progress,
  ) {
    final theme = context.zipTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.accent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Streak',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${progress.currentStreak}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'days — keep it up!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.card_giftcard_rounded, color: theme.warning, size: 44)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .rotate(
                begin: -0.08,
                end: 0.08,
                duration: 1.2.seconds,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }

  Widget _buildTipCard(BuildContext context) {
    final theme = context.zipTheme;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.15),
            end: Offset.zero,
          ).animate(anim),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_tipIndex),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: theme.surfaceAlt),
        ),
        child: Row(
          children: [
            const Text('💡', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _tips[_tipIndex],
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showWelcomeNameModal(BuildContext context, PlayerProgressService progress) {
    final theme = context.zipTheme;
    final controller = TextEditingController(text: '');
    
    showDialog(
      context: context,
      barrierDismissible: false, // Force them to enter a name
      builder: (context) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button dismissal
          child: Dialog(
            backgroundColor: theme.surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Welcome to NeonZIP!',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Enter your player name to get started (max 12 characters).',
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
                          Provider.of<GameStateManager>(context, listen: false).audioEngine.playUIClick();
                          progress.updatePlayerName(name);
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text(
                        'Start Playing',
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
          ),
        );
      },
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(1)}k';
    }
    return '$n';
  }
}
