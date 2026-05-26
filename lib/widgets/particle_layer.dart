import 'dart:math' as math;
import 'package:flutter/material.dart';

class Particle {
  double x, y;
  double vx, vy;
  double life;
  double maxLife;
  Color color;
  double size;

  Particle({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.life,
    required this.color,
    required this.size,
  }) : maxLife = life;
}

class ParticleLayer extends StatefulWidget {
  final Offset? dragOffset;
  final Color particleColor;

  const ParticleLayer({
    Key? key,
    required this.dragOffset,
    this.particleColor = Colors.white,
  }) : super(key: key);

  @override
  State<ParticleLayer> createState() => ParticleLayerState();
}

class ParticleLayerState extends State<ParticleLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<Particle> _particles = [];
  final math.Random _rnd = math.Random();
  Offset? _lastDragOffset;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(_updateParticles);
    _controller.repeat();
  }

  @override
  void didUpdateWidget(ParticleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.dragOffset != null) {
      _emitParticles(widget.dragOffset!);
    }
    _lastDragOffset = widget.dragOffset;
  }

  void _emitParticles(Offset pos) {
    // Generate 1-2 particles per update
    int count = _rnd.nextInt(2) + 1;
    for (int i = 0; i < count; i++) {
      double angle = _rnd.nextDouble() * math.pi * 2;
      double speed = _rnd.nextDouble() * 2 + 1; // 1 to 3 pixels per frame
      double life = _rnd.nextDouble() * 0.4 + 0.3; // 0.3s to 0.7s life

      _particles.add(Particle(
        x: pos.dx + (_rnd.nextDouble() * 10 - 5),
        y: pos.dy + (_rnd.nextDouble() * 10 - 5),
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        life: life,
        color: widget.particleColor,
        size: _rnd.nextDouble() * 3 + 2,
      ));
    }

    // Keep pool size manageable
    if (_particles.length > 150) {
      _particles.removeRange(0, _particles.length - 150);
    }
  }
  
  // Public method for external triggers (like the completion blast)
  void burst(Offset pos, int count, Color color, {double speedMultiplier = 1.0}) {
    for (int i = 0; i < count; i++) {
      double angle = _rnd.nextDouble() * math.pi * 2;
      double speed = (_rnd.nextDouble() * 4 + 2) * speedMultiplier;
      double life = _rnd.nextDouble() * 0.5 + 0.4;
      
      _particles.add(Particle(
        x: pos.dx,
        y: pos.dy,
        vx: math.cos(angle) * speed,
        vy: math.sin(angle) * speed,
        life: life,
        color: color,
        size: _rnd.nextDouble() * 4 + 2,
      ));
    }
  }

  void _updateParticles() {
    if (_particles.isEmpty) return;
    
    final double dt = 0.016; // Approx 60fps
    for (int i = _particles.length - 1; i >= 0; i--) {
      var p = _particles[i];
      p.life -= dt;
      if (p.life <= 0) {
        // Fast removal by swapping with last element instead of shifting array
        _particles[i] = _particles.last;
        _particles.removeLast();
        continue;
      }
      p.x += p.vx;
      p.y += p.vy;
      // Slight drag
      p.vx *= 0.95;
      p.vy *= 0.95;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _ParticlePainter(_particles),
        child: Container(),
      ),
    );
  }
}

class _ParticlePainter extends CustomPainter {
  final List<Particle> particles;

  _ParticlePainter(this.particles);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    for (final p in particles) {
      double progress = p.life / p.maxLife;
      // Simple easing for fade out
      int alpha = (255 * progress).clamp(0, 255).toInt();
      paint.color = p.color.withAlpha(alpha);
      
      // Draw as a glowing circle, or add a subtle blur
      // To keep it performant, we just draw a circle.
      canvas.drawCircle(Offset(p.x, p.y), p.size * progress, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) {
    return true; // We repaint every frame the ticker runs
  }
}
