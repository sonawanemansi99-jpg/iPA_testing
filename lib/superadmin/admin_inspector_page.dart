import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/admin/corporator_complaints_page.dart';
import 'package:corporator_app/admin/zone_list_page.dart';
import 'package:corporator_app/admin/zone_sevak_list_page.dart';
import 'package:corporator_app/services/super_admin_services.dart';
import 'package:corporator_app/superadmin/edit_admin_page.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AdminInspectorPage extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const AdminInspectorPage({Key? key, required this.adminData}) : super(key: key);

  @override
  State<AdminInspectorPage> createState() => _AdminInspectorPageState();
}

class _AdminInspectorPageState extends State<AdminInspectorPage> with TickerProviderStateMixin {
  final SuperAdminService _superAdminServices = SuperAdminService();
  
  bool _isLoading = true;
  late bool _isActive;
  
  // ── Track current data in state to reflect edits ──
  late Map<String, dynamic> _currentAdminData;

  int totalZones = 0;
  int totalSevaks = 0;
  int totalComplaints = 0;

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  // Theme Colors
  static const saffron = Color(0xFFFF6700);
  static const gold = Color(0xFFFFD700);
  static const navyBlue = Color(0xFF002868);
  static const darkNavy = Color(0xFF001A45);
  static const warmWhite = Color(0xFFFFFDF7);
  static const indiaGreen = Color(0xFF138808);

  @override
  void initState() {
    super.initState();
    // Initialize state with data passed from list
    _currentAdminData = widget.adminData;
    _isActive = _currentAdminData['isActive'] ?? false;
    
    _fetchAdminSpecificStats();

    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController?.dispose();
    super.dispose();
  }

  // ── REFRESH LOGIC: Fetches both counts AND the latest profile details ──
  Future<void> _fetchAdminSpecificStats() async {
    setState(() => _isLoading = true);
    final adminId = _currentAdminData['adminId'];
    
    try {
      // Fire requests concurrently for performance
      final results = await Future.wait([
        _superAdminServices.getAdminSpecificZones(adminId),
        _superAdminServices.getAdminSpecificComplaints(adminId),
        _superAdminServices.getAdminSpecificSevaks(adminId),
        _superAdminServices.getAdminById(adminId), // Re-fetch profile to catch edits
      ]);

      if (mounted) {
        setState(() {
          totalZones = (results[0] as List).length;
          totalComplaints = (results[1] as List).length;
          totalSevaks = (results[2] as List).length;
          
          // Update the local state with the freshest backend data
          _currentAdminData = results[3] as Map<String, dynamic>;
          _isActive = _currentAdminData['isActive'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching inspector data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAccountStatus() async {
    final bool newStatus = !_isActive;
    setState(() => _isActive = newStatus); 

    try {
      await _superAdminServices.toggleAdminStatus(_currentAdminData['adminId'], newStatus);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(newStatus ? "Account Activated" : "Account Suspended"), 
          backgroundColor: newStatus ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
        )
      );
    } catch (e) {
      setState(() => _isActive = !newStatus); 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating)
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> pulse = _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

    return MainScaffold(
      title: "Inspector View",
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [darkNavy, navyBlue, Color(0xFF003A8C)], stops: [0.0, 0.4, 1.0],
          ),
        ),
        child: Stack(
          children: [
            Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
            Column(
              children: [
                Container(height: 4, decoration: const BoxDecoration(gradient: LinearGradient(colors: [saffron, gold, saffron]))),
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: gold))
                    : RefreshIndicator(
                        onRefresh: _fetchAdminSpecificStats,
                        color: gold, backgroundColor: darkNavy,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileCard(pulse),
                              const SizedBox(height: 24),
                              _buildStatsRow(),
                              const SizedBox(height: 28),
                              _buildSectionLabel("प्रशासन नियंत्रण", "ADMINISTRATION CONTROL"),
                              const SizedBox(height: 14),

                              _buildActionButton(
                                icon: Icons.map_outlined, hindi: "प्रशासक के ज़ोन देखें", english: "VIEW ADMIN'S ZONES",
                                color: indiaGreen, accentColor: Colors.white,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ZoneListPage(adminId: _currentAdminData['adminId'])));
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildActionButton(
                                icon: Icons.engineering, hindi: "प्रशासक के सेवक देखें", english: "VIEW ADMIN'S SEVAKS",
                                color: const Color(0xFF004B87), accentColor: Colors.white,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => ZoneSevakListPage(adminId: _currentAdminData['adminId'])));
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildActionButton(
                                icon: Icons.list_alt_outlined, hindi: "प्रशासक की शिकायतें देखें", english: "VIEW ADMIN'S COMPLAINTS",
                                color: const Color(0xFF1A6FAB), accentColor: Colors.white,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => CorporatorComplaintsPage(adminId: _currentAdminData['adminId'])));
                                },
                              ),
                            ],
                          ),
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

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard("ZONES", totalZones.toString(), indiaGreen)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("SEVAKS", totalSevaks.toString(), gold)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("ISSUES", totalComplaints.toString(), saffron)),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: warmWhite.withOpacity(0.05), borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Text(count, style: TextStyle(color: accentColor, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildProfileCard(Animation<double> pulse) {
    // ── Use local state data ──
    final admin = _currentAdminData;
    final String photoUrl = admin['livePhotoUrl'] ?? '';
    final String adminName = admin['name'] ?? 'Unknown Admin';
    final String email = admin['email'] ?? 'N/A';
    final String mobile = admin['mobileNumber'] ?? 'N/A';
    final String groupName = admin['adminGroupName'] ?? 'Unassigned Group';

    return ScaleTransition(
      scale: pulse,
      child: Container(
        decoration: BoxDecoration(
          color: warmWhite, borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                decoration: BoxDecoration(gradient: LinearGradient(colors: _isActive ? [darkNavy, navyBlue] : [Colors.red[900]!, Colors.red[700]!])),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_isActive ? "INSPECTING ADMIN" : "ACCOUNT SUSPENDED", style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
                    Row(
                      children: [
                        IconButton(
                          tooltip: "Edit Corporator Details",
                          icon: const Icon(Icons.edit_note, color: Colors.white, size: 26),
                          onPressed: () async {
                            final bool? updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditAdminPage(adminData: _currentAdminData),
                              ),
                            );
                            if (updated == true) _fetchAdminSpecificStats(); // Refresh NAME/EMAIL on return
                          },
                        ),
                        Transform.scale(
                          scale: 0.8,
                          child: Switch(
                            value: _isActive, 
                            activeColor: gold, 
                            inactiveThumbColor: Colors.white, 
                            inactiveTrackColor: Colors.red[300], 
                            onChanged: (val) => _toggleAccountStatus()
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 76, height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, 
                        border: Border.all(color: _isActive ? gold : Colors.red, width: 2.5), 
                        image: photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                        color: darkNavy.withOpacity(0.05),
                      ),
                      child: photoUrl.isEmpty ? const Icon(Icons.person, color: darkNavy, size: 40) : null,
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(adminName, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: darkNavy, letterSpacing: 0.5)),
                          const SizedBox(height: 6),
                          _profileDetail(Icons.email_outlined, email),
                          const SizedBox(height: 3),
                          _profileDetail(Icons.phone_outlined, mobile),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: navyBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(6), border: Border.all(color: navyBlue.withOpacity(0.2))),
                            child: Text(groupName.toUpperCase(), style: const TextStyle(color: navyBlue, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
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
      ),
    );
  }

  Widget _profileDetail(IconData icon, String value) {
    return Row(children: [Icon(icon, color: saffron, size: 13), const SizedBox(width: 6), Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF444444), fontSize: 13, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis))]);
  }

  Widget _buildSectionLabel(String hindi, String english) {
    return Row(
      children: [
        Container(width: 4, height: 22, color: saffron, margin: const EdgeInsets.only(right: 10)),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(hindi, style: const TextStyle(color: Color(0xFFFFD580), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
          Text(english, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
        ]),
      ],
    );
  }

  Widget _buildActionButton({required IconData icon, required String hindi, required String english, required Color color, required Color accentColor, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight), 
          borderRadius: BorderRadius.circular(14), 
          border: Border.all(color: accentColor.withOpacity(0.25), width: 1), 
          boxShadow: [BoxShadow(color: color.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 5))]
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46, 
              decoration: BoxDecoration(color: accentColor.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: accentColor.withOpacity(0.3), width: 1)), 
              child: Icon(icon, color: accentColor, size: 24)
            ),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(hindi, style: TextStyle(color: accentColor.withOpacity(0.75), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)), Text(english, style: TextStyle(color: accentColor, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5))])),
            Icon(Icons.arrow_forward_ios, color: accentColor.withOpacity(0.5), size: 16),
          ],
        ),
      ),
    );
  }
}

class _ChakraPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.025)..style = PaintingStyle.stroke..strokeWidth = 1;
    final centers = [Offset(size.width * 0.88, size.height * 0.06), Offset(size.width * 0.05, size.height * 0.45), Offset(size.width * 0.7, size.height * 0.88)];
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