import 'package:flutter/material.dart';

class LinkText extends StatelessWidget {
  final VoidCallback? onTap;
  final String text1;
  final String text2;
  final Color colorText1;
  final Color colorText2;

  const LinkText({
    super.key,
    required this.onTap,
    required this.text1,
    required this.text2,
    required this.colorText1,
    required this.colorText2,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: const TextStyle(
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.3,
            height: 1.4,
          ),
          children: [
            TextSpan(
              text: text1,
              style: TextStyle(color: colorText1),
            ),
            TextSpan(
              text: text2,
              style: TextStyle(
                color: colorText2,
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
      ),
    );
  }
}