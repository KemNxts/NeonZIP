import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:confetti/confetti.dart';
import '../models/app_theme.dart';
import 'bouncing_button.dart';
import 'mascot_widget.dart';

class LevelCompleteOverlay extends StatefulWidget {
  final VoidCallback onNextLevel;
  final VoidCallback onBackToHome;
  final int levelId;
  final int starsEarned;

  const LevelCompleteOverlay({
    Key? key,
    required this.onNextLevel,
    required this.onBackToHome,
    this.levelId = 1,
    this.starsEarned = 3,
  }) : super(key: key);

  @override
  State<LevelCompleteOverlay> createState() => _LevelCompleteOverlayState();
}

class _LevelCompleteOverlayState extends State<LevelCompleteOverlay> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 4),
    );
    _confettiController.play();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Stack(
      children: [
        // Dim backdrop
        Container(color: theme.scrim),

        // Confetti from top
        Align(
          alignment: Alignment.topCenter,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirectionality: BlastDirectionality.explosive,
            shouldLoop: false,
            emissionFrequency: 0.06,
            numberOfParticles: 20,
            maxBlastForce: 30,
            minBlastForce: 10,
            gravity: 0.15,
            colors: [
              theme.warning,
              theme.success,
              theme.accent,
              theme.danger,
              theme.accentAlt,
              theme.pathStart,
            ],
            createParticlePath: _drawStar,
          ),
        ),

        // Main Card
        Center(
          child:
              Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                    decoration: BoxDecoration(
                      color: theme.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadow,
                          blurRadius: 40,
                          offset: const Offset(0, 20),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cheering Mascot peeking above card
                        Transform.translate(
                          offset: const Offset(0, -40),
                          child:
                              const MascotWidget(
                                emotion: MascotEmotion.cheer,
                                size: 130,
                              ).animate().scale(
                                delay: 200.ms,
                                duration: 600.ms,
                                curve: Curves.elasticOut,
                              ),
                        ),

                        Text(
                          'Well Done!',
                          style: TextStyle(
                            color: theme.textPrimary,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ).animate().scale(
                          delay: 300.ms,
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                        ),

                        const SizedBox(height: 4),
                        Text(
                          'Level ${widget.levelId} Completed',
                          style: TextStyle(
                            color: theme.mutedText,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ).animate().fadeIn(delay: 400.ms),

                        const SizedBox(height: 24),

                        // Animated Stars
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildAnimatedStar(context, 0, false),
                            _buildAnimatedStar(context, 1, true),
                            _buildAnimatedStar(context, 2, false),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // Rewards row
                        Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                _buildRewardChip(
                                  context,
                                  Icons.monetization_on_rounded,
                                  theme.warning,
                                  '+120',
                                ),
                                const SizedBox(width: 16),
                                _buildRewardChip(
                                  context,
                                  Icons.diamond_rounded,
                                  theme.accent,
                                  '+10',
                                ),
                              ],
                            )
                            .animate()
                            .fadeIn(delay: 900.ms, duration: 300.ms)
                            .slideY(
                              begin: 0.5,
                              end: 0,
                              delay: 900.ms,
                              duration: 500.ms,
                              curve: Curves.easeOutBack,
                            ),

                        const SizedBox(height: 32),

                        // Next Level button
                        BouncingButton(
                          onPressed: widget.onNextLevel,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20),
                            decoration: BoxDecoration(
                              color: theme.success,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: theme.success.withSafeOpacity(0.3),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Next Level',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Icon(
                                  Icons.arrow_forward_rounded,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ],
                            ),
                          ),
                        ).animate().scale(
                          delay: 1100.ms,
                          duration: 600.ms,
                          curve: Curves.elasticOut,
                        ),

                        const SizedBox(height: 12),

                        // Back to Home
                        BouncingButton(
                          onPressed: widget.onBackToHome,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            decoration: BoxDecoration(
                              color: theme.surface,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: theme.surfaceAlt,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Back to Home',
                                style: TextStyle(
                                  color: theme.textSecondary,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ).animate().fadeIn(delay: 1300.ms, duration: 400.ms),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .scale(
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),
        ),
      ],
    );
  }

  Widget _buildAnimatedStar(BuildContext context, int index, bool isCenter) {
    final theme = context.zipTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: isCenter ? 16.0 : 0.0),
      child:
          Icon(
                Icons.star_rounded,
                color: index < widget.starsEarned ? theme.warning : theme.surfaceAlt,
                size: isCenter ? 72 : 56,
              )
              .animate(delay: (500 + index * 200).ms)
              .scale(
                begin: const Offset(0, 0),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .rotate(
                begin: -0.3,
                end: 0,
                duration: 600.ms,
                curve: Curves.easeOutBack,
              ),
    );
  }

  Widget _buildRewardChip(
    BuildContext context,
    IconData icon,
    Color color,
    String text,
  ) {
    final theme = context.zipTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: theme.surfaceAlt,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.surfaceAlt),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: theme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Path _drawStar(Size size) {
    double degToRad(double deg) => deg * (pi / 180.0);
    const numberOfPoints = 5;
    final halfWidth = size.width / 2;
    final externalRadius = halfWidth;
    final internalRadius = halfWidth / 2.5;
    final degreesPerStep = degToRad(360 / numberOfPoints);
    final halfDegreesPerStep = degreesPerStep / 2;
    final path = Path();
    final fullAngle = degToRad(360);
    path.moveTo(
      halfWidth + externalRadius * cos(0 - pi / 2),
      halfWidth + externalRadius * sin(0 - pi / 2),
    );

    for (double step = 0; step < fullAngle; step += degreesPerStep) {
      path.lineTo(
        halfWidth + externalRadius * cos(step - pi / 2),
        halfWidth + externalRadius * sin(step - pi / 2),
      );
      path.lineTo(
        halfWidth + internalRadius * cos(step + halfDegreesPerStep - pi / 2),
        halfWidth + internalRadius * sin(step + halfDegreesPerStep - pi / 2),
      );
    }
    path.close();
    return path;
  }
}

extension SafeColor on Color {
  Color withSafeOpacity(double opacity) {
    return withOpacity(opacity.clamp(0.0, 1.0));
  }
}

