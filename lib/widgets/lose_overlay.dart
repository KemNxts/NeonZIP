import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import 'bouncing_button.dart';
import 'mascot_widget.dart';

class LoseOverlay extends StatelessWidget {
  final VoidCallback onRetry;
  final VoidCallback onBackToHome;
  final int moves;
  final int bestMoves;

  const LoseOverlay({
    Key? key,
    required this.onRetry,
    required this.onBackToHome,
    this.moves = 18,
    this.bestMoves = 23,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Stack(
      children: [
        // Themed gradient backdrop using glow color
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                theme.glow.withSafeOpacity(0.3),
                theme.glow.withSafeOpacity(0.6),
              ],
            ),
          ),
        ),

        // Main content
        SafeArea(
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Coin counter top
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '32.503',
                            style: TextStyle(
                              color: theme.textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: theme.warning,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.monetization_on,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 200.ms),

              const Spacer(),

              // Sad Mascot — drops in with a defeated bounce.
              const MascotWidget(
                emotion: MascotEmotion.sad,
                size: 160,
              ).animate()
                .scale(
                  delay: 200.ms,
                  duration: 700.ms,
                  begin: const Offset(0.0, 0.0),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.easeOutBack,
                )
                .fadeIn(delay: 200.ms, duration: 400.ms)
                .slideY(
                  delay: 200.ms,
                  begin: -0.3,
                  end: 0,
                  duration: 700.ms,
                  curve: Curves.easeOutCubic,
                ),

              // Danger X badge — slams down.
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.danger,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ).animate()
                .scale(
                  delay: 550.ms,
                  duration: 600.ms,
                  begin: const Offset(0, 0),
                  end: const Offset(1.0, 1.0),
                  curve: Curves.elasticOut,
                )
                .rotate(
                  delay: 550.ms,
                  begin: -0.2,
                  end: 0,
                  duration: 400.ms,
                  curve: Curves.easeOutCubic,
                ),

              const SizedBox(height: 24),

              Text(
                    'Oh no!',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 650.ms, duration: 300.ms)
                  .scale(
                    delay: 650.ms,
                    begin: const Offset(0.7, 0.7),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                    curve: Curves.easeOutBack,
                  ),

              const SizedBox(height: 8),
              Text(
                'Better luck next time.',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 800.ms),

              const SizedBox(height: 32),

              // Stats row
              Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 48),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 24,
                      ),
                      decoration: BoxDecoration(
                        color: theme.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: theme.shadow,
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildStatColumn(context, 'Moves', '$moves'),
                          Container(
                            width: 1,
                            height: 40,
                            color: theme.surfaceAlt,
                          ),
                          _buildStatColumn(context, 'Time', '01:25'),
                          Container(
                            width: 1,
                            height: 40,
                            color: theme.surfaceAlt,
                          ),
                          _buildStatColumn(context, 'Best', '$bestMoves'),
                        ],
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 900.ms, duration: 400.ms)
                  .slideY(begin: 0.3, end: 0, curve: Curves.easeOutCubic),

              const Spacer(),

              // Action buttons
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    BouncingButton(
                      onPressed: onRetry,
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'Try Again',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.white.withSafeOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ).animate().scale(
                      delay: 1000.ms,
                      duration: 500.ms,
                      curve: Curves.elasticOut,
                    ),

                    const SizedBox(height: 12),

                    BouncingButton(
                      onPressed: onBackToHome,
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
                    ).animate().fadeIn(delay: 1200.ms, duration: 400.ms),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    final theme = context.zipTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            color: theme.mutedText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: theme.textPrimary,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

extension SafeColor on Color {
  Color withSafeOpacity(double opacity) {
    return withOpacity(opacity.clamp(0.0, 1.0));
  }
}

