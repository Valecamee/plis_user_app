import 'package:flutter/material.dart';

class PermissionItem extends StatelessWidget {
  final Widget icon;
  final String text;
  final String subtext;
  final bool isSelected;
  final VoidCallback onTap;

  const PermissionItem({
    Key? key,
    required this.icon,
    required this.text,
    required this.subtext,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFF0FDFC) : Color(0xFFF8F9FA),
          border: Border.all(
            color: isSelected ? Color(0xFF4ECDC4) : Color(0xFFE9ECEF),
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            icon,
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF495057),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtext,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF495057),
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Color(0xFF4ECDC4),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }
}