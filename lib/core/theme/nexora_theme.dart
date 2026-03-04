// lib/theme/nexora_theme.dart

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// =====================================================
/// NEXORA OFFICIAL DARK THEME
/// Inspired by Logo: Midnight + Neon Purple + Pink + Cyan
/// Tagline: "WHERE CAMPUS HEARTS CONNECT"
/// =====================================================

class NexoraColors {
  // ---------------- BACKGROUND GRADIENTS ----------------
  static const Color midnightDark = Color(0xFF000000); // Pure Black
  static const Color midnightPurple = Color(
    0xFF080812,
  ); // Extremely Deep Purple
  static const Color midnightBlue = Color(0xFF0A0A1A); // Extremely Deep Blue

  // ---------------- PRIMARY BRAND COLORS ----------------
  static const Color primaryOrange = Color(0xFFFF8C00); // Main NEXORA orange
  static const Color brightOrange = Color(0xFFFFA500); // Bright neon orange
  static const Color deepOrange = Color(0xFFE65100); // Deep royal orange
  // ---------------- BRAND ACCENT COLORS ----------------
  static const Color flameRed = Color(0xFFFF4500); // Flame red for highlight
  static const Color peachOrange = Color(
    0xFFFFCC80,
  ); // Peach orange for soft accent
  static const Color loveRed = Color(0xFFFF2400); // Scarlet red
  static const Color accentAmber = Color(0xFFFFBF00); // Bright amber accent
  static const Color softAmber = Color(0xFFFFD700); // Gold amber
  static const Color deepAmber = Color(0xFFCC7722); // Ocher amber

  // --- BACKWARD COMPATIBILITY ALIASES (now all orange/amber) ---
  static const Color primaryPurple = Color(0xFFFF8C00); // → primaryOrange
  static const Color romanticPink = Color(0xFFFF4500); // → flameRed
  static const Color softPink = Color(0xFFFFCC80); // → peachOrange
  static const Color accentCyan = Color(0xFFFFBF00); // → accentAmber
  static const Color softCyan = Color(0xFFFFD700); // → softAmber
  static const Color deepCyan = Color(0xFFCC7722); // → deepAmber
  static const Color brightPurple = Color(0xFFFFA500); // → brightOrange
  static const Color deepPurple = Color(0xFFE65100); // → deepOrange

  // ---------------- TEXT COLORS ----------------
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFE0E0E0); // Light gray
  static const Color textMuted = Color(0xFF9E9E9E); // Medium gray
  static const Color textDark = Color(0xFF666666); // Dark gray

  // ---------------- CARD/CONTAINER COLORS (Solid UI) ----------------
  static const Color cardBackground = Color(0xFF121212); // Neutral dark gray
  static const Color cardBorder = Color(0xFF2A2A2A); // Distinct border
  static const Color cardSurface = Color(0xFF1E1E1E); // Elevated surface

  // ---------------- GLASS EFFECT COLORS (Legacy - mapped to solid) ----------------
  static Color glassBackground = const Color(0xFF121212); // Now solid
  static Color glassBorder = const Color(0xFF2A2A2A); // Now solid
  static Color glassHighlight = const Color(0xFF1E1E1E); // Now solid

  // ---------------- STATUS COLORS ----------------
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color online = Color(0xFF4CAF50);
  static const Color offline = Color(0xFF9E9E9E);
}

/// =====================================================
/// GRADIENTS
/// =====================================================

class NexoraGradients {
  // Main background gradient (from logo)
  static const LinearGradient mainBackground = LinearGradient(
    colors: [
      NexoraColors.midnightDark,
      Color(0xFF1A0F00), // Midnight Orange
      NexoraColors.midnightDark,
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Orange glow gradient
  static LinearGradient purpleGlow = LinearGradient(
    colors: [NexoraColors.primaryOrange.withOpacity(0.3), Colors.transparent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Primary button gradient (Orange/Black style)
  static const LinearGradient primaryButton = LinearGradient(
    colors: [NexoraColors.primaryOrange, NexoraColors.midnightDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Orange glow for match screen
  static const LinearGradient romanticGlow = LinearGradient(
    colors: [NexoraColors.flameRed, NexoraColors.primaryOrange],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Amber accent gradient
  static const LinearGradient cyanAccent = LinearGradient(
    colors: [NexoraColors.accentAmber, NexoraColors.softAmber],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Flame pulse gradient
  static const LinearGradient heartPulse = LinearGradient(
    colors: [NexoraColors.flameRed, NexoraColors.loveRed],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Surface overlay gradient (solid)
  static const LinearGradient surfaceOverlay = LinearGradient(
    colors: [Color(0xFF252538), Color(0xFF1E1E2E), Color(0xFF14142B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Legacy glass overlay - mapped to solid
  static LinearGradient glassOverlay = surfaceOverlay;

  // NEXORA logo gradient
  static const LinearGradient logoGradient = LinearGradient(
    colors: [
      NexoraColors.primaryOrange,
      NexoraColors.flameRed,
      NexoraColors.accentAmber,
    ],
    stops: [0.3, 0.6, 1.0],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Glassy button/filter gradient
  static const LinearGradient glassyGradient = LinearGradient(
    colors: [NexoraColors.primaryOrange, NexoraColors.midnightDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// =====================================================
/// SHADOWS & GLOW EFFECTS
/// =====================================================

class NexoraShadows {
  // Orange glow for active elements
  static BoxShadow purpleGlow = BoxShadow(
    color: NexoraColors.primaryOrange.withOpacity(0.3),
    blurRadius: 20,
    spreadRadius: 0,
    offset: const Offset(0, 4),
  );

  // Intense orange glow for highlights
  static BoxShadow intensePurpleGlow = BoxShadow(
    color: NexoraColors.primaryOrange.withOpacity(0.6),
    blurRadius: 30,
    spreadRadius: 5,
  );

  // Flame glow for romantic elements
  static BoxShadow pinkGlow = BoxShadow(
    color: NexoraColors.flameRed.withOpacity(0.4),
    blurRadius: 25,
    spreadRadius: 2,
  );

  // Amber glow for accents
  static BoxShadow cyanGlow = BoxShadow(
    color: NexoraColors.accentAmber.withOpacity(0.3),
    blurRadius: 20,
    spreadRadius: 2,
  );

  // Card shadow
  static BoxShadow cardShadow = BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 10,
    spreadRadius: 0,
    offset: const Offset(0, 4),
  );

  // Bottom navigation shadow
  static BoxShadow bottomNavShadow = BoxShadow(
    color: Colors.black.withOpacity(0.5),
    blurRadius: 20,
    spreadRadius: 0,
    offset: const Offset(0, -4),
  );

  // Text glow for special titles
  static Shadow textGlow = Shadow(
    color: NexoraColors.primaryPurple.withOpacity(0.5),
    blurRadius: 10,
  );
}

/// =====================================================
/// TEXT STYLES
/// =====================================================

class NexoraTextStyles {
  // NEXORA Logo style (non-const due to Paint gradient)
  static TextStyle get logoStyle => TextStyle(
    fontSize: 32.sp,
    fontWeight: FontWeight.bold,
    letterSpacing: 2.w,
    color: NexoraColors.primaryPurple,
  );

  // Tagline style
  static TextStyle get taglineStyle => TextStyle(
    fontSize: 10.sp,
    letterSpacing: 1.5.w,
    color: NexoraColors.textSecondary,
  );

  // Headline styles
  static TextStyle get headline1 => TextStyle(
    fontSize: 32.sp,
    fontWeight: FontWeight.bold,
    color: NexoraColors.textPrimary,
  );

  static TextStyle get headline2 => TextStyle(
    fontSize: 28.sp,
    fontWeight: FontWeight.bold,
    color: NexoraColors.textPrimary,
  );

  static TextStyle get headline3 => TextStyle(
    fontSize: 24.sp,
    fontWeight: FontWeight.w600,
    color: NexoraColors.textPrimary,
  );

  // Body text styles
  static TextStyle get bodyLarge =>
      TextStyle(fontSize: 16.sp, color: NexoraColors.textPrimary);

  static TextStyle get bodyMedium =>
      TextStyle(fontSize: 14.sp, color: NexoraColors.textSecondary);

  static TextStyle get bodySmall =>
      TextStyle(fontSize: 12.sp, color: NexoraColors.textMuted);

  // Special styles
  static TextStyle get romanticText => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: NexoraColors.primaryOrange,
  );

  static TextStyle get glowingText => TextStyle(
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    color: NexoraColors.textPrimary,
    shadows: [
      Shadow(
        color: NexoraColors.primaryOrange.withOpacity(0.5),
        blurRadius: 10.r,
      ),
    ],
  );
}

/// =====================================================
/// RESPONSIVE SPACING
/// =====================================================

class NexoraSpacing {
  static double get xs => 4.w;
  static double get sm => 8.w;
  static double get md => 16.w;
  static double get lg => 24.w;
  static double get xl => 32.w;
  static double get xxl => 48.w;

  static EdgeInsets get screenPadding => EdgeInsets.all(20.w);
  static EdgeInsets get cardPadding => EdgeInsets.all(16.w);
  static EdgeInsets get buttonPadding =>
      EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h);
}

/// =====================================================
/// RESPONSIVE SIZES
/// =====================================================

class NexoraSizes {
  static double get iconSm => 16.r;
  static double get iconMd => 24.r;
  static double get iconLg => 32.r;

  static double get avatarSm => 40.r;
  static double get avatarMd => 60.r;
  static double get avatarLg => 80.r;

  static double get borderRadiusSm => 8.r;
  static double get borderRadiusMd => 16.r;
  static double get borderRadiusLg => 24.r;

  static double get buttonHeight => 48.h;
}

/// =====================================================
/// ANIMATIONS & DURATIONS
/// =====================================================

class NexoraAnimations {
  static const Duration quick = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration pageTransition = Duration(milliseconds: 400);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve bounceCurve = Curves.elasticOut;
  static const Curve smoothCurve = Curves.easeOutCubic;
}

/// =====================================================
/// SMOOTH PAGE ROUTE
/// =====================================================

class NexoraPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  NexoraPageRoute({required this.page})
    : super(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: NexoraAnimations.pageTransition,
        reverseTransitionDuration: NexoraAnimations.normal,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );

          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1.0, 0.0),
              end: Offset.zero,
            ).animate(curvedAnimation),
            child: FadeTransition(
              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
                ),
              ),
              child: child,
            ),
          );
        },
      );
}

/// =====================================================
/// DECORATIONS
/// =====================================================

class NexoraDecorations {
  // Glass container decoration
  static BoxDecoration glassDecoration({
    double borderRadius = 24,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: NexoraColors.glassBackground,
      borderRadius: BorderRadius.circular(borderRadius.r),
      border: Border.all(
        color: borderColor ?? NexoraColors.glassBorder,
        width: 1.w,
      ),
    );
  }

  // Gradient card decoration
  static BoxDecoration gradientCard({
    double borderRadius = 24,
    required Gradient gradient,
  }) {
    return BoxDecoration(
      gradient: gradient,
      borderRadius: BorderRadius.circular(borderRadius.r),
      boxShadow: [NexoraShadows.cardShadow],
    );
  }

  // Avatar decoration
  static BoxDecoration avatarDecoration({
    double size = 50,
    Gradient? gradient,
  }) {
    return BoxDecoration(
      gradient: gradient ?? NexoraGradients.primaryButton,
      borderRadius: BorderRadius.circular(size * 0.3.r),
      boxShadow: [NexoraShadows.purpleGlow],
    );
  }

  // Heart pulse decoration
  static BoxDecoration heartPulseDecoration = BoxDecoration(
    gradient: NexoraGradients.heartPulse,
    shape: BoxShape.circle,
    boxShadow: [NexoraShadows.pinkGlow],
  );
}

/// =====================================================
/// MAIN THEME CONFIG
/// =====================================================

class NexoraTheme {
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: NexoraColors.midnightDark,
    useMaterial3: true,

    // Color Scheme
    colorScheme: const ColorScheme.dark(
      primary: NexoraColors.primaryOrange,
      secondary: NexoraColors.flameRed,
      tertiary: NexoraColors.accentAmber,
      surface: Color(0xFF121212),
      error: NexoraColors.error,
      onPrimary: NexoraColors.textPrimary,
      onSecondary: NexoraColors.textPrimary,
      onSurface: NexoraColors.textPrimary,
    ),

    // Text Theme
    textTheme: TextTheme(
      displayLarge: NexoraTextStyles.headline1,
      displayMedium: NexoraTextStyles.headline2,
      displaySmall: NexoraTextStyles.headline3,
      bodyLarge: NexoraTextStyles.bodyLarge,
      bodyMedium: NexoraTextStyles.bodyMedium,
      bodySmall: NexoraTextStyles.bodySmall,
    ).apply(fontFamily: 'Poppins'),

    // App Bar Theme
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      iconTheme: const IconThemeData(color: NexoraColors.textPrimary),
      titleTextStyle: NexoraTextStyles.headline3,
    ),

    // Bottom Navigation Bar Theme
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: NexoraColors.primaryPurple,
      unselectedItemColor: NexoraColors.textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),

    // Elevated Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style:
          ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: NexoraColors.textPrimary,
            padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24.r),
            ),
            shadowColor: Colors.transparent,
          ).copyWith(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return NexoraColors.textMuted;
              }
              return Colors.transparent;
            }),
            elevation: WidgetStateProperty.all(0),
          ),
    ),

    // Text Button Theme
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: NexoraColors.primaryPurple,
        textStyle: const TextStyle(fontWeight: FontWeight.w600),
      ),
    ),

    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: NexoraColors.glassBackground,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: NexoraColors.primaryOrange, width: 1.w),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: NexoraColors.error, width: 1.w),
      ),
      hintStyle: const TextStyle(color: NexoraColors.textMuted),
      labelStyle: const TextStyle(color: NexoraColors.textSecondary),
    ),

    // Card Theme
    cardTheme: CardThemeData(
      color: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
    ),

    // Dialog Theme
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
    ),

    // Snackbar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: NexoraColors.midnightPurple,
      contentTextStyle: const TextStyle(color: NexoraColors.textPrimary),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      behavior: SnackBarBehavior.floating,
    ),

    // Tab Bar Theme
    tabBarTheme: TabBarThemeData(
      labelColor: NexoraColors.textPrimary,
      unselectedLabelColor: NexoraColors.textMuted,
      indicator: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        gradient: NexoraGradients.primaryButton,
      ),
      indicatorSize: TabBarIndicatorSize.tab,
    ),

    // Floating Action Button Theme
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: NexoraColors.primaryOrange,
      foregroundColor: NexoraColors.textPrimary,
      elevation: 8,
    ),

    // Progress Indicator Theme
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: NexoraColors.primaryOrange,
      circularTrackColor: Colors.white.withOpacity(0.08),
    ),

    // Divider Theme
    dividerTheme: DividerThemeData(
      color: NexoraColors.glassBorder,
      thickness: 1,
      space: 20,
    ),

    // Tooltip Theme
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: NexoraColors.midnightPurple,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(color: NexoraColors.textPrimary),
    ),

    // Page Transitions
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static ThemeData get lightTheme =>
      darkTheme; // Fallback to dark theme for now

  static InputDecoration glassInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: NexoraColors.textMuted),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: const BorderSide(color: NexoraColors.primaryOrange),
      ),
    );
  }
}

/// =====================================================
/// CUSTOM PAINTER FOR HEART ANIMATIONS
/// =====================================================

class HeartPainter extends CustomPainter {
  final double progress;
  final Color color;

  HeartPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);

    final path = Path();
    final width = size.width;
    final height = size.height;
    final scale = 0.8 + (progress * 0.2);

    path.moveTo(width * 0.5, height * 0.2);
    path.cubicTo(
      width * 0.3,
      height * 0.1,
      width * 0.1,
      height * 0.3,
      width * 0.5,
      height * 0.8,
    );
    path.cubicTo(
      width * 0.9,
      height * 0.3,
      width * 0.7,
      height * 0.1,
      width * 0.5,
      height * 0.2,
    );

    canvas.scale(scale, scale);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
