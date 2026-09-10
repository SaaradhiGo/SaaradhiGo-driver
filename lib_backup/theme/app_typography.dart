import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  static TextStyle get headlineMd => GoogleFonts.inter(
    fontSize: 24,
    height: 32 / 24,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get displayLg => GoogleFonts.inter(
    fontSize: 32,
    height: 40 / 32,
    letterSpacing: -0.02 * 32, // -0.02em
    fontWeight: FontWeight.w700,
  );

  static TextStyle get dataMono => GoogleFonts.jetBrainsMono(
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
  );

  static TextStyle get bodyMd => GoogleFonts.inter(
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get headlineSm => GoogleFonts.inter(
    fontSize: 20,
    height: 28 / 20,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get bodyLg => GoogleFonts.inter(
    fontSize: 18,
    height: 26 / 18,
    fontWeight: FontWeight.w400,
  );

  static TextStyle get headlineLgMobile => GoogleFonts.inter(
    fontSize: 28,
    height: 34 / 28,
    fontWeight: FontWeight.w700,
  );

  static TextStyle get labelCaps => GoogleFonts.inter(
    fontSize: 12,
    height: 16 / 12,
    letterSpacing: 0.05 * 12, // 0.05em
    fontWeight: FontWeight.w700,
  );
}
