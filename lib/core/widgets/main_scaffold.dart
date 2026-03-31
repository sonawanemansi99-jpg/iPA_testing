import 'package:flutter/material.dart';

class MainScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final Widget? floatingActionButton;

  const MainScaffold({
    super.key,
    required this.body,
    required this.title,
    this.floatingActionButton,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with TickerProviderStateMixin {
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  // ── Brand Colors ──
  static const Color saffron     = Color(0xFFFF6700);
  static const Color deepSaffron = Color(0xFFE55C00);
  static const Color gold        = Color(0xFFFFD700);
  static const Color navyBlue    = Color(0xFF002868);
  static const Color darkNavy    = Color(0xFF001A45);
  static const Color white       = Color(0xFFFFFDF7);

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkNavy, // Base color to blend with gradient
      appBar: _buildAppBar(context),
      body: widget.body,
      floatingActionButton: widget.floatingActionButton,
    );
  }

  // ── Themed AppBar ──
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [darkNavy, navyBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
          // Bottom saffron accent line
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [saffron, gold, saffron]),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: SizedBox(
                height: 64, // Match the preferred size height
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // ── Smart Back Button (Left Aligned) ──
                    if (Navigator.canPop(context))
                      Align(
                        alignment: Alignment.centerLeft,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: gold.withOpacity(0.35)),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new,
                              color: Colors.white70,
                              size: 18,
                            ),
                          ),
                        ),
                      ),

                    // ── Title (Perfectly Centered) ──
                    Align(
                      alignment: Alignment.center,
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [gold, white, gold],
                        ).createShader(bounds),
                        child: Text(
                          widget.title.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),

                    // ── Pulsing emblem (Right Aligned) ──
                    Align(
                      alignment: Alignment.centerRight,
                      child: ScaleTransition(
                        scale: _pulseAnimation ?? kAlwaysCompleteAnimation,
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [gold, saffron, deepSaffron],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gold.withOpacity(0.5),
                                blurRadius: 10,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.account_balance,
                              size: 18, color: darkNavy),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}