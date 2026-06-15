import 'package:flutter/material.dart';

class AppTheme {
  // Brand Colors
  static const Color primaryBlue = Color(0xFF2563EB); // blue-600
  static const Color darkBg = Color(0xFF08060D);
  static const Color darkCard = Color(0xFF16171D);
  static const Color grayBorder = Color(0xFFE5E7EB);
  static const Color darkGrayBorder = Color(0xFF1F2937);

  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: const Color(0xFFF1F2F6),
    colorScheme: const ColorScheme.light(
      primary: primaryBlue,
      secondary: primaryBlue,
      surface: Colors.white,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.black),
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: grayBorder),
      ),
    ),
    useMaterial3: true,
  );

  static ThemeData darkTheme = ThemeData(
    primaryColor: primaryBlue,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      primary: primaryBlue,
      secondary: primaryBlue,
      surface: darkCard,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: darkCard,
      elevation: 0,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: darkGrayBorder),
      ),
    ),
    useMaterial3: true,
  );
}
