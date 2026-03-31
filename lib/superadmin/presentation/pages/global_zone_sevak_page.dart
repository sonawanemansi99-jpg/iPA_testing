import 'package:corporator_app/services/super_admin_services.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class GlobalSevakListPage extends StatefulWidget {
  const GlobalSevakListPage({Key? key}) : super(key: key);

  @override
  State<GlobalSevakListPage> createState() => _GlobalSevakListPageState();
}

class _GlobalSevakListPageState extends State<GlobalSevakListPage> with TickerProviderStateMixin {
  final SuperAdminService _superAdminServices = SuperAdminService();

  List<dynamic> _allSevaks = [];
  List<dynamic> _filteredSevaks = [];
  bool _isLoading = true;
  String _searchQuery = "";

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
    _fetchSevaks();
    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> _fetchSevaks() async {
    setState(() => _isLoading = true);
    try {
      final data = await _superAdminServices.getAllGlobalSevaks();
      setState(() {
        _allSevaks = data;
        _filteredSevaks = data;
      });
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterSevaks(String query) {
    setState(() {
      _searchQuery = query;
      _filteredSevaks = _allSevaks.where((sevak) {
        final sevakName = (sevak['name'] ?? '').toLowerCase();
        final adminName = (sevak['adminName'] ?? '').toLowerCase();
        final email = (sevak['email'] ?? '').toLowerCase();
        final phone = (sevak['mobileNumber'] ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        
        return sevakName.contains(searchLower) || 
               adminName.contains(searchLower) || 
               email.contains(searchLower) || 
               phone.contains(searchLower);
      }).toList();
    });
  }

  Future<void> _deleteSevak(int sevakId, String sevakName) async {
    final bool? confirm = await _showDeleteConfirmation(sevakName);
    if (confirm != true) return;

    setState(() => _isLoading = true);
    try {
      await _superAdminServices.deleteZoneSevak(sevakId);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Sevak deleted successfully."), backgroundColor: Colors.green));
      _fetchSevaks();
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(e.toString());
    }
  }

  Future<bool?> _showDeleteConfirmation(String sevakName) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: warmWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: dangerRed, size: 28),
            SizedBox(width: 10),
            Text("Delete Sevak?", style: TextStyle(color: darkNavy, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text("Are you sure you want to permanently delete '$sevakName'? This will unassign them from all their active zones.", style: const TextStyle(color: Colors.black87, height: 1.4)),
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
                  Text("संपूर्ण सेवक सूची", style: TextStyle(color: Color(0xFFFFD580), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  Text("GLOBAL SEVAKS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ])),
                ScaleTransition(scale: pulse,
                  child: GestureDetector(
                    onTap: _fetchSevaks,
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
                onChanged: _filterSevaks,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search Name, Admin, Phone, Email...",
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
            else if (_filteredSevaks.isEmpty)
              const Expanded(child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.engineering, color: Colors.white24, size: 72),
                  SizedBox(height: 16),
                  Text("No Sevaks found", style: TextStyle(color: Colors.white54, fontSize: 16, fontWeight: FontWeight.w700)),
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
                        itemCount: _filteredSevaks.length,
                        itemBuilder: (context, index) => _buildSevakCard(_filteredSevaks[index], index),
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
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.07), borderRadius: BorderRadius.circular(12), border: Border.all(color: gold.withOpacity(0.25), width: 1)),
      child: Row(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [gold, saffron]), boxShadow: [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 10)]), child: const Icon(Icons.engineering, color: darkNavy, size: 20)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("TOTAL DIRECTORY", style: TextStyle(color: gold, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
            Text("${_allSevaks.length} Sevaks Registered", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
          ])),
        ],
      ),
    );
  }

  Color _sevakColor(int index) {
    const colors = [saffron, Color(0xFF1A6FAB), Color(0xFF138808), Color(0xFF6B21A8), Color(0xFFB45309)];
    return colors[index % colors.length];
  }

  Widget _buildSevakCard(Map<String, dynamic> sevak, int index) {
    final int sevakId = sevak['id'] ?? sevak['zoneSevakId'] ?? 0;
    final String name = sevak['name'] ?? 'Unknown Name';
    final String adminName = sevak['adminName'] ?? 'SYSTEM';
    final String email = sevak['email'] ?? 'N/A';
    final String phone = sevak['mobileNumber'] ?? 'N/A';
    final String photoUrl = sevak['livePhotoUrl']?.toString() ?? '';
    
    final List<dynamic> zoneIds = sevak['zoneIds'] ?? [];
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 46, height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: accentColor, width: 2),
                            image: photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                            gradient: photoUrl.isEmpty ? RadialGradient(colors: [accentColor.withOpacity(0.3), accentColor.withOpacity(0.1)]) : null,
                          ),
                          child: photoUrl.isEmpty ? Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : "S", style: TextStyle(color: accentColor, fontSize: 20, fontWeight: FontWeight.w900))) : null,
                        ),
                        const SizedBox(width: 12),
                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: darkNavy)),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.admin_panel_settings, size: 12, color: saffron),
                                  const SizedBox(width: 4),
                                  Expanded(child: Text(adminName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.blueGrey), overflow: TextOverflow.ellipsis)),
                                ],
                              )
                            ],
                          ),
                        ),
                        // Delete Button
                        GestureDetector(
                          onTap: () => _deleteSevak(sevakId, name),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: dangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.person_remove_alt_1, color: dangerRed, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(height: 1, color: accentColor.withOpacity(0.3)),
                    const SizedBox(height: 12),
                    
                    Row(
                      children: [
                        Expanded(child: _infoTile(Icons.email_outlined, "EMAIL", email)),
                        Expanded(child: _infoTile(Icons.phone_outlined, "MOBILE", phone)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _infoTile(Icons.location_on_outlined, "ASSIGNMENT", "${zoneIds.length} Zones Assigned"),
                  ],
                ),
              ),
            ),
            Positioned(left: 0, top: 0, bottom: 0, child: Container(width: 6, color: accentColor)),
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
              Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF888888), fontWeight: FontWeight.w700, letterSpacing: 1)),
              Text(value, style: const TextStyle(fontSize: 12, color: darkNavy, fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
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