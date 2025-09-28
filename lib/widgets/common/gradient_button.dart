import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final bool enabled;
  final double? width;
  final double? height;
  final List<Color>? colors; 


  const GradientButton({
    Key? key,
    required this.text,
    required this.onTap,
    this.enabled = true,
    this.width,
    this.height,
    this.colors, 
  });

  }) : super(key: key);


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: enabled
              ? LinearGradient(
            colors: colors ?? [AppColors.principal, AppColors.secundario],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          )
              : null,
          color: enabled ? null : Color(0xFFE9ECEF),
          borderRadius: BorderRadius.circular(28),
          boxShadow: enabled
              ? [
            BoxShadow(
              color: (colors != null ? colors!.first : AppColors.principal)
                  .withOpacity(0.3), 
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
              color: enabled ? Colors.white : Color(0xFF666666),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}