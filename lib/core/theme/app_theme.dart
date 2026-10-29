import 'package:flutter/material.dart';

class AppTheme {
  // Brand colors from screens/stitch_helpdesk_mobile_support_app/odoo_desk/DESIGN.md
  static const Color primaryTeal = Color(0xFF017E84);
  static const Color primaryDark = Color(0xFF006368);
  static const Color secondaryAubergine = Color(0xFF714B67);
  static const Color surfaceCanvas = Color(0xFFF6FAFF);
  static const Color surfaceCard = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFECF5FE);
  static const Color surfaceContainer = Color(0xFFE6EFF8);
  static const Color surfaceContainerHigh = Color(0xFFE0E9F2);
  static const Color hairlineBorder = Color(0xFFDEE2E6);

  static const Color textPrimary = Color(0xFF141D23);
  static const Color textSecondary = Color(0xFF3E4949);
  static const Color textMuted = Color(0xFF6E797A);

  // Specialized Semantic Status Tokens from DESIGN.md
  static const statusNew = StatusToken(
    foreground: Color(0xFF2D62A3),
    container: Color(0xFFE3EEFA),
    border: Color(0xFFBFD7F2),
  );
  static const statusApproved = StatusToken(
    foreground: Color(0xFF016B88),
    container: Color(0xFFD1ECF1),
    border: Color(0xFFA8DAE3),
  );
  static const statusTracking = StatusToken(
    foreground: Color(0xFF5B3FB5),
    container: Color(0xFFEFE9FB),
    border: Color(0xFFD3C6F5),
  );
  static const statusWip = StatusToken(
    foreground: Color(0xFF7A5601),
    container: Color(0xFFFFF3CD),
    border: Color(0xFFFFE08A),
  );
  static const statusSolving = StatusToken(
    foreground: Color(0xFF5B3C53),
    container: Color(0xFFF1E6EE),
    border: Color(0xFFDFC8D8),
  );
  static const statusDone = StatusToken(
    foreground: Color(0xFF006D15),
    container: Color(0xFFD4EDDA),
    border: Color(0xFFB6DFC0),
  );
  static const statusRejected = StatusToken(
    foreground: Color(0xFFB02A37),
    container: Color(0xFFF8D7DA),
    border: Color(0xFFF1AEB5),
  );

  static StatusToken getStatusToken(String stageName, {bool isClosed = false, int sequence = 1}) {
    final lower = stageName.toLowerCase();
    if (lower.contains('new')) return statusNew;
    if (lower.contains('approve')) return statusApproved;
    if (lower.contains('track')) return statusTracking;
    if (lower.contains('progress') || lower.contains('wip')) return statusWip;
    if (lower.contains('solving')) return statusSolving;
    if (lower.contains('done') || lower.contains('close') || isClosed && !lower.contains('reject')) return statusDone;
    if (lower.contains('reject') || lower.contains('cancel')) return statusRejected;

    switch (sequence) {
      case 1:
        return statusNew;
      case 2:
        return statusApproved;
      case 3:
        return statusTracking;
      case 4:
        return statusWip;
      case 5:
        return statusSolving;
      case 6:
        return statusDone;
      case 7:
        return statusRejected;
      default:
        return statusNew;
    }
  }

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: surfaceCanvas,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryTeal,
        primary: primaryTeal,
        onPrimary: Colors.white,
        secondary: secondaryAubergine,
        surface: surfaceCanvas,
        onSurface: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: surfaceCanvas,
        foregroundColor: textPrimary,
        centerTitle: false,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: hairlineBorder),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: hairlineBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: hairlineBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryTeal, width: 2),
        ),
      ),
    );
  }

  static ThemeData get darkTheme => lightTheme;
}

class StatusToken {
  final Color foreground;
  final Color container;
  final Color border;

  const StatusToken({
    required this.foreground,
    required this.container,
    required this.border,
  });
}
