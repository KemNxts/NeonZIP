import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../models/difficulty.dart';
import '../services/game_state_manager.dart';
import '../services/player_progress_service.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/mascot_widget.dart';
import 'gameplay_screen.dart';

class LevelSelectScreen extends StatefulWidget {
  const LevelSelectScreen({Key? key}) : super(key: key);

  @override
  State<LevelSelectScreen> createState() => _LevelSelectScreenState();
}

class _LevelSelectScreenState extends State<LevelSelectScreen> {
  Difficulty _currentDifficulty = Difficulty.beginner;
  int _maxLevels = 0;
  int _maxUnlocked = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final state = Provider.of<GameStateManager>(context, listen: false);
    _maxLevels = await state.levelManager.getMaxLevels(_currentDifficulty);
    _maxUnlocked = state.levelManager.getMaxUnlockedLevel(_currentDifficulty);
    setState(() => _isLoading = false);
  }

  void _goBack() {
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    final progress = context.watch<PlayerProgressService>();
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context)
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: -0.4, end: 0, curve: Curves.easeOutCubic),

            const SizedBox(height: 16),

            _buildDifficultyTabs().animate().fadeIn(
              delay: 150.ms,
              duration: 300.ms,
            ),

            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 28,
                      ),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 0.85,
                          ),
                      itemCount: _maxLevels,
                      itemBuilder: (context, index) {
                        int levelId = index + 1;
                        bool isUnlocked = levelId <= _maxUnlocked;
                        bool isCurrent = levelId == _maxUnlocked;
                        int starsEarned = progress.levelStars['${_currentDifficulty.name}_$levelId'] ?? 0;

                        return _buildLevelCard(
                              context,
                              levelId,
                              isUnlocked,
                              isCurrent,
                              starsEarned,
                            )
                            .animate()
                            .scale(
                              delay: (index * 18).ms,
                              duration: 320.ms,
                              begin: const Offset(0.5, 0.5),
                              end: const Offset(1.0, 1.0),
                              curve: Curves.easeOutBack,
                            )
                            .fadeIn(
                              delay: (index * 18).ms,
                              duration: 220.ms,
                            );
                      },
                    ),
            ),

            _buildClassicModeBanner()
                .animate()
                .fadeIn(delay: 400.ms)
                .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = context.zipTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BouncingButton(
            onPressed: _goBack,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new,
                color: theme.textPrimary,
                size: 20,
              ),
            ),
          ),
          Text(
            'Level Select',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          Row(
            children: [
              Icon(Icons.star_rounded, color: theme.warning, size: 26),
              const SizedBox(width: 4),
              Text(
                '$_maxUnlocked/$_maxLevels',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultyTabs() {
    final theme = context.zipTheme;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      physics: const BouncingScrollPhysics(),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.surface,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: theme.shadow,
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTabItem(Difficulty.beginner, 'Beginner', theme.success),
            _buildTabItem(Difficulty.medium, 'Medium', theme.warning),
            _buildTabItem(Difficulty.hard, 'Hard', theme.danger),
          ],
        ),
      ),
    );
  }

  Widget _buildTabItem(Difficulty diff, String label, Color color) {
    final theme = context.zipTheme;
    bool isSelected = _currentDifficulty == diff;
    Color activeColor = diff == Difficulty.hard ? theme.danger : Colors.white;
    Color bgColor = isSelected ? color : Colors.transparent;
    Color textColor = isSelected ? activeColor : theme.mutedText;

    return BouncingButton(
      onPressed: () {
        setState(() {
          _currentDifficulty = diff;
          _loadData();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutBack,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    int levelId,
    bool isUnlocked,
    bool isCurrent,
    int starsEarned,
  ) {
    final theme = context.zipTheme;
    Color cardColor = isUnlocked ? theme.surface : theme.surfaceAlt;
    if (isCurrent) cardColor = theme.navActive;

    Widget content;
    if (isUnlocked) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$levelId',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(3, (index) {
                return Icon(
                  Icons.star_rounded,
                  color: index < starsEarned
                      ? (isCurrent ? Colors.white : theme.warning)
                      : (isCurrent ? Colors.white.withOpacity(0.5) : theme.surfaceAlt),
                  size: 13,
                );
              }),
            ],
          ),
        ],
      );
    } else {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$levelId',
            style: TextStyle(
              color: theme.mutedText,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Icon(Icons.lock_rounded, color: theme.mutedText, size: 16),
        ],
      );
    }

    return BouncingButton(
      onPressed: () async {
        if (isUnlocked) {
          final state = Provider.of<GameStateManager>(context, listen: false);
          await state.loadSpecificLevel(_currentDifficulty, levelId);
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
                      begin: const Offset(0, 0.06),
                      end: Offset.zero,
                    ).animate(curved),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 360),
            ),
          );
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            if (isUnlocked)
              BoxShadow(
                color: isCurrent
                    ? theme.warning.withOpacity(0.35)
                    : theme.shadow,
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
          ],
        ),
        child: content,
      ),
    );
  }

  Widget _buildClassicModeBanner() {
    final theme = context.zipTheme;
    String gridSizeStr = '5×5 Grid';
    if (_currentDifficulty == Difficulty.medium) gridSizeStr = '7×7 Grid';
    if (_currentDifficulty == Difficulty.hard) gridSizeStr = '9×9 Grid';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [theme.accent, theme.accentAlt],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: theme.glow.withOpacity(0.3),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Classic Mode',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  gridSizeStr,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const MascotWidget(emotion: MascotEmotion.happy, size: 55)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(
                begin: -4,
                end: 4,
                duration: 1.2.seconds,
                curve: Curves.easeInOut,
              ),
        ],
      ),
    );
  }
}
