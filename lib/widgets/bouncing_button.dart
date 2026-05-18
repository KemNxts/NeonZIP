import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class BouncingButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Color glowColor;

  const BouncingButton({
    Key? key,
    required this.child,
    required this.onPressed,
    this.glowColor = Colors.cyanAccent,
  }) : super(key: key);

  @override
  State<BouncingButton> createState() => _BouncingButtonState();
}

class _BouncingButtonState extends State<BouncingButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      // Fast press-down, slower spring release.
      duration: const Duration(milliseconds: 120),
      reverseDuration: const Duration(milliseconds: 480),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _controller,
        // Sharp ease-in for the press (feels snappy & heavy).
        curve: Curves.easeInCubic,
        // Elastic spring for the release (feels tactile & satisfying).
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) {
    HapticFeedback.lightImpact();
    _controller.forward();
  }

  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onPressed();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          // Shadow lifts as button is pressed down, drops back on release.
          final double press = (1.0 - _scaleAnimation.value) / 0.12;
          final double shadowY = 6.0 - (press * 5.0);
          final double blur = 14.0 - (press * 12.0);
          final double spread = 1.0 - (press * 1.0);

          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: blur.clamp(0, 20),
                    spreadRadius: spread.clamp(0, 2),
                    offset: Offset(0, shadowY.clamp(0, 10)),
                  ),
                ],
              ),
              child: widget.child,
            ),
          );
        },
      ),
    );
  }
}
