import 'package:corporator_app/features/complaints/presentation/screens/zone_sevak_complaints_page.dart';
import 'package:corporator_app/corporator/presentations/corporator_dashboard.dart';
import 'package:corporator_app/services/auth_service.dart';
import 'package:corporator_app/superadmin/presentation/pages/register_corporator.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> with TickerProviderStateMixin {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordHidden = true;
  bool _isLoading = false;

  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final AuthService _authService = AuthService();

  // Brand Colors — Saffron + Deep Tricolor
  static const Color saffron = Color(0xFFFF6700);
  static const Color deepSaffron = Color(0xFFE55C00);
  static const Color gold = Color(0xFFFFD700);
  static const Color navyBlue = Color(0xFF002868);
  static const Color darkNavy = Color(0xFF001A45);
  static const Color white = Color(0xFFFFFDF7);
  static const Color ashoka = Color(0xFF1A6FAB);

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
    emailController.dispose();
    passwordController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }


// Assuming you have instantiated the service at the top of your state class:
// final AuthService _authService = AuthService();

Future<void> loginUser() async {
  setState(() => _isLoading = true);
  
  try {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    // 1. Call the new Spring Boot AuthService
    bool success = await _authService.login(email, password);
    
    if (!success) {
      throw Exception("Invalid credentials or server error");
    }

    // 2. Fetch the securely stored role
    const storage = FlutterSecureStorage();
    String role = await storage.read(key: 'user_role') ?? "";
    String uid = await storage.read(key: 'user_id') ?? "1"; // See important note below!

    if (!mounted) return;

    // 3. Show your beautiful Success SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text(
              "जय हिन्द! Login Successful",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: saffron, // Replaced 'saffron' variable if not defined locally
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );

    // 4. Route based on Spring Boot Roles
    if (role == "ROLE_SUPER_ADMIN") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CorporatorRegistrationPage()),
      );
    } else if (role == "ROLE_ADMIN") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CorporatorDashboard()),
      );
    } else if (role == "ROLE_ZONE_SEVAK") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ZoneSevakComplaintsPage()), // Or SevakDashboard
      );
    } else {
      throw Exception("Unknown role received: $role");
    }

  } catch (e) {
    if (!mounted) return;
    
    // 5. Show Error SnackBar
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(e.toString().replaceAll("Exception: ", "")),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Deep navy gradient background ──
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

          // ── Geometric Ashoka Chakra pattern background ──
          Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),

          // ── Saffron top banner strip ──
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [saffron, gold, saffron]),
              ),
            ),
          ),

          // ── Main content ──
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 32),

                  // ── Party / App Logo Section ──
                  _buildLogoSection(size),

                  const SizedBox(height: 28),

                  // ── Tagline Banner ──
                  _buildTaglineBanner(),

                  const SizedBox(height: 28),

                  // ── Login Card ──
                  _buildLoginCard(),

                  const SizedBox(height: 24),

                  // ── Footer ──
                  _buildFooter(),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoSection(Size size) {
    return Column(
      children: [
        // Animated glowing emblem
        ScaleTransition(
          scale: _pulseAnimation,
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                colors: [gold, saffron, deepSaffron],
                stops: [0.3, 0.7, 1.0],
              ),
              boxShadow: [
                BoxShadow(
                  color: gold.withOpacity(0.6),
                  blurRadius: 28,
                  spreadRadius: 4,
                ),
                BoxShadow(
                  color: saffron.withOpacity(0.4),
                  blurRadius: 50,
                  spreadRadius: 10,
                ),
              ],
              border: Border.all(color: gold, width: 3),
            ),
            child: const Icon(Icons.account_balance, size: 52, color: darkNavy),
          ),
        ),

        const SizedBox(height: 16),

        // App name — bold political style
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [gold, white, gold],
          ).createShader(bounds),
          child: const Text(
            "CORPORATOR APP",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 4,
            ),
          ),
        ),

        const SizedBox(height: 6),

        // Subtitle
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: saffron, width: 3),
              right: BorderSide(color: saffron, width: 3),
            ),
          ),
          child: const Text(
            "जनता की सेवा • नागरिकों का विकास",
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFFFFD580),
              fontStyle: FontStyle.italic,
              letterSpacing: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTaglineBanner() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: const [saffron, Color(0xFFFF8C00), deepSaffron],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: saffron.withOpacity(0.5),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.star, color: Colors.white, size: 16),
              SizedBox(width: 8),
              Text(
                "SEVA • VIKAS • SAMARPAN",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 3,
                ),
              ),
              SizedBox(width: 8),
              Icon(Icons.star, color: Colors.white, size: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLoginCard() {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: saffron.withOpacity(0.15),
            blurRadius: 16,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          // Card header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [darkNavy, navyBlue]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Column(
              children: [
                const Text(
                  "OFFICIAL LOGIN PORTAL",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: gold,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  height: 2,
                  width: 80,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, gold, Colors.transparent],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Form fields
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                _buildField(
                  controller: emailController,
                  label: "Email / Username",
                  hint: "Enter your official email",
                  icon: Icons.person_outline,
                  keyboardType: TextInputType.emailAddress,
                ),

                const SizedBox(height: 16),

                _buildField(
                  controller: passwordController,
                  label: "Password",
                  hint: "Enter your password",
                  icon: Icons.lock_outline,
                  obscure: true,
                ),

                const SizedBox(height: 10),

                // Forgot password
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {
                      
                    },
                    // onPressed: () => Navigator.push(
                    //   context,
                    //   MaterialPageRoute(
                    //     builder: (_) => const ForgotPasswordPage(),
                    //   ),
                    // ),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                    ),
                    child: const Text(
                      "Forgot Password?",
                      style: TextStyle(
                        color: ashoka,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Login Button — full saffron CTA
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : loginUser,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
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
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [
                          BoxShadow(
                            color: saffron.withOpacity(0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Container(
                        alignment: Alignment.center,
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.login,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    "SECURE LOGIN",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.5,
                                    ),
                                  ),
                                ],
                              ),
                      ),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
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
          obscureText: obscure ? isPasswordHidden : false,
          keyboardType: keyboardType,
          style: const TextStyle(
            fontSize: 15,
            color: darkNavy,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: Icon(icon, color: saffron, size: 22),
            suffixIcon: obscure
                ? IconButton(
                    icon: Icon(
                      isPasswordHidden
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: () =>
                        setState(() => isPasswordHidden = !isPasswordHidden),
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF7F5EF),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: saffron, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        // Tricolor divider
        Row(
          children: [
            Expanded(child: Container(height: 3, color: saffron)),
            Expanded(child: Container(height: 3, color: white)),
            Expanded(
              child: Container(height: 3, color: const Color(0xFF138808)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user, color: gold.withOpacity(0.7), size: 14),
            const SizedBox(width: 6),
            Text(
              "Authorised Government Portal  •  Secure & Encrypted",
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 11,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          "© 2025 Corporator Portal. All Rights Reserved.",
          style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10),
        ),
      ],
    );
  }
}

// ── Custom painter for Ashoka Chakra inspired background pattern ──
class _ChakraPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Large concentric circles (chakra-like)
    final centers = [
      Offset(size.width * 0.85, size.height * 0.12),
      Offset(size.width * 0.1, size.height * 0.75),
    ];

    for (final center in centers) {
      for (int r = 20; r <= 180; r += 22) {
        canvas.drawCircle(center, r.toDouble(), paint);
      }
      // Spokes
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

    // Subtle diagonal lines
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