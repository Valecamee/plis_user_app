import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final double? width;
  final double? height;

  const GradientButton({
    super.key,
    required this.text,
    required this.onTap,
    this.enabled = true,
    this.width,
    this.height,
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
              ? const LinearGradient(
            colors: [AppColors.principal, AppColors.secundario],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : null,
          color: enabled ? null : AppColors.gris300,
          borderRadius: BorderRadius.circular(28),
          boxShadow: enabled
              ? [
            BoxShadow(
              color: AppColors.principal.withOpacity(0.3),
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