import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─── Palette ────────────────────────────────────────────────────────────────
const Color kCream    = Color(0xFFFDF8F2);
const Color kWarm     = Color(0xFFF5E9D8);
const Color kBrown    = Color(0xFF4A2E12);
const Color kBrown2   = Color(0xFF6B4423);
const Color kAmber    = Color(0xFFC97C2A);
const Color kAmber2   = Color(0xFFE8A84B);
const Color kDark     = Color(0xFF1A0D04);
const Color kMuted    = Color(0xFF8A7060);
const Color kMuted2   = Color(0xFFB09880);

const Color kGreen    = Color(0xFF2D5A2A);
const Color kGreenBg  = Color(0xFFE6F2E5);
const Color kRed      = Color(0xFF7A2020);
const Color kRedBg    = Color(0xFFF5E5E5);
const Color kBlueDark = Color(0xFF1E3A6E);
const Color kBlueBg   = Color(0xFFE5ECF8);
const Color kYellow   = Color(0xFF7A6000);
const Color kYellowBg = Color(0xFFFFF8DC);

// ─── Typography ─────────────────────────────────────────────────────────────
TextTheme pawIDTextTheme() {
  return TextTheme(
    displayLarge: GoogleFonts.playfairDisplay(
      fontSize: 32, fontWeight: FontWeight.w700, color: kDark,
    ),
    displayMedium: GoogleFonts.playfairDisplay(
      fontSize: 26, fontWeight: FontWeight.w700, color: kDark,
    ),
    displaySmall: GoogleFonts.playfairDisplay(
      fontSize: 22, fontWeight: FontWeight.w600, color: kDark,
    ),
    headlineMedium: GoogleFonts.playfairDisplay(
      fontSize: 18, fontWeight: FontWeight.w600, color: kDark,
    ),
    headlineSmall: GoogleFonts.dmSans(
      fontSize: 16, fontWeight: FontWeight.w600, color: kDark,
    ),
    titleLarge: GoogleFonts.dmSans(
      fontSize: 16, fontWeight: FontWeight.w600, color: kDark,
    ),
    titleMedium: GoogleFonts.dmSans(
      fontSize: 14, fontWeight: FontWeight.w600, color: kDark,
    ),
    bodyLarge: GoogleFonts.dmSans(
      fontSize: 15, fontWeight: FontWeight.w400, color: kDark,
    ),
    bodyMedium: GoogleFonts.dmSans(
      fontSize: 13, fontWeight: FontWeight.w400, color: kMuted,
    ),
    labelLarge: GoogleFonts.dmSans(
      fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 0.5,
    ),
    labelSmall: GoogleFonts.spaceMono(
      fontSize: 10, fontWeight: FontWeight.w400, letterSpacing: 0.8, color: kMuted,
    ),
  );
}

// ─── Theme ───────────────────────────────────────────────────────────────────
ThemeData pawIDTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.light(
      primary: kAmber,
      primaryContainer: kWarm,
      secondary: kBrown,
      surface: kCream,
      background: kCream,
      onPrimary: Colors.white,
      onSecondary: Colors.white,
      onSurface: kDark,
    ),
    scaffoldBackgroundColor: kCream,
    textTheme: pawIDTextTheme(),
    appBarTheme: AppBarTheme(
      backgroundColor: kCream,
      elevation: 0,
      centerTitle: false,
      iconTheme: const IconThemeData(color: kBrown),
      titleTextStyle: GoogleFonts.playfairDisplay(
        fontSize: 22, fontWeight: FontWeight.w700, color: kBrown,
      ),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kAmber,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kWarm,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      hintStyle: GoogleFonts.dmSans(color: kMuted2),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: kWarm,
      iconTheme: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const IconThemeData(color: kAmber);
        }
        return const IconThemeData(color: kMuted);
      }),
      labelTextStyle: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w600, color: kAmber);
        }
        return GoogleFonts.dmSans(fontSize: 11, color: kMuted);
      }),
    ),
  );
}

// ─── Indian breeds ────────────────────────────────────────────────────────────
const List<String> kIndianBreeds = [
  'Indian Pariah Dog',
  'Rajapalayam dog',
  'Mudhol Hound',
  'Chippiparai',
  'Kombai',
  'Kanni',
  'Jonangi',
  'Bakharwal Dog',
  'Rampur Greyhound',
  'Tibetan Mastiff',
];

// ─── Misc ─────────────────────────────────────────────────────────────────────
const String kDefaultServerUrl = 'http://10.0.2.2:5000';
const String kServerUrlKey = 'server_url';
const int kMaxHistory = 20;