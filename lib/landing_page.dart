import 'dart:math' as math;

import 'package:corporator_app/features/auth/presentation/login.dart';
import 'package:flutter/material.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with TickerProviderStateMixin {

  // ── Brand Colors ──
  static const saffron     = Color(0xFFFF6700);
  static const deepSaffron = Color(0xFFE55C00);
  static const gold        = Color(0xFFFFD700);
  static const navyBlue    = Color(0xFF002868);
  static const darkNavy    = Color(0xFF001A45);
  static const white       = Color(0xFFFFFDF7);
  static const indiaGreen  = Color(0xFF138808);

  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _fadeController;
  late AnimationController _slideController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Navy gradient background ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [darkNavy, navyBlue, Color(0xFF003580)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // ── Chakra pattern ──
          Positioned.fill(
            child: CustomPaint(painter: _ChakraPatternPainter()),
          ),

          // ── Saffron top strip ──
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [saffron, gold, saffron]),
              ),
            ),
          ),

          // ── Bottom green strip ──
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [indiaGreen, Color(0xFF0A5C06), indiaGreen]),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: Column(
                    children: [
                      const Spacer(flex: 2),

                      // ── Pulsing Emblem ──
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [gold, saffron, deepSaffron],
                              stops: [0.3, 0.7, 1.0],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gold.withOpacity(0.55),
                                blurRadius: 36,
                                spreadRadius: 6,
                              ),
                              BoxShadow(
                                color: saffron.withOpacity(0.3),
                                blurRadius: 60,
                                spreadRadius: 14,
                              ),
                            ],
                            border: Border.all(color: gold, width: 3),
                          ),
                          child: const Icon(
                            Icons.account_balance,
                            size: 60,
                            color: darkNavy,
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── App name ──
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [gold, white, gold],
                        ).createShader(bounds),
                        child: const Text(
                          "CORPORATOR APP",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 5,
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Hindi subtitle ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 6),
                        decoration: BoxDecoration(
                          border: Border(
                            left: BorderSide(color: saffron, width: 3),
                            right: BorderSide(color: saffron, width: 3),
                          ),
                        ),
                        child: const Text(
                          "जनता की सेवा • नागरिकों का विकास",
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFFFFD580),
                            fontStyle: FontStyle.italic,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── Saffron tagline banner ──
                      AnimatedBuilder(
                        animation: _shimmerController,
                        builder: (context, child) => Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              vertical: 11, horizontal: 16),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [saffron, Color(0xFFFF8C00), deepSaffron],
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: saffron.withOpacity(0.45),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: const [
                              Icon(Icons.star, color: Colors.white, size: 14),
                              SizedBox(width: 10),
                              Text(
                                "SEVA • VIKAS • SAMARPAN",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 3,
                                ),
                              ),
                              SizedBox(width: 10),
                              Icon(Icons.star, color: Colors.white, size: 14),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(flex: 2),

                      // ── Feature pills ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _featurePill(Icons.shield_outlined,    "Secure"),
                          const SizedBox(width: 12),
                          _featurePill(Icons.bolt_outlined,      "Fast"),
                          const SizedBox(width: 12),
                          _featurePill(Icons.verified_outlined,  "Official"),
                        ],
                      ),

                      const SizedBox(height: 36),

                      // ── LOGIN Button ──
                      SizedBox(
                        width: double.infinity,
                        height: 58,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const Login()),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Ink(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [saffron, deepSaffron],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: saffron.withOpacity(0.55),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Container(
                              alignment: Alignment.center,
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.login_rounded,
                                      color: Colors.white, size: 22),
                                  SizedBox(width: 12),
                                  Text(
                                    "LOGIN",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Tricolor divider ──
                      Row(
                        children: [
                          Expanded(child: Container(height: 3, color: saffron)),
                          Expanded(child: Container(height: 3, color: white)),
                          Expanded(child: Container(height: 3, color: indiaGreen)),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // ── Footer ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.verified_user,
                              color: gold.withOpacity(0.6), size: 13),
                          const SizedBox(width: 6),
                          Text(
                            "Authorised Government Portal  •  Secure & Encrypted",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.45),
                              fontSize: 11,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      Text(
                        "© 2025 Corporator Portal. All Rights Reserved.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.25),
                          fontSize: 10,
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.25), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: gold, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ashoka Chakra background painter ──
class _ChakraPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final centers = [
      Offset(size.width * 0.85, size.height * 0.12),
      Offset(size.width * 0.08, size.height * 0.55),
      Offset(size.width * 0.6,  size.height * 0.88),
    ];

    for (final center in centers) {
      for (int r = 20; r <= 200; r += 22) {
        canvas.drawCircle(center, r.toDouble(), paint);
      }
      final spokePaint = Paint()
        ..color = Colors.white.withOpacity(0.035)
        ..strokeWidth = 1;
      for (int i = 0; i < 24; i++) {
        final angle = (i * math.pi * 2) / 24;
        canvas.drawLine(
          center,
          Offset(
            center.dx + math.cos(angle) * 200,
            center.dy + math.sin(angle) * 200,
          ),
          spokePaint,
        );
      }
    }

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 36) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        linePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}