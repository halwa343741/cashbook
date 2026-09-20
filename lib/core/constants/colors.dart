import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Consistent in both modes)
  static const Color primary = Color(0xFF15803D);      // Emerald Green
  static const Color primary500 = Color(0xFF15803D);
  static const Color primaryDark = Color(0xFF0F5B2C);  // Dark Splash Emerald
  static const Color primaryLight = Color(0xFFDCFCE7); // Light Emerald Tint
  static const Color primaryHover = Color(0xFF166534); // Darker Green for press

  // Status & Transaction Colors
  static const Color income = Color(0xFF16A34A);       // Cash In Green
  static const Color incomeGreen = Color(0xFF16A34A);
  static const Color incomeLight = Color(0xFFDCFCE7);  // Light Green Tag

  static const Color expense = Color(0xFFEF4444);      // Cash Out Red
  static const Color expenseRed = Color(0xFFEF4444);
  static const Color expenseLight = Color(0xFFFEE2E2); // Light Red Tag

  static const Color transfer = Color(0xFF3B82F6);     // Blue Transfer
  static const Color blue500 = Color(0xFF3B82F6);
  static const Color transferLight = Color(0xFFDBEAFE);// Light Blue Tag

  static const Color amber500 = Color(0xFFF59E0B);
  static const Color white = Color(0xFFFFFFFF);

  // Gray & Neutral Palette
  static const Color gray50 = Color(0xFFF8FAFC);
  static const Color gray100 = Color(0xFFF1F5F9);
  static const Color gray200 = Color(0xFFE2E8F0);
  static const Color gray300 = Color(0xFFCBD5E1);
  static const Color gray400 = Color(0xFF94A3B8);
  static const Color gray500 = Color(0xFF64748B);
  static const Color gray600 = Color(0xFF475569);
  static const Color gray700 = Color(0xFF334155);
  static const Color gray800 = Color(0xFF1E293B);
  static const Color gray900 = Color(0xFF0F172A);

  // --- Light Mode Palette ---
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);    // Pure White
  static const Color lightCardBorder = Color(0xFFF1F5F9); // Slate 100
  static const Color lightInputBorder = Color(0xFFE2E8F0);// Slate 200
  static const Color lightTextPrimary = Color(0xFF0F172A);// Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightTextMuted = Color(0xFF94A3B8);  // Slate 400
  static const Color lightDivider = Color(0xFFE2E8F0);

  // --- Dark Mode Palette ---
  static const Color darkBackground = Color(0xFF0B1120);  // Deep Dark Slate
  static const Color darkSurface = Color(0xFF1E293B);     // Slate 800
  static const Color darkCardBorder = Color(0xFF334155);  // Slate 700
  static const Color darkInputBorder = Color(0xFF475569); // Slate 600
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // Slate 50
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // Slate 300
  static const Color darkTextMuted = Color(0xFF64748B);   // Slate 500
  static const Color darkDivider = Color(0xFF334155);
}
