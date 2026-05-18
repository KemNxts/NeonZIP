import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../services/game_state_manager.dart';
import '../services/player_progress_service.dart';
import '../widgets/bouncing_button.dart';
import '../widgets/game_board_widget.dart';
import '../widgets/level_complete_overlay.dart';
import '../widgets/mascot_widget.dart';
import 'main_shell.dart';

class GameplayScreen extends StatefulWidget {
  const GameplayScreen({Key? key}) : super(key: key);

  @override
  State<GameplayScreen> createState() => _GameplayScreenState();
}

class _GameplayScreenState extends State<GameplayScreen> {
  bool _showEncouragement = false;
  String _encouragementText = '';
  int _lastPathLength = 0;

  // Timer
  int _elapsedSeconds = 0;
  Timer? _timer;
  bool _usedHintThisLevel = false;
  int _earnedStarsThisLevel = 0;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsedSeconds++);
    });
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _checkEncouragement(GameStateManager state) {
    if (state.board == null) return;
    int totalCells = state.board!.size * state.board!.size;
    int currentLen = state.playerPath.points.length;

    if (currentLen > _lastPathLength && currentLen > 0) {
      double progress = currentLen / totalCells;
      if (progress >= 0.5 && _lastPathLength / totalCells < 0.5) {
        _triggerEncouragement('Nice move!\nYou\'re doing great!');
      } else if (progress >= 0.75 && _lastPathLength / totalCells < 0.75) {
        _triggerEncouragement('Almost there!\nKeep going!');
      }
    }
    _lastPathLength = currentLen;
  }

  void _triggerEncouragement(String text) {
    setState(() {
      _showEncouragement = true;
      _encouragementText = text;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _showEncouragement = false);
    });
  }

  void _showHintDialog(BuildContext context, GameStateManager state) {
    final progress = Provider.of<PlayerProgressService>(context, listen: false);
    final theme = context.zipTheme;

    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (ctx) {
        return Center(
          child:
              Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: GestureDetector(
                            onTap: () => Navigator.of(ctx).pop(),
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: theme.surfaceAlt,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.close,
                                color: theme.textSecondary,
                                size: 20,
                              ),
                            ),
                          ),
                        ),
                        const MascotWidget(
                          emotion: MascotEmotion.thinking,
                          size: 120,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Need a hint?',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Reveal the next correct move!',
                          style: TextStyle(
                            color: theme.textSecondary,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 24),
                        BouncingButton(
                          onPressed: () {
                            if (progress.hintsRemaining > 0 &&
                                state.applyHint()) {
                              progress.useHint();
                              _usedHintThisLevel = true;
                            }
                            Navigator.of(ctx).pop();
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: progress.hintsRemaining > 0
                                  ? theme.accent
                                  : theme.surfaceAlt,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: progress.hintsRemaining > 0
                                  ? [
                                      BoxShadow(
                                        color: theme.accent.withOpacity(0.3),
                                        blurRadius: 15,
                                        offset: const Offset(0, 6),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.lightbulb_rounded,
                                    color: Color(0xFFFFC107),
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'Use Hint',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${progress.hintsRemaining}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 250.ms)
                  .scale(
                    begin: const Offset(0.75, 0.75),
                    end: const Offset(1.0, 1.0),
                    duration: 420.ms,
                    curve: Curves.easeOutBack,
                  ),
        );
      },
    );
  }

  int _calculateStars(GameStateManager state) {
    int stars = 3;
    if (_usedHintThisLevel) stars -= 1;
    if (state.movesCounter > 5) stars -= 1;
    int parTime = (state.board?.size ?? 5) * 10;
    if (_elapsedSeconds > parTime) stars -= 1;
    return stars.clamp(1, 3);
  }

  void _onLevelComplete(GameStateManager state) {
    _timer?.cancel();
    _earnedStarsThisLevel = _calculateStars(state);
    final progress = Provider.of<PlayerProgressService>(context, listen: false);
    progress.onLevelCompleted(
      levelId: state.levelManager.currentLevelId,
      starsEarned: _earnedStarsThisLevel,
      usedHints: _usedHintThisLevel,
      timeTakenSeconds: _elapsedSeconds,
      difficulty: state.currentDifficulty.name,
    );
  }

  void _goHome(GameStateManager state) {
    _timer?.cancel();
    state.backToMenu();
    Navigator.of(context).pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Consumer<GameStateManager>(
          builder: (context, state, child) {
            // Level complete hook
            if (state.state == GameState.levelComplete) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_timer?.isActive ?? false) _onLevelComplete(state);
              });
            }

            WidgetsBinding.instance.addPostFrameCallback((_) {
              _checkEncouragement(state);
            });

            return Stack(
              children: [
                Column(
                  children: [
                    _buildTopBar(context, state)
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(
                          begin: -0.4,
                          end: 0,
                          curve: Curves.easeOutCubic,
                        ),

                    _buildStatsBar(
                      state,
                    ).animate().fadeIn(delay: 100.ms, duration: 400.ms),

                    Expanded(
                      child: Stack(
                        children: [
                          const GameBoardWidget(),

                          // Mascot corner
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: _buildGameplayMascot(state),
                          ),

                          // Encouragement bubble
                          if (_showEncouragement)
                            Positioned(
                              bottom: 90,
                              left: 16,
                              child: _buildEncouragementBubble()
                                  .animate()
                                  .fadeIn(duration: 150.ms)
                                  .scale(
                                    begin: const Offset(0.6, 0.6),
                                    end: const Offset(1.0, 1.0),
                                    duration: 500.ms,
                                    curve: Curves.elasticOut,
                                  )
                                  .slideY(
                                    begin: 0.3,
                                    end: 0,
                                    duration: 300.ms,
                                    curve: Curves.easeOutCubic,
                                  )
                                  .then(delay: 1400.ms)
                                  .fadeOut(duration: 250.ms),
                            ),
                        ],
                      ),
                    ),

                    _buildBottomBar(context, state)
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .slideY(begin: 0.4, end: 0, curve: Curves.easeOutCubic),
                  ],
                ),

                if (state.state == GameState.levelComplete)
                  LevelCompleteOverlay(
                    levelId: state.levelManager.currentLevelId,
                    starsEarned: _earnedStarsThisLevel,
                    onNextLevel: () async {
                      _usedHintThisLevel = false;
                      _earnedStarsThisLevel = 0;
                      _startTimer();
                      int nextId = state.levelManager.currentLevelId + 1;
                      int maxLevels = await state.levelManager.getMaxLevels(
                        state.currentDifficulty,
                      );
                      if (nextId > maxLevels) {
                        _goHome(state);
                      } else {
                        await state.loadSpecificLevel(
                          state.currentDifficulty,
                          nextId,
                        );
                      }
                    },
                    onBackToHome: () => _goHome(state),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildGameplayMascot(GameStateManager state) {
    MascotEmotion emotion = MascotEmotion.idle;
    if (state.board != null) {
      int total = state.board!.size * state.board!.size;
      int current = state.playerPath.points.length;
      if (current > total * 0.75) {
        emotion = MascotEmotion.cheer;
      } else if (current > total * 0.5) {
        emotion = MascotEmotion.happy;
      }
    }
    return MascotWidget(emotion: emotion, size: 55);
  }

  Widget _buildEncouragementBubble() {
    final theme = context.zipTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        _encouragementText,
        style: TextStyle(
          color: theme.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context, GameStateManager state) {
    final theme = context.zipTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          BouncingButton(
            onPressed: () => _goHome(state),
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
            'Level ${state.levelManager.currentLevelId}',
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
          Consumer<PlayerProgressService>(
            builder: (_, progress, __) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: theme.surface,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: theme.shadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    '${progress.coins}',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: theme.warning,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.monetization_on,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsBar(GameStateManager state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem('Moves', '${state.movesCounter}'),
          _buildStatItem('Time', _formatTime(_elapsedSeconds)),
          _buildStatItem('Goal', '⚡'),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    final theme = context.zipTheme;
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 19,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context, GameStateManager state) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildActionButton(
            icon: Icons.undo_rounded,
            label: 'Undo',
            onPressed: () => state.undoLastPoint(),
          ),
          _buildActionButton(
            icon: Icons.refresh_rounded,
            label: 'Reset',
            onPressed: () {
              state.resetLevel();
              Provider.of<PlayerProgressService>(
                context,
                listen: false,
              ).recordLevelReset();
              _lastPathLength = 0;
            },
          ),
          Consumer<PlayerProgressService>(
            builder: (_, progress, __) =>
                _buildActionButton(
                      icon: Icons.lightbulb_rounded,
                      label: 'Hint',
                      color: context.zipTheme.accent,
                      textColor: Colors.white,
                      badgeCount: progress.hintsRemaining,
                      onPressed: () => _showHintDialog(context, state),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.06, 1.06),
                      duration: 900.ms,
                      curve: Curves.easeInOutSine,
                    )
                    .shimmer(
                      duration: 1800.ms,
                      delay: 400.ms,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    Color color = Colors.white,
    Color textColor = const Color(0xFF1E293B),
    int? badgeCount,
  }) {
    final theme = context.zipTheme;
    final isSurfaceButton = color == Colors.white;
    final effectiveColor = isSurfaceButton ? theme.surface : color;
    final effectiveTextColor = textColor == const Color(0xFF1E293B)
        ? theme.textPrimary
        : textColor;
    return BouncingButton(
      onPressed: onPressed,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: effectiveColor,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: color == Colors.white
                      ? theme.shadow
                      : effectiveColor.withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: effectiveTextColor, size: 26),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    color: effectiveTextColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (badgeCount != null)
            Positioned(
              top: -8,
              right: -8,
              child: Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: theme.success,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badgeCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
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
