import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'models/app_theme.dart';
import 'screens/loading_screen.dart';
import 'services/game_state_manager.dart';
import 'services/level_manager.dart';
import 'services/player_progress_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final levelManager = LevelManager();
  final gameStateManager = GameStateManager(levelManager);
  final playerProgress = PlayerProgressService();

  await gameStateManager.init();
  await playerProgress.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: gameStateManager),
        ChangeNotifierProvider.value(value: playerProgress),
      ],
      child: const NeonZipApp(),
    ),
  );
}

class NeonZipApp extends StatelessWidget {
  const NeonZipApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProgressService>(
      builder: (context, progress, _) {
        final appTheme = progress.activeTheme;
        final baseTextTheme = appTheme.isDark
            ? ThemeData.dark().textTheme
            : ThemeData.light().textTheme;

        return MaterialApp(
          title: 'NeonZIP',
          debugShowCheckedModeBanner: false,
          theme: appTheme.toThemeData(
            GoogleFonts.outfitTextTheme(baseTextTheme),
          ),
          themeAnimationDuration: const Duration(milliseconds: 520),
          themeAnimationCurve: Curves.easeInOutCubic,
          builder: (context, child) => _ThemeTransitionShell(
            themeId: appTheme.id,
            glowColor: appTheme.glow,
            child: child ?? const SizedBox.shrink(),
          ),
          home: const LoadingScreen(),
        );
      },
    );
  }
}

class _ThemeTransitionShell extends StatefulWidget {
  final String themeId;
  final Color glowColor;
  final Widget child;

  const _ThemeTransitionShell({
    required this.themeId,
    required this.glowColor,
    required this.child,
  });

  @override
  State<_ThemeTransitionShell> createState() => _ThemeTransitionShellState();
}

class _ThemeTransitionShellState extends State<_ThemeTransitionShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..value = 1;
  }

  @override
  void didUpdateWidget(covariant _ThemeTransitionShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.themeId != widget.themeId) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        IgnorePointer(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final opacity =
                  (1 - Curves.easeOutCubic.transform(_controller.value)) * 0.24;
              return Opacity(
                opacity: opacity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topCenter,
                      radius: 1.15,
                      colors: [
                        widget.glowColor.withOpacity(0.55),
                        widget.glowColor.withOpacity(0.12),
                        Colors.transparent,
                      ],
                      stops: const [0, 0.42, 1],
                    ),
                  ),
                  child: const SizedBox.expand(),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
