import 'package:flutter/material.dart';

enum AppThemeType { classic, neon, minimal, candy, space, dark, aurora }

const String kDefaultThemeId = 'theme_classic';

class AppThemeData {
  final AppThemeType type;
  final String id;
  final String name;
  final String description;
  final int price;
  final bool isPremium;

  final int boardBg;
  final int pathColorStart;
  final int pathColorEnd;
  final int nodeColor;
  final int scaffoldBg;
  final int surfaceColor;
  final int surfaceAltColor;
  final int textPrimaryColor;
  final int textSecondaryColor;
  final int mutedTextColor;
  final int accentColor;
  final int accentAltColor;
  final int successColor;
  final int warningColor;
  final int dangerColor;
  final int navActiveColor;
  final int glowColor;

  const AppThemeData({
    required this.type,
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.isPremium,
    required this.boardBg,
    required this.pathColorStart,
    required this.pathColorEnd,
    required this.nodeColor,
    required this.scaffoldBg,
    required this.surfaceColor,
    required this.surfaceAltColor,
    required this.textPrimaryColor,
    required this.textSecondaryColor,
    required this.mutedTextColor,
    required this.accentColor,
    required this.accentAltColor,
    required this.successColor,
    required this.warningColor,
    required this.dangerColor,
    required this.navActiveColor,
    required this.glowColor,
  });

  Color get boardBackground => Color(boardBg);
  Color get pathStart => Color(pathColorStart);
  Color get pathEnd => Color(pathColorEnd);
  Color get node => Color(nodeColor);
  Color get background => Color(scaffoldBg);
  Color get surface => Color(surfaceColor);
  Color get surfaceAlt => Color(surfaceAltColor);
  Color get textPrimary => Color(textPrimaryColor);
  Color get textSecondary => Color(textSecondaryColor);
  Color get mutedText => Color(mutedTextColor);
  Color get accent => Color(accentColor);
  Color get accentAlt => Color(accentAltColor);
  Color get success => Color(successColor);
  Color get warning => Color(warningColor);
  Color get danger => Color(dangerColor);
  Color get navActive => Color(navActiveColor);
  Color get glow => Color(glowColor);

  bool get isDark {
    final luminance = background.computeLuminance();
    return luminance < 0.45;
  }

  ZipThemeColors toThemeExtension() {
    return ZipThemeColors(
      id: id,
      background: background,
      surface: surface,
      surfaceAlt: surfaceAlt,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      mutedText: mutedText,
      accent: accent,
      accentAlt: accentAlt,
      success: success,
      warning: warning,
      danger: danger,
      navActive: navActive,
      boardBackground: boardBackground,
      node: node,
      pathStart: pathStart,
      pathEnd: pathEnd,
      glow: glow,
      shadow: Colors.black.withOpacity(isDark ? 0.24 : 0.07),
      scrim: Colors.black.withOpacity(isDark ? 0.62 : 0.35),
    );
  }

  ThemeData toThemeData(TextTheme textTheme) {
    final brightness = isDark ? Brightness.dark : Brightness.light;
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: accent,
          brightness: brightness,
        ).copyWith(
          primary: accent,
          secondary: accentAlt,
          surface: surface,
          onSurface: textPrimary,
          error: danger,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: background,
      cardColor: surface,
      primaryColor: accent,
      textTheme: textTheme.apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: surface,
        contentTextStyle: TextStyle(
          color: textPrimary,
          fontWeight: FontWeight.w800,
        ),
        behavior: SnackBarBehavior.floating,
      ),
      extensions: <ThemeExtension<dynamic>>[toThemeExtension()],
    );
  }
}

class ZipThemeColors extends ThemeExtension<ZipThemeColors> {
  final String id;
  final Color background;
  final Color surface;
  final Color surfaceAlt;
  final Color textPrimary;
  final Color textSecondary;
  final Color mutedText;
  final Color accent;
  final Color accentAlt;
  final Color success;
  final Color warning;
  final Color danger;
  final Color navActive;
  final Color boardBackground;
  final Color node;
  final Color pathStart;
  final Color pathEnd;
  final Color glow;
  final Color shadow;
  final Color scrim;

  const ZipThemeColors({
    required this.id,
    required this.background,
    required this.surface,
    required this.surfaceAlt,
    required this.textPrimary,
    required this.textSecondary,
    required this.mutedText,
    required this.accent,
    required this.accentAlt,
    required this.success,
    required this.warning,
    required this.danger,
    required this.navActive,
    required this.boardBackground,
    required this.node,
    required this.pathStart,
    required this.pathEnd,
    required this.glow,
    required this.shadow,
    required this.scrim,
  });

  bool get isDark => background.computeLuminance() < 0.45;
  bool get isBoardDark => boardBackground.computeLuminance() < 0.40;

  @override
  ZipThemeColors copyWith({
    String? id,
    Color? background,
    Color? surface,
    Color? surfaceAlt,
    Color? textPrimary,
    Color? textSecondary,
    Color? mutedText,
    Color? accent,
    Color? accentAlt,
    Color? success,
    Color? warning,
    Color? danger,
    Color? navActive,
    Color? boardBackground,
    Color? node,
    Color? pathStart,
    Color? pathEnd,
    Color? glow,
    Color? shadow,
    Color? scrim,
  }) {
    return ZipThemeColors(
      id: id ?? this.id,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      mutedText: mutedText ?? this.mutedText,
      accent: accent ?? this.accent,
      accentAlt: accentAlt ?? this.accentAlt,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      navActive: navActive ?? this.navActive,
      boardBackground: boardBackground ?? this.boardBackground,
      node: node ?? this.node,
      pathStart: pathStart ?? this.pathStart,
      pathEnd: pathEnd ?? this.pathEnd,
      glow: glow ?? this.glow,
      shadow: shadow ?? this.shadow,
      scrim: scrim ?? this.scrim,
    );
  }

  @override
  ZipThemeColors lerp(ThemeExtension<ZipThemeColors>? other, double t) {
    if (other is! ZipThemeColors) return this;
    return ZipThemeColors(
      id: t < 0.5 ? id : other.id,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      mutedText: Color.lerp(mutedText, other.mutedText, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentAlt: Color.lerp(accentAlt, other.accentAlt, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      navActive: Color.lerp(navActive, other.navActive, t)!,
      boardBackground: Color.lerp(boardBackground, other.boardBackground, t)!,
      node: Color.lerp(node, other.node, t)!,
      pathStart: Color.lerp(pathStart, other.pathStart, t)!,
      pathEnd: Color.lerp(pathEnd, other.pathEnd, t)!,
      glow: Color.lerp(glow, other.glow, t)!,
      shadow: Color.lerp(shadow, other.shadow, t)!,
      scrim: Color.lerp(scrim, other.scrim, t)!,
    );
  }
}

extension ZipThemeContext on BuildContext {
  ZipThemeColors get zipTheme {
    return Theme.of(this).extension<ZipThemeColors>() ??
        kAllThemes.first.toThemeExtension();
  }
}

const List<AppThemeData> kAllThemes = [
  AppThemeData(
    type: AppThemeType.classic,
    id: kDefaultThemeId,
    name: 'Classic',
    description: 'The original clean look',
    price: 0,
    isPremium: false,
    boardBg: 0xFFFFF0EC,
    pathColorStart: 0xFFFF9800,
    pathColorEnd: 0xFFF44336,
    nodeColor: 0xFF1E293B,
    scaffoldBg: 0xFFF8F9FA,
    surfaceColor: 0xFFFFFFFF,
    surfaceAltColor: 0xFFF1F5F9,
    textPrimaryColor: 0xFF1E293B,
    textSecondaryColor: 0xFF64748B,
    mutedTextColor: 0xFF94A3B8,
    accentColor: 0xFF8B5CF6,
    accentAltColor: 0xFF00B074,
    successColor: 0xFF00B074,
    warningColor: 0xFFFFC107,
    dangerColor: 0xFFF43F5E,
    navActiveColor: 0xFFFFD54F,
    glowColor: 0xFF8B5CF6,
  ),
  AppThemeData(
    type: AppThemeType.neon,
    id: 'theme_neon',
    name: 'Neon',
    description: 'Glow in the dark vibes',
    price: 500,
    isPremium: true,
    boardBg: 0xFF101827,
    pathColorStart: 0xFF00F5FF,
    pathColorEnd: 0xFFFF3DF2,
    nodeColor: 0xFFE0FEFF,
    scaffoldBg: 0xFF070A18,
    surfaceColor: 0xFF101827,
    surfaceAltColor: 0xFF17223A,
    textPrimaryColor: 0xFFF8FEFF,
    textSecondaryColor: 0xFFB9C7E8,
    mutedTextColor: 0xFF7C8AA8,
    accentColor: 0xFF00F5FF,
    accentAltColor: 0xFFFF3DF2,
    successColor: 0xFF2DFF9C,
    warningColor: 0xFFFFD166,
    dangerColor: 0xFFFF4D7D,
    navActiveColor: 0xFF00F5FF,
    glowColor: 0xFF00F5FF,
  ),
  AppThemeData(
    type: AppThemeType.minimal,
    id: 'theme_minimal',
    name: 'Minimal',
    description: 'Clean and distraction-free',
    price: 300,
    isPremium: true,
    boardBg: 0xFFF4F4F5,
    pathColorStart: 0xFF71717A,
    pathColorEnd: 0xFF27272A,
    nodeColor: 0xFF18181B,
    scaffoldBg: 0xFFFFFFFF,
    surfaceColor: 0xFFFFFFFF,
    surfaceAltColor: 0xFFF4F4F5,
    textPrimaryColor: 0xFF18181B,
    textSecondaryColor: 0xFF52525B,
    mutedTextColor: 0xFFA1A1AA,
    accentColor: 0xFF27272A,
    accentAltColor: 0xFF0EA5E9,
    successColor: 0xFF16A34A,
    warningColor: 0xFFEAB308,
    dangerColor: 0xFFE11D48,
    navActiveColor: 0xFFE4E4E7,
    glowColor: 0xFF71717A,
  ),
  AppThemeData(
    type: AppThemeType.candy,
    id: 'theme_candy',
    name: 'Candy',
    description: 'Sweet pastel colors',
    price: 400,
    isPremium: true,
    boardBg: 0xFFFFEEF8,
    pathColorStart: 0xFFFF6FAE,
    pathColorEnd: 0xFFB779FF,
    nodeColor: 0xFF8A1C54,
    scaffoldBg: 0xFFFFF7FB,
    surfaceColor: 0xFFFFFFFF,
    surfaceAltColor: 0xFFFFE4F2,
    textPrimaryColor: 0xFF43203A,
    textSecondaryColor: 0xFF80526D,
    mutedTextColor: 0xFFA97991,
    accentColor: 0xFFFF4E9B,
    accentAltColor: 0xFF8B5CF6,
    successColor: 0xFF10B981,
    warningColor: 0xFFFFB703,
    dangerColor: 0xFFF43F5E,
    navActiveColor: 0xFFFFD6EA,
    glowColor: 0xFFFF6FAE,
  ),
  AppThemeData(
    type: AppThemeType.space,
    id: 'theme_space',
    name: 'Space',
    description: 'Explore the cosmos',
    price: 600,
    isPremium: true,
    boardBg: 0xFF0B1535,
    pathColorStart: 0xFF60A5FA,
    pathColorEnd: 0xFFC084FC,
    nodeColor: 0xFFE2E8F0,
    scaffoldBg: 0xFF050816,
    surfaceColor: 0xFF111B35,
    surfaceAltColor: 0xFF182545,
    textPrimaryColor: 0xFFF8FAFC,
    textSecondaryColor: 0xFFB8C4DF,
    mutedTextColor: 0xFF7E8AA6,
    accentColor: 0xFF60A5FA,
    accentAltColor: 0xFFC084FC,
    successColor: 0xFF34D399,
    warningColor: 0xFFFBBF24,
    dangerColor: 0xFFFB7185,
    navActiveColor: 0xFF23345F,
    glowColor: 0xFF60A5FA,
  ),
  AppThemeData(
    type: AppThemeType.dark,
    id: 'theme_dark',
    name: 'Dark',
    description: 'Easy on the eyes',
    price: 350,
    isPremium: true,
    boardBg: 0xFF1B273A,
    pathColorStart: 0xFF22C55E,
    pathColorEnd: 0xFF14B8A6,
    nodeColor: 0xFFF8FAFC,
    scaffoldBg: 0xFF0F172A,
    surfaceColor: 0xFF1E293B,
    surfaceAltColor: 0xFF26354B,
    textPrimaryColor: 0xFFF8FAFC,
    textSecondaryColor: 0xFFCBD5E1,
    mutedTextColor: 0xFF94A3B8,
    accentColor: 0xFF22C55E,
    accentAltColor: 0xFF14B8A6,
    successColor: 0xFF22C55E,
    warningColor: 0xFFFFC107,
    dangerColor: 0xFFFB7185,
    navActiveColor: 0xFF2B4A3D,
    glowColor: 0xFF22C55E,
  ),
  AppThemeData(
    type: AppThemeType.aurora,
    id: 'theme_aurora',
    name: 'Aurora',
    description: 'Luminous polar-night colors',
    price: 750,
    isPremium: true,
    boardBg: 0xFF092D35,
    pathColorStart: 0xFF2DD4BF,
    pathColorEnd: 0xFFF472B6,
    nodeColor: 0xFFE6FFFB,
    scaffoldBg: 0xFF061B22,
    surfaceColor: 0xFF102E36,
    surfaceAltColor: 0xFF173D45,
    textPrimaryColor: 0xFFF1FFFC,
    textSecondaryColor: 0xFFBCE7E1,
    mutedTextColor: 0xFF82AAA6,
    accentColor: 0xFF2DD4BF,
    accentAltColor: 0xFFF472B6,
    successColor: 0xFF7DD3FC,
    warningColor: 0xFFFDE68A,
    dangerColor: 0xFFFB7185,
    navActiveColor: 0xFF1C4D55,
    glowColor: 0xFF2DD4BF,
  ),
];

AppThemeData themeById(String id) {
  return kAllThemes.firstWhere(
    (theme) => theme.id == normalizeThemeId(id),
    orElse: () => kAllThemes.first,
  );
}

String normalizeThemeId(String? id) {
  if (id == null || id.isEmpty || id == 'classic') return kDefaultThemeId;
  if (id.startsWith('theme_')) return id;
  return 'theme_$id';
}
