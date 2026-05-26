import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/app_theme.dart';
import '../services/settings_service.dart';
import 'main_shell.dart';

class PathSelectionScreen extends StatefulWidget {
  const PathSelectionScreen({Key? key}) : super(key: key);

  @override
  State<PathSelectionScreen> createState() => _PathSelectionScreenState();
}

class _PathSelectionScreenState extends State<PathSelectionScreen> {
  PathStyle _selectedStyle = PathStyle.terminalDot; // Default selection

  void _confirmSelection() async {
    final settings = Provider.of<SettingsService>(context, listen: false);
    await settings.setPathStyle(_selectedStyle);
    await settings.setFirstRunCompleted();

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const MainShell(),
        transitionsBuilder: (_, anim, __, child) {
          final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(curved),
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
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose Your\nPath Style',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.2),
              
              const SizedBox(height: 16),
              
              Text(
                'You can change this later in Settings.',
                style: TextStyle(
                  color: theme.textSecondary,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              
              const Spacer(),
              
              Row(
                children: [
                  Expanded(
                    child: _buildStyleCard(
                      context: context,
                      title: 'Classic',
                      description: 'Smooth, continuous flow.',
                      style: PathStyle.classic,
                      theme: theme,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildStyleCard(
                      context: context,
                      title: 'Terminal Dot',
                      description: 'Clear endpoint indicator.',
                      style: PathStyle.terminalDot,
                      theme: theme,
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
              
              const Spacer(),
              
              GestureDetector(
                onTap: _confirmSelection,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [theme.accent, theme.accentAlt],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: theme.accent.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'Continue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.9, 0.9)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStyleCard({
    required BuildContext context,
    required String title,
    required String description,
    required PathStyle style,
    required ZipThemeColors theme,
  }) {
    final isSelected = _selectedStyle == style;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedStyle = style),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? theme.surfaceAlt : theme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? theme.accent : Colors.transparent,
            width: 3,
          ),
          boxShadow: [
            if (isSelected)
              BoxShadow(
                color: theme.accent.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              )
            else
              BoxShadow(
                color: theme.shadow,
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          children: [
            // Preview drawing
            SizedBox(
              height: 120,
              child: Center(
                child: CustomPaint(
                  size: const Size(80, 80),
                  painter: StylePreviewPainter(
                    theme: theme,
                    style: style,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: theme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              description,
              style: TextStyle(
                color: theme.textSecondary,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class StylePreviewPainter extends CustomPainter {
  final ZipThemeColors theme;
  final PathStyle style;

  StylePreviewPainter({required this.theme, required this.style});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    path.moveTo(0, size.height * 0.2);
    path.lineTo(size.width * 0.8, size.height * 0.2);
    path.quadraticBezierTo(size.width, size.height * 0.2, size.width, size.height * 0.4);
    path.lineTo(size.width, size.height * 0.6);
    path.quadraticBezierTo(size.width, size.height * 0.8, size.width * 0.8, size.height * 0.8);
    path.lineTo(size.width * 0.4, size.height * 0.8);

    final strokeWidth = 16.0;

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [theme.pathStart, theme.pathEnd],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    canvas.drawPath(path, paint);

    // Inner highlight
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..strokeWidth = strokeWidth * 0.25
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke,
    );

    if (style == PathStyle.terminalDot) {
      final tip = Offset(size.width * 0.4, size.height * 0.8);
      final dotR = strokeWidth * 0.45;

      // Glow
      canvas.drawCircle(
        tip,
        dotR * 1.35,
        Paint()
          ..color = theme.pathEnd.withOpacity(0.25)
          ..style = PaintingStyle.fill,
      );

      // Solid
      canvas.drawCircle(tip, dotR, Paint()..color = theme.pathEnd);

      // White core
      canvas.drawCircle(
        tip,
        dotR * 0.45,
        Paint()..color = Colors.white.withOpacity(0.85),
      );
    }
  }

  @override
  bool shouldRepaint(covariant StylePreviewPainter oldDelegate) {
    return oldDelegate.style != style || oldDelegate.theme.id != theme.id;
  }
}
