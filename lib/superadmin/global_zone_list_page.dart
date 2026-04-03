import 'package:corporator_app/services/super_admin_services.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class GlobalZoneListPage extends StatefulWidget {
  const GlobalZoneListPage({Key? key}) : super(key: key);

  @override
  State<GlobalZoneListPage> createState() => _GlobalZoneListPageState();
}

class _GlobalZoneListPageState extends State<GlobalZoneListPage> with TickerProviderStateMixin {
  final SuperAdminService _superAdminServices = SuperAdminService();

  List<dynamic> _allZones = [];
  List<dynamic> _filteredZones = [];
  bool _isLoading = true;
  String _searchQuery = "";

  // Stats
  int _totalAreas = 0;
  int _unassignedCount = 0;

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  // Theme Colors
  static const saffron = Color(0xFFFF6700);
  static const gold = Color(0xFFFFD700);
  static const navyBlue = Color(0xFF002868);
  static const darkNavy = Color(0xFF001A45);
  static const warmWhite = Color(0xFFFFFDF7);
  static const dangerRed = Color(0xFFCC2200);

  @override
  void initState() {
    super.initState();
    _fetchZones();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> _fetchZones() async {
    setState(() => _isLoading = true);
    try {
      final data = await _superAdminServices.getAllGlobalZones();
      
      int areasCount = 0;
      int unassigned = 0;
      
      for(var zone in data) {
        areasCount += (zone['areas'] as List).length;
        if(zone['zoneSevakId'] == null) unassigned++;
      }

      setState(() {
        _allZones = data;
        _filteredZones = data;
        _totalAreas = areasCount;
        _unassignedCount = unassigned;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterZones(String query) {
    setState(() {
      _searchQuery = query;
      _filteredZones = _allZones.where((zone) {
        final zoneName = (zone['name'] ?? '').toLowerCase();
        final adminName = (zone['adminName'] ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        return zoneName.contains(searchLower) || adminName.contains(searchLower);
      }).toList();
    });
  }

  Future<void> _deleteZone(int zoneId, String zoneName) async {
    final bool? confirm = await _showDeleteConfirmation(zoneName);
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _superAdminServices.deleteZone(zoneId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Zone deleted successfully."), backgroundColor: Colors.green));
      _fetchZones();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<bool?> _showDeleteConfirmation(String zoneName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: warmWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: dangerRed, size: 28),
            SizedBox(width: 10),
            Text("Delete Zone?", style: TextStyle(color: darkNavy, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text("Are you sure you want to permanently delete '$zoneName'? This action cannot be undone and will orphan all associated areas.", style: const TextStyle(color: Colors.black87, height: 1.4)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: dangerRed, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("DELETE PERMANENTLY", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: dangerRed));
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
                  Text("संपूर्ण ज़ोन सूची", style: TextStyle(color: Color(0xFFFFD580), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  Text("GLOBAL ZONES", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ])),
                ScaleTransition(scale: pulse,
                  child: GestureDetector(
                    onTap: _fetchZones,
                    child: Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const LinearGradient(colors: [saffron, Color(0xFFE55C00)]), boxShadow: [BoxShadow(color: saffron.withOpacity(0.5), blurRadius: 10)], border: Border.all(color: gold, width: 1.5)), child: const Icon(Icons.refresh, color: Colors.white, size: 20)),
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
            
            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _filterZones,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search by Zone or Admin Name...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search, color: gold),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),

            if (_isLoading)
              Expanded(child: const Center(child: CircularProgressIndicator(color: gold)))
            else if (_filteredZones.isEmpty)
              const Expanded(child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.map_outlined, color: Colors.white24, size: 72),
                  SizedBox(height: 16),
                  Text("No zones found", style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w700)),
                ]),
              ))
            else
              Expanded(
                child: Column(
                  children: [
                    _buildStatsRow(),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        itemCount: _filteredZones.length,
                        itemBuilder: (context, index) => _buildZoneCard(_filteredZones[index]),
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

  Widget _buildStatsRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(
        children: [
          Expanded(child: _statMiniCard("ZONES", _allZones.length.toString(), gold)),
          const SizedBox(width: 10),
          Expanded(child: _statMiniCard("AREAS", _totalAreas.toString(), Colors.blueAccent)),
          const SizedBox(width: 10),
          Expanded(child: _statMiniCard("UNASSIGNED", _unassignedCount.toString(), _unassignedCount > 0 ? dangerRed : Colors.green)),
        ],
      ),
    );
  }

  Widget _statMiniCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildZoneCard(Map<String, dynamic> zone) {
    final int zoneId = zone['id'];
    final String name = zone['name'] ?? 'Unknown Zone';
    final String adminName = zone['adminName'] ?? 'Unknown Admin';
    final String sevakName = zone['zoneSevakName'] ?? 'UNASSIGNED';
    final bool isUnassigned = sevakName == 'UNASSIGNED';
    final int areaCount = (zone['areas'] as List?)?.length ?? 0;

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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkNavy)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings, size: 14, color: saffron),
                                  const SizedBox(width: 6),
                                  Text(adminName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.blueGrey)),
                                ],
                              )
                            ],
                          ),
                        ),
                        // Delete Button
                        GestureDetector(
                          onTap: () => _deleteZone(zoneId, name),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: dangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.delete_outline, color: dangerRed, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: saffron.withOpacity(0.2)),
                    const SizedBox(height: 12),
                    
                    _infoTile(Icons.person_outline, "ASSIGNED SEVAK", sevakName, isHighlight: isUnassigned),
                    const SizedBox(height: 8),
                    _infoTile(Icons.location_city, "AREAS REGISTERED", "$areaCount Areas"),
                  ],
                ),
              ),
            ),
            Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 6, color: isUnassigned ? dangerRed : Colors.green)),
          ],
        ),
      ),
    );
  }

  Widget _infoTile(IconData icon, String label, String value, {bool isHighlight = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: saffron, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF888888), fontWeight: FontWeight.w700, letterSpacing: 1)),
              Text(value, style: TextStyle(fontSize: 14, color: isHighlight ? dangerRed : darkNavy, fontWeight: FontWeight.w800)),
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
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}