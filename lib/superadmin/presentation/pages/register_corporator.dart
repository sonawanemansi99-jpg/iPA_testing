import 'dart:math' as math;

import 'package:corporator_app/features/auth/presentation/login.dart';
import 'package:corporator_app/superadmin/services/superadmin_services.dart';
import 'package:flutter/material.dart';

class CorporatorRegistrationPage extends StatefulWidget {
  const CorporatorRegistrationPage({super.key});

  @override
  State<CorporatorRegistrationPage> createState() =>
      _CorporatorRegistrationPageState();
}

class _CorporatorRegistrationPageState
    extends State<CorporatorRegistrationPage> with TickerProviderStateMixin {

  final nameController     = TextEditingController();
  final emailController    = TextEditingController();
  final passwordController = TextEditingController();
  final mobileController   = TextEditingController();

  final SuperadminServices superadminServices = SuperadminServices();
  bool isLoading = false;
  bool isPasswordHidden = true;

  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

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
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    mobileController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  // ── BACKEND LOGIC UNTOUCHED ──
  Future<void> registerCorporator() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        mobileController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: const [
            Icon(Icons.warning_amber_rounded, color: Colors.white),
            SizedBox(width: 10),
            Text("Please fill all fields",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await superadminServices.registerCorporator(
        name:     nameController.text.trim(),
        email:    emailController.text.trim(),
        password: passwordController.text.trim(),
        mobileNo: mobileController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Corporator Registered Successfully!",
                style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          backgroundColor: saffron,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> logout() async {
    try {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const Login()));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Logout failed: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
          Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),

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

          SafeArea(
            child: Column(
              children: [
                // ── Custom AppBar ──
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      // App emblem
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [gold, saffron, deepSaffron],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gold.withOpacity(0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.account_balance,
                              size: 20, color: darkNavy),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [gold, white, gold],
                          ).createShader(bounds),
                          child: const Text(
                            "CREATE CORPORATOR",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.5,
                            ),
                          ),
                        ),
                      ),
                      // Logout button
                      GestureDetector(
                        onTap: logout,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                                color: Colors.red.withOpacity(0.5)),
                          ),
                          child: const Icon(Icons.logout_rounded,
                              color: Colors.redAccent, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Tagline strip ──
                AnimatedBuilder(
                  animation: _shimmerController,
                  builder: (context, child) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [saffron, Color(0xFFFF8C00), deepSaffron],
                      ),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: saffron.withOpacity(0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.star, color: Colors.white, size: 13),
                        SizedBox(width: 8),
                        Text(
                          "SUPERADMIN • REGISTRATION PORTAL",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.star, color: Colors.white, size: 13),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ── Scrollable form ──
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // ── Personal Info Card ──
                        _buildSectionCard(
                          headerTitle: "PERSONAL INFORMATION",
                          headerIcon: Icons.person_outline,
                          children: [
                            _buildField(
                              controller: nameController,
                              label: "Full Name",
                              hint: "Enter corporator's full name",
                              icon: Icons.person_outline,
                            ),
                            const SizedBox(height: 16),
                            _buildField(
                              controller: mobileController,
                              label: "Mobile Number",
                              hint: "Enter mobile number",
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── Credentials Card ──
                        _buildSectionCard(
                          headerTitle: "LOGIN CREDENTIALS",
                          headerIcon: Icons.lock_outline,
                          children: [
                            _buildField(
                              controller: emailController,
                              label: "Email Address",
                              hint: "Enter official email",
                              icon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                            ),
                            const SizedBox(height: 16),
                            _buildPasswordField(),
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── Register Button ──
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : registerCorporator,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              elevation: 0,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                gradient: isLoading
                                    ? null
                                    : const LinearGradient(
                                        colors: [saffron, deepSaffron],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                color:
                                    isLoading ? Colors.grey.shade500 : null,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: isLoading
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: saffron.withOpacity(0.5),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.how_to_reg,
                                              color: Colors.white, size: 20),
                                          SizedBox(width: 10),
                                          Text(
                                            "REGISTER CORPORATOR",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 15,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 2,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Tricolor footer ──
                        Row(
                          children: [
                            Expanded(
                                child: Container(height: 3, color: saffron)),
                            Expanded(
                                child: Container(height: 3, color: white)),
                            Expanded(
                                child: Container(
                                    height: 3,
                                    color: const Color(0xFF138808))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "© 2025 Corporator Portal. All Rights Reserved.",
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.35),
                              fontSize: 10),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Section card with navy header ──
  Widget _buildSectionCard({
    required String headerTitle,
    required IconData headerIcon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: saffron.withOpacity(0.1),
            blurRadius: 14,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [darkNavy, navyBlue]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(headerIcon, color: gold, size: 18),
                const SizedBox(width: 10),
                Text(
                  headerTitle,
                  style: const TextStyle(
                    color: gold,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.5,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  // ── Standard text field ──
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: navyBlue,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(
              fontSize: 15, color: darkNavy, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: saffron, size: 22),
            filled: true,
            fillColor: const Color(0xFFF7F5EF),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: saffron, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 14),
          ),
        ),
      ],
    );
  }

  // ── Password field ──
  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "PASSWORD",
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: navyBlue,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          obscureText: isPasswordHidden,
          style: const TextStyle(
              fontSize: 15, color: darkNavy, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: "Create a strong password",
            hintStyle:
                TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon:
                const Icon(Icons.lock_outline, color: saffron, size: 22),
            suffixIcon: IconButton(
              icon: Icon(
                isPasswordHidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey.shade500,
                size: 20,
              ),
              onPressed: () =>
                  setState(() => isPasswordHidden = !isPasswordHidden),
            ),
            filled: true,
            fillColor: const Color(0xFFF7F5EF),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide:
                  BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: saffron, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
                vertical: 16, horizontal: 14),
          ),
        ),
      ],
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
      Offset(size.width * 0.1, size.height * 0.75),
    ];

    for (final center in centers) {
      for (int r = 20; r <= 180; r += 22) {
        canvas.drawCircle(center, r.toDouble(), paint);
      }
      final spokePaint = Paint()
        ..color = Colors.white.withOpacity(0.04)
        ..strokeWidth = 1;
      for (int i = 0; i < 24; i++) {
        final angle = (i * math.pi * 2) / 24;
        canvas.drawLine(
          center,
          Offset(
            center.dx + math.cos(angle) * 180,
            center.dy + math.sin(angle) * 180,
          ),
          spokePaint,
        );
      }
    }

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.025)
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