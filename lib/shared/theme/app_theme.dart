import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════
// APP THEME — paleta coherente con la versión web
// Fondo oscuro #0d1117 + acento índigo #4361ee
// ══════════════════════════════════════════════════════════════════

abstract class AppColors {
  // Fondos
  static const bg = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const surface2 = Color(0xFF1C2230);
  static const surface3 = Color(0xFF212940);

  // Bordes
  static const border = Color(0xFF30363D);
  static const border2 = Color(0xFF3D4658);

  // Acento
  static const indigo = Color(0xFF4361EE);
  static const indigoLight = Color(0xFF7B93F9);

  // Semáforo legal
  static const danger = Color(0xFFE53E3E);
  static const warning = Color(0xFFD97706);
  static const success = Color(0xFF2EA86F);
  static const info = Color(0xFF4361EE);

  // Texto
  static const text = Color(0xFFE6EDF3);
  static const text2 = Color(0xFF8B949E);
  static const text3 = Color(0xFF6E7681);
}

abstract class AppTheme {
  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.bg,

        colorScheme: const ColorScheme.dark(
          primary: AppColors.indigo,
          secondary: AppColors.indigoLight,
          surface: AppColors.surface,
          error: AppColors.danger,
          onPrimary: Colors.white,
          onSurface: AppColors.text,
        ),

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.text,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          titleTextStyle: TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),

        // Bottom Navigation
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.indigo.withOpacity(0.2),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                color: AppColors.indigoLight,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              );
            }
            return const TextStyle(color: AppColors.text3, fontSize: 11);
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppColors.indigoLight, size: 22);
            }
            return const IconThemeData(color: AppColors.text3, size: 22);
          }),
        ),

        // Cards
        cardTheme: CardThemeData(
          color: AppColors.surface,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: AppColors.border),
          ),
          margin: const EdgeInsets.only(bottom: 14),
        ),

        // Inputs
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface3,
          labelStyle: const TextStyle(color: AppColors.text2, fontSize: 12),
          hintStyle: const TextStyle(color: AppColors.text3),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.indigo, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.danger),
          ),
        ),

        // ElevatedButton
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.indigo,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            elevation: 0,
          ),
        ),

        // OutlinedButton
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.text2,
            side: const BorderSide(color: AppColors.border),
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),

        // Chip
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.surface3,
          selectedColor: AppColors.indigo.withOpacity(0.2),
          labelStyle:
              const TextStyle(color: AppColors.text2, fontSize: 12),
          side: const BorderSide(color: AppColors.border),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 24,
        ),

        // SnackBar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.surface2,
          contentTextStyle: const TextStyle(color: AppColors.text),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          behavior: SnackBarBehavior.floating,
        ),

        // Text
        textTheme: const TextTheme(
          displayLarge: TextStyle(color: AppColors.text),
          headlineMedium: TextStyle(
              color: AppColors.text, fontSize: 20, fontWeight: FontWeight.w800),
          titleLarge: TextStyle(
              color: AppColors.text, fontSize: 16, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(
              color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: AppColors.text, fontSize: 14),
          bodyMedium: TextStyle(color: AppColors.text2, fontSize: 13),
          bodySmall: TextStyle(color: AppColors.text3, fontSize: 11.5),
          labelSmall: TextStyle(
              color: AppColors.text2,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.07),
        ),
      );
}
