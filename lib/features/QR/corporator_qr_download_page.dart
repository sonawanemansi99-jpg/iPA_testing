import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

class CorporatorQRDownloadPage extends StatefulWidget {
  const CorporatorQRDownloadPage({super.key});

  @override
  State<CorporatorQRDownloadPage> createState() =>
      _CorporatorQRDownloadPageState();
}

class _CorporatorQRDownloadPageState extends State<CorporatorQRDownloadPage>
    with TickerProviderStateMixin {
  final GlobalKey qrKey = GlobalKey();

  String? corporatorId;
  String? url;

  bool _isDownloading = false;

  late AnimationController _pulseController;
  late AnimationController _shimmerController;
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
    generateQR();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // ── BACKEND LOGIC UNTOUCHED ──
  void generateQR() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      corporatorId = user.uid;
      url = "https://elegant-kelpie-5bc1d7.netlify.app/?corporatorId=$corporatorId";
      setState(() {});
    }
  }

  Future<void> downloadQR() async {
    setState(() => _isDownloading = true);
    try {
      RenderRepaintBoundary boundary =
          qrKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 3);
      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final file = File("${directory.path}/corporator_${corporatorId}_qr.png");
      await file.writeAsBytes(pngBytes);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "QR saved at:\n${file.path}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: saffron,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red.shade800,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isDownloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Loading state
    if (url == null) {
      return Scaffold(
        body: Stack(
          children: [
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
            Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
            const Center(
              child: CircularProgressIndicator(color: gold),
            ),
          ],
        ),
      );
    }

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
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: gold.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new,
                              color: gold, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [gold, white, gold],
                        ).createShader(bounds),
                        child: const Text(
                          "CORPORATOR QR",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 3,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 40,
                          height: 40,
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
                          child: const Icon(Icons.qr_code_2,
                              size: 20, color: darkNavy),
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
                          "SCAN TO REGISTER COMPLAINT",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.star, color: Colors.white, size: 13),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // ── QR Card ──
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    color: white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: gold.withOpacity(0.5), width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 32,
                        offset: const Offset(0, 12),
                      ),
                      BoxShadow(
                        color: saffron.withOpacity(0.15),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Card header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: const BoxDecoration(
                          gradient:
                              LinearGradient(colors: [darkNavy, navyBlue]),
                          borderRadius: BorderRadius.vertical(
                              top: Radius.circular(18)),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              "OFFICIAL QR CODE",
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
                                  colors: [
                                    Colors.transparent,
                                    gold,
                                    Colors.transparent
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // QR code
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // QR with gold border frame
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: gold.withOpacity(0.6), width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: gold.withOpacity(0.2),
                                    blurRadius: 16,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: RepaintBoundary(
                                key: qrKey,
                                child: QrImageView(
                                  data: url!,
                                  size: 220,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Corporator ID label
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7F5EF),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: Colors.grey.shade300, width: 1),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.fingerprint,
                                      color: saffron, size: 16),
                                  const SizedBox(width: 6),
                                  Text(
                                    "ID: ${corporatorId?.substring(0, 12)}...",
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: navyBlue,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // ── Download Button ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _isDownloading ? null : downloadQR,
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: _isDownloading
                              ? null
                              : const LinearGradient(
                                  colors: [saffron, deepSaffron],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                          color: _isDownloading ? Colors.grey.shade500 : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: _isDownloading
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
                          child: _isDownloading
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
                                    Icon(Icons.download_rounded,
                                        color: Colors.white, size: 22),
                                    SizedBox(width: 10),
                                    Text(
                                      "DOWNLOAD QR",
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
                ),

                const SizedBox(height: 20),

                // ── Tricolor footer ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    children: [
                      Expanded(child: Container(height: 3, color: saffron)),
                      Expanded(child: Container(height: 3, color: white)),
                      Expanded(
                          child: Container(
                              height: 3, color: const Color(0xFF138808))),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  "© 2025 Corporator Portal. All Rights Reserved.",
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 10),
                ),
                const SizedBox(height: 20),
              ],
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