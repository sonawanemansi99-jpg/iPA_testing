import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._(); 

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF2596BE),
      Color(0xFF0C6795),
      Color(0xFF0F5272),
    ],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient darkGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF2596BE),
      Color(0xFF0C6795),
      Color(0xFF0F5272),
      Color(0xFF0A3F58),
    ],
  );


  static const RadialGradient glowGradient = RadialGradient(
    center: Alignment.topLeft,
    radius: 1.3,
    colors: [
      Color(0xFF2596BE),
      Color(0xFF0C6795),
      Color(0xFF0F5272),
    ],
  );
}