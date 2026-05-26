import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/app_theme.dart';
import '../services/player_progress_service.dart';
import 'mascot_widget.dart';
import 'bouncing_button.dart';

class VictoryFinaleOverlay extends StatelessWidget {
  final VoidCallback onBackToHome;

  const VictoryFinaleOverlay({
    super.key,
    required this.onBackToHome,
  });

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    final progress = Provider.of<PlayerProgressService>(context, listen: false);

    return Stack(
      children: [
        // Full screen subtle gradient backing
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.background.withValues(alpha: 0.95),
                theme.surfaceAlt.withValues(alpha: 0.95),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),

        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Cat Motion Overlay & Scripting
                const MascotWidget(
                  emotion: MascotEmotion.cheer,
                  size: 200,
                )
                    .animate(onPlay: (c) => c.repeat())
                    .moveY(
                      begin: -15,
                      end: 15,
                      duration: 800.ms,
                      curve: Curves.easeInOutSine,
                    )
                    .shimmer(
                      duration: 2.seconds,
                      color: theme.glow.withValues(alpha: 0.4),
                    ),

                const SizedBox(height: 40),

                // Dynamic Dialogue Canvas
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: theme.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: theme.accent.withValues(alpha: 0.3),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Campaign Complete!',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Thank you so much for playing, ${progress.playerName}!',
                        style: TextStyle(
                          color: theme.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'You have mastered every path. We are crafting brand-new puzzle challenges behind the scenes—stay tuned for upcoming games!',
                        style: TextStyle(
                          color: theme.textSecondary,
                          fontSize: 16,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      BouncingButton(
                        onPressed: onBackToHome,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: theme.accent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: const Center(
                            child: Text(
                              'Return to Home',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(duration: 800.ms)
                    .slideY(
                      begin: 0.3,
                      end: 0,
                      duration: 800.ms,
                      curve: Curves.easeOutBack,
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
