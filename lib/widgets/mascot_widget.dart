import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'dart:math';

import '../services/player_progress_service.dart';

enum MascotEmotion { idle, happy, sad, thinking, celebrate, wow, cheer }

class MascotSkinPalette {
  final String id;
  final Color bodyColor;
  final Color shadowColor;
  final Color legColor;
  final Color shoeColor;
  final Color eyeColor;
  final Color cheekColor;
  final Color mouthColor;
  final Color accentColor;
  final Color glowColor;

  const MascotSkinPalette({
    required this.id,
    required this.bodyColor,
    required this.shadowColor,
    required this.legColor,
    required this.shoeColor,
    required this.eyeColor,
    required this.cheekColor,
    required this.mouthColor,
    required this.accentColor,
    required this.glowColor,
  });
}

const List<MascotSkinPalette> kMascotSkins = [
  MascotSkinPalette(
    id: 'skin_default',
    bodyColor: Color(0xFFFFD54F),
    shadowColor: Color(0xFFE6A310),
    legColor: Color(0xFFE6A310),
    shoeColor: Color(0xFF6A1B9A),
    eyeColor: Color(0xFF1E293B),
    cheekColor: Color(0xFFFF8A65),
    mouthColor: Color(0xFFF43F5E),
    accentColor: Color(0xFF8B5CF6),
    glowColor: Color(0xFFFFD54F),
  ),
  MascotSkinPalette(
    id: 'skin_ninja',
    bodyColor: Color(0xFF334155),
    shadowColor: Color(0xFF111827),
    legColor: Color(0xFF1F2937),
    shoeColor: Color(0xFF0F172A),
    eyeColor: Color(0xFFF8FAFC),
    cheekColor: Color(0xFF94A3B8),
    mouthColor: Color(0xFFEF4444),
    accentColor: Color(0xFFF43F5E),
    glowColor: Color(0xFF64748B),
  ),
  MascotSkinPalette(
    id: 'skin_space',
    bodyColor: Color(0xFFBBD9FF),
    shadowColor: Color(0xFF5B7DB5),
    legColor: Color(0xFF7FA7D9),
    shoeColor: Color(0xFF8B5CF6),
    eyeColor: Color(0xFF0F172A),
    cheekColor: Color(0xFFFF80AB),
    mouthColor: Color(0xFF3B82F6),
    accentColor: Color(0xFF60A5FA),
    glowColor: Color(0xFF60A5FA),
  ),
  MascotSkinPalette(
    id: 'skin_royal',
    bodyColor: Color(0xFFFFC857),
    shadowColor: Color(0xFFD97706),
    legColor: Color(0xFFD97706),
    shoeColor: Color(0xFF6D28D9),
    eyeColor: Color(0xFF2E1065),
    cheekColor: Color(0xFFFF7A90),
    mouthColor: Color(0xFFBE123C),
    accentColor: Color(0xFFFFD700),
    glowColor: Color(0xFFFFD700),
  ),
  MascotSkinPalette(
    id: 'skin_cyber',
    bodyColor: Color(0xFF0F766E),
    shadowColor: Color(0xFF134E4A),
    legColor: Color(0xFF115E59),
    shoeColor: Color(0xFF111827),
    eyeColor: Color(0xFFECFEFF),
    cheekColor: Color(0xFF67E8F9),
    mouthColor: Color(0xFF22D3EE),
    accentColor: Color(0xFF00F5FF),
    glowColor: Color(0xFF00F5FF),
  ),
  MascotSkinPalette(
    id: 'skin_sleepy',
    bodyColor: Color(0xFFD8B4FE),
    shadowColor: Color(0xFFA855F7),
    legColor: Color(0xFFA855F7),
    shoeColor: Color(0xFF7E22CE),
    eyeColor: Color(0xFF3B0764),
    cheekColor: Color(0xFFF9A8D4),
    mouthColor: Color(0xFF9333EA),
    accentColor: Color(0xFFFDE68A),
    glowColor: Color(0xFFD8B4FE),
  ),
];

String normalizeMascotSkinId(String? id) {
  if (id == null || id.isEmpty || id == 'default') return 'skin_default';
  if (id.startsWith('skin_')) return id;
  return 'skin_$id';
}

MascotSkinPalette mascotSkinById(String? id) {
  final normalized = normalizeMascotSkinId(id);
  return kMascotSkins.firstWhere(
    (skin) => skin.id == normalized,
    orElse: () => kMascotSkins.first,
  );
}

class MascotWidget extends StatelessWidget {
  final MascotEmotion emotion;
  final double size;
  final String? skinId;

  const MascotWidget({
    Key? key,
    this.emotion = MascotEmotion.idle,
    this.size = 150.0,
    this.skinId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final activeSkinId =
        skinId ??
        context.select<PlayerProgressService, String>(
          (progress) => progress.equippedSkin,
        );
    final skin = mascotSkinById(activeSkinId);

    // Body proportions
    final double bodyWidth = size;
    final double bodyHeight = size * 0.7;
    final double earSize = size * 0.25;
    final double shoeSize = size * 0.2;

    final Color bodyColor = skin.bodyColor;
    final Color shadowColor = skin.shadowColor;
    final Color legColor = skin.legColor;
    final Color shoeColor = skin.shoeColor;
    final Color eyeColor = skin.eyeColor;
    final Color cheekColor = skin.cheekColor;

    // Core body stack
    Widget body = Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        // Left Ear
        Positioned(
          top: -earSize * 0.5,
          left: bodyWidth * 0.1,
          child: _buildEar(earSize, bodyColor, shadowColor, false),
        ),
        // Right Ear
        Positioned(
          top: -earSize * 0.5,
          right: bodyWidth * 0.1,
          child: _buildEar(earSize, bodyColor, shadowColor, true),
        ),

        // Main Body Shape (Soft Rectangle)
        Container(
          width: bodyWidth,
          height: bodyHeight,
          decoration: BoxDecoration(
            color: bodyColor,
            borderRadius: BorderRadius.circular(bodyHeight * 0.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
              // Inner bottom shadow for 3D feel
              BoxShadow(
                color: shadowColor.withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, -8),
                spreadRadius: -5,
              ),
            ],
          ),
        ),

        // Face Elements
        _buildFace(
          bodyWidth,
          bodyHeight,
          eyeColor,
          cheekColor,
          skin.mouthColor,
        ),

        // Left Leg/Shoe
        Positioned(
          bottom: -shoeSize * 0.8,
          left: bodyWidth * 0.2,
          child: _buildLeg(shoeSize, shoeColor, legColor),
        ),
        // Right Leg/Shoe
        Positioned(
          bottom: -shoeSize * 0.8,
          right: bodyWidth * 0.2,
          child: _buildLeg(shoeSize, shoeColor, legColor),
        ),

        ..._buildSkinAccessories(activeSkinId, bodyWidth, bodyHeight, skin),

        // Emotion Specific Overlays (Arms, Tears, Props)
        if (emotion == MascotEmotion.sad) ...[
          Positioned(
            bottom: bodyHeight * 0.2,
            left: bodyWidth * 0.3,
            child: const Icon(
              Icons.water_drop,
              color: Colors.lightBlueAccent,
              size: 16,
            ),
          ),
          Positioned(
            bottom: bodyHeight * 0.2,
            right: bodyWidth * 0.3,
            child: const Icon(
              Icons.water_drop,
              color: Colors.lightBlueAccent,
              size: 16,
            ),
          ),
        ],
        if (emotion == MascotEmotion.thinking) ...[
          Positioned(
                top: -bodyHeight * 0.4,
                right: -bodyWidth * 0.2,
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: skin.accentColor,
                  ),
                ),
              )
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .moveY(
                begin: 0,
                end: -10,
                duration: 1.seconds,
                curve: Curves.easeInOut,
              ),

          // Magnifying glass hand
          Positioned(
            bottom: bodyHeight * 0.1,
            right: -bodyWidth * 0.1,
            child: Icon(Icons.search_rounded, color: eyeColor, size: 48),
          ),
        ],
        if (emotion == MascotEmotion.cheer ||
            emotion == MascotEmotion.celebrate) ...[
          // Raised arms
          Positioned(
            top: -bodyHeight * 0.1,
            left: -bodyWidth * 0.1,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: 20,
                height: 40,
                decoration: BoxDecoration(
                  color: bodyColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
          Positioned(
            top: -bodyHeight * 0.1,
            right: -bodyWidth * 0.1,
            child: Transform.rotate(
              angle: 0.5,
              child: Container(
                width: 20,
                height: 40,
                decoration: BoxDecoration(
                  color: bodyColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ],
    );

    // Apply overall animations based on emotion
    Widget animatedBody = body;

    switch (emotion) {
      case MascotEmotion.idle:
        // Gentle float with subtle squash-stretch for a breathing feel.
        animatedBody = animatedBody
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: -6,
              end: 6,
              duration: 2400.ms,
              curve: Curves.easeInOutSine,
            )
            .scaleX(
              begin: 1.0,
              end: 1.04,
              duration: 2400.ms,
              curve: Curves.easeInOutSine,
            )
            .scaleY(
              begin: 1.02,
              end: 0.97,
              duration: 2400.ms,
              curve: Curves.easeInOutSine,
            );
        break;
      case MascotEmotion.happy:
        // Springy bounce — launches up with overshoot then settles.
        animatedBody = animatedBody
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -18,
              duration: 480.ms,
              curve: Curves.easeOutCubic,
            )
            .scaleY(
              begin: 1.0,
              end: 0.95,
              duration: 480.ms,
              curve: Curves.easeInOutSine,
            );
        break;
      case MascotEmotion.cheer:
        // Energetic side-to-side sway with upward bounce.
        animatedBody = animatedBody
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveY(
              begin: 0,
              end: -14,
              duration: 360.ms,
              curve: Curves.easeOutCubic,
            )
            .moveX(
              begin: -4,
              end: 4,
              duration: 360.ms,
              curve: Curves.easeInOutSine,
            );
        break;
      case MascotEmotion.sad:
        // Slow drooping fall, then a tiny defeated tilt.
        animatedBody = animatedBody
            .animate()
            .moveY(
              begin: -8,
              end: 12,
              duration: 900.ms,
              curve: Curves.bounceOut,
            )
            .then()
            .rotate(
              begin: -0.03,
              end: 0.03,
              duration: 2000.ms,
              curve: Curves.easeInOutSine,
            );
        break;
      case MascotEmotion.thinking:
        // Asymmetric head-tilt — leans one way then the other, like pondering.
        animatedBody = animatedBody
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .rotate(
              begin: -0.08,
              end: 0.05,
              duration: 1800.ms,
              curve: Curves.easeInOutSine,
            )
            .moveY(
              begin: 0,
              end: -4,
              duration: 1800.ms,
              curve: Curves.easeInOutSine,
            );
        break;
      case MascotEmotion.wow:
        // Fast heartbeat pulse: quick scale up+down twice per cycle.
        animatedBody = animatedBody
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.08, 1.08),
              duration: 220.ms,
              curve: Curves.easeOutCubic,
            )
            .then()
            .scale(
              begin: const Offset(1.08, 1.08),
              end: const Offset(1.0, 1.0),
              duration: 180.ms,
              curve: Curves.easeInCubic,
            );
        break;
      case MascotEmotion.celebrate:
        // Spin + rhythmic scale pulse — feels like a victory dance.
        animatedBody = animatedBody
            .animate(onPlay: (c) => c.repeat())
            .rotate(
              begin: 0,
              end: 2 * pi,
              duration: 1600.ms,
              curve: Curves.easeInOutCubic,
            )
            .scale(
              begin: const Offset(1.0, 1.0),
              end: const Offset(1.15, 1.15),
              duration: 800.ms,
              curve: Curves.easeInOutSine,
            )
            .then()
            .scale(
              begin: const Offset(1.15, 1.15),
              end: const Offset(1.0, 1.0),
              duration: 800.ms,
              curve: Curves.easeInOutSine,
            );
        break;
    }

    return SizedBox(
      width: size * 1.5,
      height: size * 1.5,
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutCubic,
              ),
              child: ScaleTransition(
                scale: Tween<double>(
                  begin: 0.80,
                  end: 1.0,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutBack,
                  ),
                ),
                child: child,
              ),
            );
          },
          child: DecoratedBox(
            key: ValueKey(activeSkinId),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: skin.glowColor.withValues(alpha: 0.22),
                  blurRadius: size * 0.18,
                  spreadRadius: size * 0.01,
                ),
              ],
            ),
            child: animatedBody,
          ),
        ),
      ),
    );
  }

  Widget _buildEar(double size, Color color, Color shadowColor, bool isRight) {
    return Transform.rotate(
      angle: isRight ? 0.2 : -0.2,
      child: ClipPath(
        clipper: TriangleClipper(),
        child: Container(width: size, height: size, color: color),
      ),
    );
  }

  Widget _buildLeg(double size, Color shoeColor, Color legColor) {
    return Column(
      children: [
        Container(width: size * 0.4, height: size * 0.8, color: legColor),
        Container(
          width: size,
          height: size * 0.6,
          decoration: BoxDecoration(
            color: shoeColor,
            borderRadius: BorderRadius.circular(size * 0.3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(width: 2, height: 4, color: Colors.white54),
                const SizedBox(width: 4),
                Container(width: 2, height: 4, color: Colors.white54),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildSkinAccessories(
    String activeSkinId,
    double bodyWidth,
    double bodyHeight,
    MascotSkinPalette skin,
  ) {
    switch (activeSkinId) {
      case 'skin_ninja':
        return [
          Positioned(
            top: bodyHeight * 0.23,
            child: Container(
              width: bodyWidth * 0.72,
              height: bodyHeight * 0.22,
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.55),
                borderRadius: BorderRadius.circular(bodyHeight * 0.08),
              ),
            ),
          ),
          Positioned(
            top: bodyHeight * 0.06,
            right: bodyWidth * 0.07,
            child: Icon(
              Icons.bolt_rounded,
              color: skin.accentColor,
              size: bodyWidth * 0.18,
            ),
          ),
        ];
      case 'skin_space':
        return [
          Positioned(
            top: -bodyHeight * 0.18,
            child: Container(
              width: bodyWidth * 1.15,
              height: bodyHeight * 1.15,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(bodyHeight * 0.35),
                border: Border.all(
                  color: Colors.white.withOpacity(0.45),
                  width: 3,
                ),
              ),
            ),
          ),
          Positioned(
            top: -bodyHeight * 0.24,
            child: Container(
              width: bodyWidth * 0.24,
              height: bodyWidth * 0.1,
              decoration: BoxDecoration(
                color: skin.accentColor,
                borderRadius: BorderRadius.circular(bodyWidth * 0.06),
              ),
            ),
          ),
        ];
      case 'skin_royal':
        return [
          Positioned(
            top: -bodyHeight * 0.46,
            child: Icon(
              Icons.workspace_premium_rounded,
              color: skin.accentColor,
              size: bodyWidth * 0.38,
            ),
          ),
        ];
      case 'skin_cyber':
        return [
          Positioned(
            top: bodyHeight * 0.08,
            left: bodyWidth * 0.08,
            child: _buildCircuitLine(bodyWidth * 0.26, skin.accentColor),
          ),
          Positioned(
            top: bodyHeight * 0.58,
            right: bodyWidth * 0.1,
            child: Transform.rotate(
              angle: pi,
              child: _buildCircuitLine(bodyWidth * 0.24, skin.accentColor),
            ),
          ),
        ];
      case 'skin_sleepy':
        return [
          Positioned(
            top: -bodyHeight * 0.34,
            right: bodyWidth * 0.06,
            child: Icon(
              Icons.bedtime_rounded,
              color: skin.accentColor,
              size: bodyWidth * 0.26,
            ),
          ),
          Positioned(
            top: -bodyHeight * 0.16,
            left: bodyWidth * 0.12,
            child: Transform.rotate(
              angle: -0.3,
              child: Container(
                width: bodyWidth * 0.34,
                height: bodyHeight * 0.16,
                decoration: BoxDecoration(
                  color: skin.accentColor,
                  borderRadius: BorderRadius.circular(bodyHeight * 0.08),
                ),
              ),
            ),
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _buildCircuitLine(double width, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: width,
          height: 3,
          decoration: BoxDecoration(
            color: color.withOpacity(0.9),
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ],
    );
  }

  Widget _buildFace(
    double w,
    double h,
    Color eyeColor,
    Color cheekColor,
    Color mouthColor,
  ) {
    // Face positions based on emotion
    double eyeSize = w * 0.12;
    Widget leftEye = _buildEye(eyeSize, eyeColor);
    Widget rightEye = _buildEye(eyeSize, eyeColor);
    Widget mouth = _buildMouth(w * 0.15, eyeColor);

    if (emotion == MascotEmotion.sad) {
      leftEye = _buildSadEye(eyeSize, eyeColor);
      rightEye = _buildSadEye(eyeSize, eyeColor);
      mouth = Transform.rotate(
        angle: pi,
        child: _buildMouth(w * 0.15, eyeColor),
      );
    } else if (emotion == MascotEmotion.wow) {
      mouth = Container(
        width: eyeSize * 1.5,
        height: eyeSize * 1.5,
        decoration: BoxDecoration(color: eyeColor, shape: BoxShape.circle),
      );
    } else if (emotion == MascotEmotion.happy ||
        emotion == MascotEmotion.cheer ||
        emotion == MascotEmotion.celebrate) {
      leftEye = _buildHappyEye(eyeSize, eyeColor);
      rightEye = _buildHappyEye(eyeSize, eyeColor);
      mouth = Container(
        width: w * 0.2,
        height: w * 0.15,
        decoration: BoxDecoration(
          color: mouthColor,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(20),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: eyeColor, width: 3),
        ),
      );
    } else if (emotion == MascotEmotion.thinking) {
      rightEye = Container(
        width: eyeSize,
        height: eyeSize * 0.3,
        color: eyeColor,
      ); // Squinting right eye
      mouth = Container(
        width: eyeSize * 1.5,
        height: 3,
        color: eyeColor,
      ); // Straight line mouth
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        // Left Eye
        Positioned(top: h * 0.3, left: w * 0.25, child: leftEye),
        // Right Eye
        Positioned(top: h * 0.3, right: w * 0.25, child: rightEye),
        // Left Cheek
        Positioned(
          top: h * 0.45,
          left: w * 0.15,
          child: _buildCheek(w * 0.15, cheekColor),
        ),
        // Right Cheek
        Positioned(
          top: h * 0.45,
          right: w * 0.15,
          child: _buildCheek(w * 0.15, cheekColor),
        ),
        // Mouth
        Positioned(top: h * 0.5, child: mouth),
      ],
    );
  }

  Widget _buildEye(double size, Color color) {
    return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: Stack(
            children: [
              Positioned(
                top: size * 0.2,
                right: size * 0.2,
                child: Container(
                  width: size * 0.3,
                  height: size * 0.3,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        )
        .animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scaleY(begin: 1.0, end: 0.1, duration: 100.ms, curve: Curves.easeInOut)
        .then(delay: 3.seconds); // Blinking logic
  }

  Widget _buildSadEye(double size, Color color) {
    return Transform.rotate(
      angle: 0.2,
      child: Container(
        width: size,
        height: size * 0.6,
        decoration: BoxDecoration(
          color: color,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
      ),
    );
  }

  Widget _buildHappyEye(double size, Color color) {
    return Container(
      width: size,
      height: size * 0.5,
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: color, width: size * 0.3),
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
    );
  }

  Widget _buildCheek(double size, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: -0.3,
          child: Container(width: 3, height: size * 0.4, color: color),
        ),
        const SizedBox(width: 2),
        Transform.rotate(
          angle: -0.3,
          child: Container(width: 3, height: size * 0.5, color: color),
        ),
        const SizedBox(width: 2),
        Transform.rotate(
          angle: -0.3,
          child: Container(width: 3, height: size * 0.4, color: color),
        ),
      ],
    );
  }

  Widget _buildMouth(double size, Color color) {
    return Container(
      width: size,
      height: size * 0.5,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: color, width: 3),
          left: BorderSide(color: color, width: 3),
          right: BorderSide(color: color, width: 3),
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
    );
  }
}

class TriangleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.moveTo(size.width / 2, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
