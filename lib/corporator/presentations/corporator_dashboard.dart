import 'package:corporator_app/core/widgets/gradient.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/corporator/presentations/zone_sevak_list_page.dart';
import 'package:corporator_app/corporator/presentations/corporator_complaints_page.dart';
import 'package:corporator_app/corporator/presentations/create_zone_page.dart';
import 'package:corporator_app/corporator/presentations/zone_list_page.dart';
import 'package:corporator_app/corporator/presentations/zone_sevak_registration_page.dart';
import 'package:corporator_app/features/auth/presentation/login.dart';
// 👇 Added the QR Download Page import
import 'package:corporator_app/features/QR/corporator_qr_download_page.dart';
import 'package:corporator_app/landing_page.dart';
import 'package:corporator_app/services/admin_services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class CorporatorDashboard extends StatefulWidget {
  const CorporatorDashboard({super.key});

  @override
  State<CorporatorDashboard> createState() => _CorporatorDashboardState();

  static Widget _statTile({required String title, required String count}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        gradient: AppGradients.darkGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CorporatorDashboardState extends State<CorporatorDashboard>
    with TickerProviderStateMixin {
  
  // ── SPRING BOOT SERVICE REPLACES FIREBASE ──
  final AdminServices _corporatorServices = AdminServices();

  Map<String, dynamic>? _adminProfile;
  bool _isLoadingProfile = true;
  String? _profileError;

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  AnimationController? _shimmerController;

  static const saffron = Color(0xFFFF6700);
  static const deepSaffron = Color(0xFFE55C00);
  static const gold = Color(0xFFFFD700);
  static const navyBlue = Color(0xFF002868);
  static const darkNavy = Color(0xFF001A45);
  static const warmWhite = Color(0xFFFFFDF7);
  static const indiaGreen = Color(0xFF138808);

  @override
  void initState() {
    super.initState();
    _fetchProfileData();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    _shimmerController?.dispose();
    super.dispose();
  }

  // Elevate the profile fetch so the whole dashboard knows if it's active
  Future<void> _fetchProfileData() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });
    try {
      final data = await _corporatorServices.getCorporatorProfile();
      if (mounted) {
        setState(() {
          _adminProfile = data;
          _isLoadingProfile = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _profileError = e.toString().replaceAll("Exception: ", "");
          _isLoadingProfile = false;
        });
      }
    }
  }

  void adminList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ZoneSevakListPage()),
    );
  }

  void _logout() async {
    await _corporatorServices.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LandingPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> pulse =
        _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

    // Default to true to prevent accidental lockouts if data is missing, 
    // but correctly lock down if backend explicitly returns false.
    final bool isActive = _adminProfile?['isActive'] ?? true;

    return MainScaffold(
      title: "Dashboard",
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkNavy, navyBlue, Color(0xFF003A8C)],
            stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: CustomPaint(painter: _ChakraPatternPainter()),
            ),
            Column(
              children: [
                // Saffron top strip
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [saffron, gold, saffron]),
                  ),
                ),

                Expanded(
                  child: _isLoadingProfile 
                    ? const Center(child: CircularProgressIndicator(color: saffron))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── Corporator Profile Card ──
                            _buildProfileCard(pulse, isActive),

                            const SizedBox(height: 20),

                            // ── Seva Slogan Banner ──
                            _buildSloganBanner(isActive),

                            const SizedBox(height: 24),

                            // ── CONDITIONAL RENDERING FOR SUSPENDED ADMINS ──
                            if (isActive) ...[
                              _buildSectionLabel(
                                "प्रशासन पैनल",
                                "ADMINISTRATION PANEL",
                              ),
                              const SizedBox(height: 14),

                              _buildActionButton(
                                icon: Icons.admin_panel_settings,
                                hindi: "सभी ज़ोन सेवक देखें",
                                english: "VIEW ALL ZONE SEVAKS",
                                color: navyBlue,
                                accentColor: gold,
                                onTap: adminList,
                              ),
                              const SizedBox(height: 12),

                              _buildActionButton(
                                icon: Icons.person_add_alt_1,
                                hindi: "नया ज़ोन सेवक जोड़ें",
                                english: "ADD NEW ZONE SEVAK",
                                color: saffron,
                                accentColor: Colors.white,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ZoneSevakRegistrationPage()),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildActionButton(
                                icon: Icons.list_alt_outlined,
                                hindi: "शिकायतें देखें",
                                english: "VIEW COMPLAINTS",
                                color: const Color(0xFF1A6FAB), 
                                accentColor: Colors.white,
                                onTap: () async {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CorporatorComplaintsPage()),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildActionButton(
                                icon: Icons.map_outlined,
                                hindi: "सभी ज़ोन देखें",
                                english: "VIEW ALL ZONES",
                                color: indiaGreen,
                                accentColor: Colors.white,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const ZoneListPage()),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildActionButton(
                                icon: Icons.add_location_alt_outlined,
                                hindi: "नया ज़ोन बनाएं",
                                english: "CREATE NEW ZONE",
                                color: const Color(0xFF004B87), 
                                accentColor: Colors.white,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CreateZonePage()),
                                  );
                                },
                              ),
                              const SizedBox(height: 12),

                              // 👇 NEW: QR Download Button
                              _buildActionButton(
                                icon: Icons.qr_code_2,
                                hindi: "क्यूआर कोड डाउनलोड करें",
                                english: "DOWNLOAD QR CODE",
                                color: Colors.teal.shade700, // Distinct utility color
                                accentColor: Colors.white,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CorporatorQRDownloadPage()),
                                  );
                                },
                              ),
                            ] else ...[
                              // ── LOCKED STATE UI ──
                              _buildSuspendedNotice(),
                            ],

                            const SizedBox(height: 28),

                            // ── Footer tricolor ──
                            Row(
                              children: [
                                Expanded(child: Container(height: 3, color: saffron)),
                                Expanded(child: Container(height: 3, color: warmWhite)),
                                Expanded(child: Container(height: 3, color: indiaGreen)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Center(
                              child: Text(
                                "© 2025 Corporator Portal  •  जनसेवा सर्वोपरि",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.35),
                                  fontSize: 10,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuspendedNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.red[900]?.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.6), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.15),
            blurRadius: 15,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        children: [
          const Icon(Icons.lock_person, color: Colors.redAccent, size: 52),
          const SizedBox(height: 16),
          const Text(
            "ACCESS REVOKED",
            style: TextStyle(
              color: Colors.redAccent,
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            "Your administrative privileges have been suspended by the System Administrator. You can no longer view or manage zones, complaints, or zone sevaks.",
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout, color: Colors.white, size: 18),
            label: const Text("SIGN OUT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[800],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildProfileCard(Animation<double> pulse, bool isActive) {
    if (_profileError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 40),
              const SizedBox(height: 8),
              Text(_profileError!, style: const TextStyle(color: Colors.red, fontSize: 12), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    final name = _adminProfile?['name'] ?? 'Unknown Name';
    final email = _adminProfile?['email'] ?? 'Unknown Email';
    final mobileNo = _adminProfile?['mobileNumber'] ?? 'Unknown Mobile'; 

    return ScaleTransition(
      scale: pulse,
      child: Container(
        decoration: BoxDecoration(
          color: warmWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: (isActive ? gold : Colors.red).withOpacity(0.3),
              blurRadius: 24,
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              // Gold/Red header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isActive ? [darkNavy, navyBlue] : [Colors.red[900]!, Colors.red[700]!]
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isActive ? "CORPORATOR PROFILE" : "ACCOUNT SUSPENDED",
                      style: const TextStyle(
                        color: gold,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.5,
                      ),
                    ),
                    Container(
                      width: 40,
                      height: 2,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, gold],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Profile content
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar with ring based on status
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: isActive ? [gold, saffron] : [Colors.red, Colors.red[900]!],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isActive ? gold : Colors.red).withOpacity(0.5),
                            blurRadius: 16,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: darkNavy,
                        size: 38,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name with shimmer-style gradient
                          ShaderMask(
                            shaderCallback: (b) => LinearGradient(
                              colors: isActive ? [darkNavy, navyBlue] : [Colors.red[900]!, Colors.red],
                            ).createShader(b),
                            child: Text(
                              name,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          _profileDetail(Icons.email_outlined, email),
                          const SizedBox(height: 4),
                          _profileDetail(Icons.phone_outlined, mobileNo),
                          const SizedBox(height: 8),
                          
                          // Rank badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isActive ? [saffron, deepSaffron] : [Colors.red, Colors.red[800]!],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isActive ? "✦  CORPORATOR" : "✖  SUSPENDED",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // ── STYLED LOGOUT ICON BUTTON ──
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent, size: 28),
                      onPressed: _logout,
                      tooltip: "Secure Logout",
                      splashRadius: 24,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileDetail(IconData icon, String value) {
    return Row(
      children: [
        Icon(icon, color: saffron, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Color(0xFF444444),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildSloganBanner(bool isActive) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isActive ? [saffron, deepSaffron] : [Colors.red[800]!, Colors.red[900]!]
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: (isActive ? saffron : Colors.red).withOpacity(0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isActive ? Icons.star : Icons.warning_amber_rounded, color: Colors.white, size: 14),
          const SizedBox(width: 10),
          Text(
            isActive ? "सेवा • विकास • समर्पण" : "ACCESS RESTRICTED",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 2.5,
            ),
          ),
          const SizedBox(width: 10),
          Icon(isActive ? Icons.star : Icons.warning_amber_rounded, color: Colors.white, size: 14),
        ],
      ),
    );
  }

  Widget _buildSectionLabel(String hindi, String english) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          color: saffron,
          margin: const EdgeInsets.only(right: 10),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              hindi,
              style: const TextStyle(
                color: Color(0xFFFFD580),
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            Text(
              english,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String hindi,
    required String english,
    required Color color,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.45),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: accentColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hindi,
                    style: TextStyle(
                      color: accentColor.withOpacity(0.75),
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
                  ),
                  Text(
                    english,
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: accentColor.withOpacity(0.5),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChakraPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.025)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final centers = [
      Offset(size.width * 0.88, size.height * 0.06),
      Offset(size.width * 0.05, size.height * 0.45),
      Offset(size.width * 0.7, size.height * 0.88),
    ];
    for (final c in centers) {
      for (int r = 20; r <= 160; r += 20) canvas.drawCircle(c, r.toDouble(), p);
      final sp = Paint()
        ..color = Colors.white.withOpacity(0.03)
        ..strokeWidth = 1;
      for (int i = 0; i < 24; i++) {
        final a = (i * math.pi * 2) / 24;
        canvas.drawLine(
          c,
          Offset(c.dx + math.cos(a) * 160, c.dy + math.sin(a) * 160),
          sp,
        );
      }
    }
    final lp = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 40)
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}