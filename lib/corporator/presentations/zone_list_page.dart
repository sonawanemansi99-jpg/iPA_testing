import 'package:corporator_app/corporator/presentations/edit_zone_page.dart';
import 'package:corporator_app/services/complaint_service.dart';
import 'package:corporator_app/services/zone_service.dart';
import 'package:corporator_app/services/zone_sevak_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class ZoneListPage extends StatefulWidget {
  const ZoneListPage({super.key});

  @override
  State<ZoneListPage> createState() => _ZoneListPageState();
}

class _ZoneListPageState extends State<ZoneListPage> with TickerProviderStateMixin {
  final ZoneService _zoneService = ZoneService();
  final ZoneSevakService _sevakService = ZoneSevakService();
  final ComplaintService _complaintService = ComplaintService();

  bool _isLoading = true;
  String? _error;
  
  List<Map<String, dynamic>> _zones = [];
  Map<int, String> _sevakNames = {};
  Map<String, int> _zoneComplaintCounts = {};

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  static const saffron = Color(0xFFFF6700);
  static const deepSaffron = Color(0xFFE55C00);
  static const gold = Color(0xFFFFD700);
  static const navyBlue = Color(0xFF002868);
  static const darkNavy = Color(0xFF001A45);
  static const warmWhite = Color(0xFFFFFDF7);
  static const indiaGreen = Color(0xFF138808);
  static const dangerRed = Color(0xFFCC2200);

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      // Fetch everything concurrently for maximum speed
      final results = await Future.wait([
        _zoneService.fetchMyZones(),
        _sevakService.fetchMyZoneSevaks(),
        _complaintService.fetchComplaints(),
      ]);

      final zones = results[0] as List<Map<String, dynamic>>;
      final sevaks = results[1] as List<Map<String, dynamic>>;
      final complaints = results[2] as List<Map<String, dynamic>>;

      // Map Sevak IDs to their Names for easy lookup
      final Map<int, String> sevakMap = {};
      for (var s in sevaks) {
        sevakMap[s['id']] = s['name'] ?? 'Unknown Sevak';
      }

      // Count Complaints per Zone
      final Map<String, int> complaintMap = {};
      for (var c in complaints) {
        final zName = c['zoneName']?.toString();
        if (zName != null) {
          complaintMap[zName] = (complaintMap[zName] ?? 0) + 1;
        }
      }

      if (mounted) {
        setState(() {
          _zones = zones;
          _sevakNames = sevakMap;
          _zoneComplaintCounts = complaintMap;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> pulse = _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

    return Scaffold(
      backgroundColor: darkNavy,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(gradient: LinearGradient(colors: [darkNavy, navyBlue]), boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))]),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.15))), child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text("ज़ोन सूची", style: TextStyle(color: Color(0xFFFFD580), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  Text("ZONE DIRECTORY", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ])),
                ScaleTransition(scale: pulse,
                  child: GestureDetector(
                    onTap: _loadDashboardData,
                    child: Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [saffron, deepSaffron]), boxShadow: [BoxShadow(color: saffron.withOpacity(0.5), blurRadius: 10)], border: Border.all(color: gold, width: 1.5)), child: const Icon(Icons.refresh, color: Colors.white, size: 20)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [darkNavy, navyBlue, Color(0xFF003A8C)], stops: [0.0, 0.4, 1.0])),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
          Column(children: [
            Container(height: 4, decoration: const BoxDecoration(gradient: LinearGradient(colors: [saffron, gold, saffron]))),
            
            if (_isLoading)
              Expanded(child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 64, height: 64, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [gold, saffron]), boxShadow: [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 20)]), child: const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: darkNavy, strokeWidth: 3))),
                    const SizedBox(height: 16),
                    const Text("लोड हो रहा है...", style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1)),
                  ],
                ),
              ))
            else if (_error != null)
              Expanded(child: Center(
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.error_outline, color: Colors.red.shade400, size: 52),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: Colors.white70, fontSize: 14), textAlign: TextAlign.center),
                ]),
              ))
            else if (_zones.isEmpty)
              const Expanded(child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.map_outlined, color: Colors.white24, size: 72),
                  SizedBox(height: 16),
                  Text("कोई ज़ोन नहीं मिला", style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w700)),
                  SizedBox(height: 4),
                  Text("No zones found", style: TextStyle(color: Colors.white30, fontSize: 13)),
                ]),
              ))
            else
              Expanded(
                child: Column(
                  children: [
                    _buildCountBanner(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _zones.length,
                        itemBuilder: (context, index) => _buildZoneCard(_zones[index], index),
                      ),
                    ),
                  ],
                ),
              ),
          ]),
        ]),
      ),
    );
  }

  Widget _buildCountBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: gold.withOpacity(0.25), width: 1)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [gold, saffron]), boxShadow: [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 10)]), child: const Icon(Icons.map, color: darkNavy, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("REGISTERED ZONES", style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            Text("${_zones.length} ज़ोन प्रबंधित हैं", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          ])),
        ],
      ),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone, int index) {
    final name = zone['name'] ?? 'Unknown Zone';
    final sevakId = zone['zoneSevakId'];
    final sevakName = sevakId != null ? _sevakNames[sevakId] ?? 'Unknown Sevak' : 'UNASSIGNED';
    
    final List<dynamic> areas = zone['areas'] ?? [];
    final complaintCount = _zoneComplaintCounts[name] ?? 0;

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
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: navyBlue, borderRadius: BorderRadius.circular(8)),
                          child: Text("Z-${index + 1}", style: const TextStyle(color: gold, fontWeight: FontWeight.w900, fontSize: 12)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: darkNavy)),
                        ),
                        GestureDetector(
                          onTap: () async {
                            final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => EditZonePage(zone: zone, availableSevaks: _sevakNames)));
                            if (result == true) _loadDashboardData();
                          },
                          child: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(gradient: const LinearGradient(colors: [navyBlue, darkNavy]), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: navyBlue.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 3))]), child: const Icon(Icons.edit_outlined, color: gold, size: 16)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: saffron.withOpacity(0.2)),
                    const SizedBox(height: 12),
                    
                    _infoTile(Icons.person_outline, "ASSIGNED SEVAK", sevakName, isHighlight: sevakId == null),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _infoTile(Icons.location_city, "AREAS", "${areas.length} Registered")),
                        Expanded(child: _infoTile(Icons.report_problem_outlined, "COMPLAINTS", "$complaintCount Total", isHighlight: complaintCount > 0)),
                      ],
                    )
                  ],
                ),
              ),
            ),
            Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 6, color: sevakId == null ? dangerRed : indiaGreen)),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: saffron, size: 14),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF888888), fontWeight: FontWeight.w700, letterSpacing: 1)),
              Text(value, style: TextStyle(fontSize: 13, color: isHighlight ? dangerRed : darkNavy, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
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
    final p = Paint()..color = Colors.white.withOpacity(0.025)..style = PaintingStyle.stroke..strokeWidth = 1;
    final centers = [Offset(size.width * 0.9, size.height * 0.05), Offset(size.width * 0.08, size.height * 0.6)];
    for (final c in centers) {
      for (int r = 20; r <= 160; r += 20) canvas.drawCircle(c, r.toDouble(), p);
      final sp = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1;
      for (int i = 0; i < 24; i++) {
        final a = (i * math.pi * 2) / 24;
        canvas.drawLine(c, Offset(c.dx + math.cos(a) * 160, c.dy + math.sin(a) * 160), sp);
      }
    }
    final lp = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 40) canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}