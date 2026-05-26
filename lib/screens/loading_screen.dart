import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:async';

import '../models/app_theme.dart';
import 'main_shell.dart';
import '../widgets/mascot_widget.dart';
import '../services/settings_service.dart';
import 'package:provider/provider.dart';
import 'path_selection_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({Key? key}) : super(key: key);

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    // Simulate loading progress
    Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _progress += 0.02;
        if (_progress >= 1.0) {
          _progress = 1.0;
          timer.cancel();
          _transitionToMenu();
        }
      });
    });
  }

  void _transitionToMenu() {
    final settings = Provider.of<SettingsService>(context, listen: false);
    final targetScreen = settings.firstRunCompleted 
        ? const MainShell() 
        : const PathSelectionScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 700),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.zipTheme;
    return Scaffold(
      backgroundColor: theme.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 48.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Logo
              Text(
                    'ZIP',
                    style: TextStyle(
                      color: theme.accent,
                      fontSize: 56,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic),

              Text(
                    'PUZZLE',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  )
                  .animate()
                  .fadeIn(delay: 200.ms, duration: 600.ms)
                  .slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic),

              const SizedBox(height: 12),
              Text(
                'Unzip the path,\nconnect all the dots!',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const Spacer(),

              // Mascot & Trail
              Center(
                child: SizedBox(
                  width: double.infinity,
                  height: 300,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // Animated Path Trails
                      Positioned(
                        top: 50,
                        left: -50,
                        right: -50,
                        child:
                            CustomPaint(
                                  size: const Size(double.infinity, 200),
                                  painter: TrailPainter(
                                    colorA: theme.accent,
                                    colorB: theme.accentAlt,
                                  ),
                                )
                                .animate(
                                  onPlay: (controller) =>
                                      controller.repeat(reverse: true),
                                )
                                .moveY(
                                  begin: -10,
                                  end: 10,
                                  duration: 3.seconds,
                                  curve: Curves.easeInOutSine,
                                ),
                      ),

                      // Mascot
                      // Mascot — springs in with a satisfying drop.
                      MascotWidget(
                        emotion: MascotEmotion.happy,
                        size: 140,
                      ).animate()
                        .scale(
                          delay: 500.ms,
                          duration: 900.ms,
                          begin: const Offset(0.2, 0.2),
                          end: const Offset(1.0, 1.0),
                          curve: Curves.elasticOut,
                        )
                        .slideY(
                          delay: 500.ms,
                          begin: -0.2,
                          end: 0,
                          duration: 700.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeIn(delay: 500.ms, duration: 300.ms),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(_progress * 100).toInt()}%',
                    style: TextStyle(
                      color: theme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: theme.surfaceAlt,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.accent,
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: [
                            BoxShadow(
                              color: theme.accent.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 800.ms, duration: 500.ms),
            ],
          ),
        ),
      ),
    );
  }
}

class TrailPainter extends CustomPainter {
  final Color colorA;
  final Color colorB;

  const TrailPainter({required this.colorA, required this.colorB});

  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = colorA.withOpacity(0.2)
      ..strokeWidth = 24
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paint2 = Paint()
      ..color = colorB.withOpacity(0.2)
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path1 = Path();
    path1.moveTo(0, size.height * 0.8);
    path1.quadraticBezierTo(
      size.width * 0.25,
      size.height * 1.2,
      size.width * 0.5,
      size.height * 0.5,
    );
    path1.quadraticBezierTo(
      size.width * 0.75,
      -size.height * 0.2,
      size.width,
      size.height * 0.2,
    );

    final path2 = Path();
    path2.moveTo(0, size.height * 0.4);
    path2.quadraticBezierTo(
      size.width * 0.3,
      -size.height * 0.1,
      size.width * 0.6,
      size.height * 0.6,
    );
    path2.quadraticBezierTo(
      size.width * 0.8,
      size.height,
      size.width,
      size.height * 0.8,
    );

    canvas.drawPath(path1, paint1);
    canvas.drawPath(path2, paint2);

    // Draw dots
    final dotPaintOrange = Paint()
      ..color = colorB
      ..style = PaintingStyle.fill;
    final dotPaintPurple = Paint()
      ..color = colorA
      ..style = PaintingStyle.fill;

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.9),
      8,
      dotPaintOrange,
    );
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.1),
      12,
      dotPaintPurple,
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.7),
      6,
      dotPaintOrange,
    );
  }

  @override
  bool shouldRepaint(covariant TrailPainter oldDelegate) {
    return oldDelegate.colorA != colorA || oldDelegate.colorB != colorB;
  }
}
