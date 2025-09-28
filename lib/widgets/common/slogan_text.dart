import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:plis_user/utils/app_colors.dart';

class SloganText extends StatelessWidget {
  const SloganText({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Compartir es",
          style: GoogleFonts.manrope(
            fontSize: 42.0,
            fontWeight: FontWeight.w700,
            color: AppColors.indigoSuave,
            letterSpacing: 0.5,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          "Avanzar",
          style: GoogleFonts.manrope(
            fontSize: 42.0,
            fontWeight: FontWeight.w900,
            color: AppColors.principal,
            letterSpacing: 0.5,
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
