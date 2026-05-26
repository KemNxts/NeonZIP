import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';

class AmbientBackground extends StatefulWidget {
  final Widget child;

  const AmbientBackground({Key? key, required this.child}) : super(key: key);

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground> {
  Offset _pointer = Offset.zero;

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return MouseRegion(
      onHover: (e) => _updatePointer(e.position, MediaQuery.of(context).size),
      child: GestureDetector(
        onPanUpdate: (e) => _updatePointer(e.globalPosition, MediaQuery.of(context).size),
        child: TweenAnimationBuilder<Offset>(
          tween: Tween<Offset>(begin: Offset.zero, end: _pointer),
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          builder: (context, pointerOffset, child) {
            return Stack(
              children: [
                // Base light background
                AnimatedContainer(
                  duration: const Duration(milliseconds: 520),
                  curve: Curves.easeInOutCubic,
                  color: theme.background,
                ),

                // Soft animated gradient blobs for the playful theme
                Positioned(
                  top: -100 + (pointerOffset.dy * 20),
                  left: -50 + (pointerOffset.dx * 20),
                  child: _buildBlob(theme.glow.withOpacity(0.07), 400)
                      .animate(onPlay: (controller) => controller.repeat())
                      .moveX(
                        begin: 0,
                        end: 100,
                        duration: 15.seconds,
                        curve: Curves.easeInOutSine,
                      )
                      .moveY(
                        begin: 0,
                        end: 50,
                        duration: 12.seconds,
                        curve: Curves.easeInOutSine,
                      )
                      .then()
                      .moveX(
                        begin: 100,
                        end: 0,
                        duration: 15.seconds,
                        curve: Curves.easeInOutSine,
                      )
                      .moveY(
                        begin: 50,
                        end: 0,
                        duration: 12.seconds,
                        curve: Curves.easeInOutSine,
                      ),
                ),
                Positioned(
                  bottom: -50 - (pointerOffset.dy * 20),
                  right: -100 - (pointerOffset.dx * 20),
                  child: _buildBlob(theme.accentAlt.withOpacity(0.06), 500)
                      .animate(onPlay: (controller) => controller.repeat())
                      .moveX(
                        begin: 0,
                        end: -100,
                        duration: 18.seconds,
                        curve: Curves.easeInOutSine,
                      )
                      .moveY(
                        begin: 0,
                        end: -80,
                        duration: 14.seconds,
                        curve: Curves.easeInOutSine,
                      )
                      .then()
                      .moveX(
                        begin: -100,
                        end: 0,
                        duration: 18.seconds,
                        curve: Curves.easeInOutSine,
                      )
                      .moveY(
                        begin: -80,
                        end: 0,
                        duration: 14.seconds,
                        curve: Curves.easeInOutSine,
                      ),
                ),

                // Floating premium particles
                ...List.generate(12, (index) {
                  final random = Random(index);
                  final size = random.nextDouble() * 15 + 5; // Larger soft particles
                  final startX = random.nextDouble() * 400;
                  final startY = random.nextDouble() * 800;
                  final durationMs = 8000 + random.nextInt(12000); // Slower movement

                  final isCross = random.nextBool();
                  
                  // Vary depth multiplier per particle
                  final depth = random.nextDouble() * 30 + 10;

                  return Positioned(
                    left: startX + (pointerOffset.dx * depth),
                    top: startY + (pointerOffset.dy * depth),
                    child: isCross
                        ? _buildCrossParticle(size, theme.accent)
                        : _buildCircleParticle(size, theme.success)
                              .animate(
                                onPlay: (controller) =>
                                    controller.repeat(reverse: true),
                              )
                              .moveY(
                                begin: 0,
                                end: -50 - random.nextDouble() * 100,
                                duration: durationMs.ms,
                                curve: Curves.easeInOutSine,
                              )
                              .rotate(
                                begin: 0,
                                end: random.nextBool() ? 0.2 : -0.2,
                                duration: durationMs.ms,
                                curve: Curves.linear,
                              )
                              .fadeIn(duration: (durationMs ~/ 3).ms)
                              .then(delay: (durationMs ~/ 3).ms)
                              .fadeOut(duration: (durationMs ~/ 3).ms),
                  );
                }),

                // Main content
                SafeArea(child: widget.child),
              ],
            );
          }
        ),
      ),
    );
  }

  void _updatePointer(Offset globalPosition, Size size) {
    setState(() {
      _pointer = Offset(
        (globalPosition.dx / size.width - 0.5) * 2,
        (globalPosition.dy / size.height - 0.5) * 2,
      );
    });
  }

  Widget _buildBlob(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    ).animate().blurXY(begin: 100, end: 100); // Massive blur for soft gradients
  }

  Widget _buildCircleParticle(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildCrossParticle(double size, Color color) {
    // Simple 4-point star/cross
    return Icon(
      Icons.close_rounded,
      size: size * 1.5,
      color: color.withOpacity(0.1),
    );
  }
}
