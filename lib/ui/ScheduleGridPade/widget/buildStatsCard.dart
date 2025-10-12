  import 'package:flutter/material.dart';

Widget buildStatsCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required BuildContext context,
  }) {
    final width = MediaQuery.of(context).size.width;

    // 🔹 Responsive breakpoints
    double padding;
    double iconSize;
    double valueFontSize;
    double titleFontSize;
    double spacing;
    double height;

    if (width < 600) {
      // Mobile
      padding = 8;
      iconSize = 20;
      valueFontSize = 16;
      titleFontSize = 12;
      spacing = 4;
      height = 100;
    } else if (width < 1024) {
      // Tablet
      padding = 10;
      iconSize = 24;
      valueFontSize = 20;
      titleFontSize = 13;
      spacing = 6;
      height = 120;
    } else if (width < 1600) {
      // Laptop
      padding = 12;
      iconSize = 28;
      valueFontSize = 24;
      titleFontSize = 14;
      spacing = 8;
      height = 140;
    } else {
      // Large screens
      padding = 16;
      iconSize = 32;
      valueFontSize = 28;
      titleFontSize = 16;
      spacing = 10;
      height = 160;
    }

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: iconSize, color: Colors.white),
          SizedBox(height: spacing),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: spacing),
          Text(
            title,
            style: TextStyle(
              fontSize: titleFontSize,
              color: Colors.white70,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }