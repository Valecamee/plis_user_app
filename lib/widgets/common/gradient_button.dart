import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final double? width;
  final double? height;
  final List<Color>? colors; // 👈 colores personalizados

  const GradientButton({
    super.key,
    required this.text,
    required this.onTap,
    this.enabled = true,
    this.width,
    this.height,
    this.colors, // 👈 se recibe
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: width ?? double.infinity,
        height: height ?? 56,
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
            colors: colors ?? [AppColors.principal, AppColors.secundario], // 👈 usa los que pases, o por defecto los tuyos
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : null,
          color: enabled ? null : AppColors.gris300,
          borderRadius: BorderRadius.circular(28),
          boxShadow: enabled
              ? [
            BoxShadow(
              color: (colors != null ? colors!.first : AppColors.principal)
                  .withOpacity(0.3), // 👈 sombra adaptada al color
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: enabled ? Colors.white : AppColors.gris600,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
