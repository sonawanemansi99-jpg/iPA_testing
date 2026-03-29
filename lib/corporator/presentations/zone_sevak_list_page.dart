import 'package:corporator_app/corporator/presentations/edit_zone_sevak_page.dart';
import 'package:corporator_app/services/zone_sevak_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ZoneSevakListPage extends StatefulWidget {
  const ZoneSevakListPage({super.key});

  @override
  State<ZoneSevakListPage> createState() => _ZoneSevakListPageState();
}

class _ZoneSevakListPageState extends State<ZoneSevakListPage>
    with TickerProviderStateMixin {
  final ZoneSevakService _zoneSevakService = ZoneSevakService();
  late Future<List<Map<String, dynamic>>> _sevaksFuture;

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  static const saffron = Color(0xFFFF6700);
  static const deepSaffron = Color(0xFFE55C00);
  static const gold = Color(0xFFFFD700);
  static const navyBlue = Color(0xFF002868);
  static const darkNavy = Color(0xFF001A45);
  static const warmWhite = Color(0xFFFFFDF7);
  static const indiaGreen = Color(0xFF138808);
  static const ashoka = Color(0xFF1A6FAB);

  @override
  void initState() {
    super.initState();
    _loadSevaks();
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

  void _loadSevaks() {
    _sevaksFuture = _zoneSevakService.fetchMyZoneSevaks();
  }

  Future<void> _refreshSevaks() async {
    setState(() {
      _loadSevaks();
    });
  }

  Color _sevakColor(int index) {
    const colors = [
      saffron,
      ashoka,
      indiaGreen,
      Color(0xFF6B21A8),
      Color(0xFFB45309),
    ];
    return colors[index % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> pulse =
        _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

    return Scaffold(
      backgroundColor: darkNavy,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [darkNavy, navyBlue]),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "ज़ोन सेवक सूची",
                          style: TextStyle(
                            color: Color(0xFFFFD580),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          "ZONE SEVAK DIRECTORY",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ScaleTransition(
                    scale: pulse,
                    child: GestureDetector(
                      onTap: _refreshSevaks,
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [saffron, deepSaffron],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: saffron.withOpacity(0.5),
                              blurRadius: 10,
                            ),
                          ],
                          border: Border.all(color: gold, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [saffron, gold, saffron]),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<Map<String, dynamic>>>(
                    future: _sevaksFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const RadialGradient(
                                    colors: [gold, saffron],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: gold.withOpacity(0.4),
                                      blurRadius: 20,
                                    ),
                                  ],
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(16),
                                  child: CircularProgressIndicator(
                                    color: darkNavy,
                                    strokeWidth: 3,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                "लोड हो रहा है...",
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(
                                Icons.people_outline,
                                color: Colors.white24,
                                size: 72,
                              ),
                              SizedBox(height: 16),
                              Text(
                                "कोई सेवक नहीं मिला",
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "No Zone Sevaks found",
                                style: TextStyle(
                                  color: Colors.white30,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final sevaks = snapshot.data!;

                      return Column(
                        children: [
                          _buildCountBanner(sevaks.length),
                          Expanded(
                            child: ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: sevaks.length,
                              itemBuilder: (context, index) {
                                final sevak = sevaks[index];
                                return _buildSevakCard(sevak, index);
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountBanner(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: gold.withOpacity(0.25), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(colors: [gold, saffron]),
              boxShadow: [
                BoxShadow(color: gold.withOpacity(0.4), blurRadius: 10),
              ],
            ),
            child: const Icon(Icons.badge, color: darkNavy, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "REGISTERED SEVAKS",
                  style: TextStyle(
                    color: gold,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  "$count सेवक कार्यरत हैं",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [saffron, deepSaffron]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(color: saffron.withOpacity(0.4), blurRadius: 8),
              ],
            ),
            child: Text(
              "$count TOTAL",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSevakCard(Map<String, dynamic> sevak, int index) {
    // ── Safe JSON Extraction based on Spring Boot DTO ──
    final name = sevak['name'] ?? 'No Name';
    final nickname = sevak['nickname'] ?? '';
    final email = sevak['email'] ?? 'No Email';
    final mobile = sevak['mobileNumber'] ?? 'No Mobile';
    final photoUrl = sevak['livePhotoUrl']?.toString();

    // Safely extract zone IDs (shows count of assigned zones)
    final List<dynamic> zoneIds = sevak['zoneIds'] ?? [];
    final locationText = zoneIds.isNotEmpty
        ? "${zoneIds.length} Zones Assigned"
        : "No Zones Assigned";

    final accentColor = _sevakColor(index);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Container(
              color: warmWhite,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar circle (Uses Live Photo if available)
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor, width: 2),
                            image: photoUrl != null && photoUrl.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(photoUrl),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            gradient: photoUrl == null || photoUrl.isEmpty
                                ? RadialGradient(
                                    colors: [
                                      accentColor.withOpacity(0.3),
                                      accentColor.withOpacity(0.1),
                                    ],
                                  )
                                : null,
                          ),
                          child: photoUrl == null || photoUrl.isEmpty
                              ? Center(
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : "Z",
                                    style: TextStyle(
                                      color: accentColor,
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                  color: darkNavy,
                                ),
                              ),
                              Text(
                                nickname.isNotEmpty
                                    ? "ZONE SEVAK ($nickname)"
                                    : "ZONE SEVAK",
                                style: TextStyle(
                                  color: accentColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () async {
                            // 1. Navigate to the Edit Page and pass the specific sevak data
                            final bool? wasUpdated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditZoneSevakPage(sevak: sevak),
                              ),
                            );

                            // 2. If the user successfully updated and popped back with 'true', refresh the list
                            if (wasUpdated == true) {
                              _refreshSevaks();
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.all(9),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [navyBlue, darkNavy],
                              ),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: navyBlue.withOpacity(0.4),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.edit_outlined,
                              color: gold,
                              size: 16,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),
                    Container(
                      height: 1,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            accentColor.withOpacity(0.5),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    _infoTile(Icons.email_outlined, "EMAIL", email),
                    const SizedBox(height: 6),
                    _infoTile(Icons.phone_outlined, "MOBILE", mobile),
                    const SizedBox(height: 6),
                    _infoTile(
                      Icons.location_on_outlined,
                      "ASSIGNMENT",
                      locationText,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 6, color: accentColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: saffron, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: Color(0xFF888888),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  color: darkNavy,
                  fontWeight: FontWeight.w700,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
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
      Offset(size.width * 0.05, size.height * 0.5),
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
