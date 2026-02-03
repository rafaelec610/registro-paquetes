import 'package:flutter/material.dart';

class AppColors {
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color green = Color(0xFF1DB954);
  static const Color yellow = Color(0xFFFFC107);
  static const Color darkGray = Color(0xFF121212);
  static const Color lightGray = Color(0xFFF2F2F2);
}

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.white,

    primaryColor: AppColors.black,

    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.green,
      foregroundColor: AppColors.white,
      elevation: 0,
      centerTitle: true,
    ),

    drawerTheme: const DrawerThemeData(
      backgroundColor: AppColors.white,
    ),

    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.black,
      secondary: AppColors.green,
      surface: AppColors.white,
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.green,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
    ),

    listTileTheme: const ListTileThemeData(
      iconColor: AppColors.black,
      textColor: AppColors.black,
    ),

    dividerColor: AppColors.lightGray,
  );
}
