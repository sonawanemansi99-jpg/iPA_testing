// import 'package:corporator_app/core/constants/constants.dart';
// import 'package:corporator_app/core/widgets/main_scaffold.dart';
// import 'package:corporator_app/landing_page.dart';
// import 'package:corporator_app/superadmin/presentation/pages/admin_list_page.dart';
// import 'package:corporator_app/superadmin/presentation/pages/global_complaints_page.dart';
// import 'package:corporator_app/superadmin/presentation/pages/global_zone_list_page.dart';
// import 'package:corporator_app/superadmin/presentation/pages/global_zone_sevak_page.dart';
// import 'package:corporator_app/superadmin/presentation/pages/register_corporator.dart';
// import 'package:corporator_app/superadmin/presentation/pages/register_super_admin_page.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'dart:convert';
// import 'dart:math' as math;
// import 'package:http/http.dart' as http;

// class SuperAdminDashboard extends StatefulWidget {
//   const SuperAdminDashboard({Key? key}) : super(key: key);

//   @override
//   State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
// }

// class _SuperAdminDashboardState extends State<SuperAdminDashboard>
//     with TickerProviderStateMixin {
//   final _storage = const FlutterSecureStorage();

//   bool _isLoading = true;
//   int totalAdmins = 0;
//   int totalZones = 0;
//   int totalComplaints = 0;

//   AnimationController? _pulseController;
//   Animation<double>? _pulseAnimation;
//   AnimationController? _shimmerController;

//   // Theme Colors
//   static const saffron = Color(0xFFFF6700);
//   static const deepSaffron = Color(0xFFE55C00);
//   static const gold = Color(0xFFFFD700);
//   static const navyBlue = Color(0xFF002868);
//   static const darkNavy = Color(0xFF001A45);
//   static const warmWhite = Color(0xFFFFFDF7);
//   static const indiaGreen = Color(0xFF138808);

//   @override
//   void initState() {
//     super.initState();
//     _fetchGlobalStats();

//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1600),
//     )..repeat(reverse: true);

//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
//       CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
//     );

//     _shimmerController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat();
//   }

//   @override
//   void dispose() {
//     _pulseController?.dispose();
//     _shimmerController?.dispose();
//     super.dispose();
//   }

//   Future<void> _fetchGlobalStats() async {
//     setState(() => _isLoading = true);
//     try {
//       final String? token = await _storage.read(key: 'jwt_token');
//       final headers = {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $token',
//         'ngrok-skip-browser-warning': '69420',
//       };

//       // Fetch Zones
//       final zoneRes = await http.get(
//         Uri.parse('${Constants.ngrokBaseUrl}/zones'),
//         headers: headers,
//       );
//       if (zoneRes.statusCode == 200) {
//         final zoneData = jsonDecode(zoneRes.body);
//         totalZones = (zoneData['data'] as List).length;
//       }

//       // Fetch Complaints
//       final compRes = await http.get(
//         Uri.parse('${Constants.ngrokBaseUrl}/complaints'),
//         headers: headers,
//       );
//       if (compRes.statusCode == 200) {
//         final compData = jsonDecode(compRes.body);
//         totalComplaints = (compData['data'] as List).length;
//       }

//       // Fetch Admins
//       final adminRes = await http.get(
//         Uri.parse('${Constants.ngrokBaseUrl}/admins'),
//         headers: headers,
//       );
//       if (adminRes.statusCode == 200) {
//         final adminData = jsonDecode(adminRes.body);
//         totalAdmins = (adminData['data'] as List).length;
//       }
//     } catch (e) {
//       debugPrint("Error fetching stats: $e");
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   void _logout() async {
//     await _storage.delete(key: 'jwt_token');
//     await _storage.delete(key: 'user_role');
//     if (!mounted) return;
//     Navigator.of(
//       context,
//     ).pushReplacement(MaterialPageRoute(builder: (_) => const LandingPage()));
//   }

//   @override
//   Widget build(BuildContext context) {
//     final Animation<double> pulse =
//         _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

//     return MainScaffold(
//       title: "Command Center",
//       body: Container(
//         decoration: const BoxDecoration(
//           gradient: LinearGradient(
//             begin: Alignment.topCenter,
//             end: Alignment.bottomCenter,
//             colors: [darkNavy, navyBlue, Color(0xFF003A8C)],
//             stops: [0.0, 0.4, 1.0],
//           ),
//         ),
//         child: Stack(
//           children: [
//             Positioned.fill(
//               child: CustomPaint(painter: _ChakraPatternPainter()),
//             ),
//             Column(
//               children: [
//                 // Saffron top strip
//                 Container(
//                   height: 4,
//                   decoration: const BoxDecoration(
//                     gradient: LinearGradient(colors: [saffron, gold, saffron]),
//                   ),
//                 ),

//                 Expanded(
//                   child: _isLoading
//                       ? const Center(
//                           child: CircularProgressIndicator(color: gold),
//                         )
//                       : RefreshIndicator(
//                           onRefresh: _fetchGlobalStats,
//                           color: gold,
//                           backgroundColor: darkNavy,
//                           child: SingleChildScrollView(
//                             physics: const AlwaysScrollableScrollPhysics(),
//                             padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 // ── Super Admin Profile Card ──
//                                 _buildProfileCard(pulse),
//                                 const SizedBox(height: 20),

//                                 // ── Seva Slogan Banner ──
//                                 // _buildSloganBanner(),
//                                 // const SizedBox(height: 24),

//                                 // ── Global Stats Row ──
//                                 _buildGlobalStatsRow(),
//                                 const SizedBox(height: 24),

//                                 // ── Section Label ──
//                                 _buildSectionLabel(
//                                   "वैश्विक प्रशासन",
//                                   "GLOBAL ADMINISTRATION",
//                                 ),
//                                 const SizedBox(height: 14),

//                                 // ── Action Buttons ──

//                                 // 1. View All Admins
//                                 _buildActionButton(
//                                   icon: Icons.admin_panel_settings,
//                                   hindi: "सभी एडमिन देखें",
//                                   english: "VIEW ALL ADMINS",
//                                   color: navyBlue,
//                                   accentColor: gold,
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) => const AdminListPage(),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                                 const SizedBox(height: 12),

//                                 // 2. Add New Admin
//                                 _buildActionButton(
//                                   icon: Icons.person_add_alt_1,
//                                   hindi: "नया एडमिन जोड़ें",
//                                   english: "ADD NEW ADMIN",
//                                   color: saffron,
//                                   accentColor: Colors.white,
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) =>
//                                             const CorporatorRegistrationPage(),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                                 const SizedBox(height: 12),

//                                 // 3. View Global Zones
//                                 _buildActionButton(
//                                   icon: Icons.map_outlined,
//                                   hindi: "सभी ज़ोन देखें",
//                                   english: "VIEW GLOBAL ZONES",
//                                   color: indiaGreen,
//                                   accentColor: Colors.white,
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) =>
//                                             const GlobalZoneListPage(),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                                 const SizedBox(height: 12),

//                                 // 4. View Global Complaints
//                                 _buildActionButton(
//                                   icon: Icons.list_alt_outlined,
//                                   hindi: "सभी शिकायतें देखें",
//                                   english: "VIEW ALL COMPLAINTS",
//                                   color: const Color(0xFF1A6FAB),
//                                   accentColor: Colors.white,
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) =>
//                                             const GlobalComplaintsPage(),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                                 const SizedBox(height: 12),

//                                 // 5. Global Zone Sevaks
//                                 _buildActionButton(
//                                   icon: Icons.engineering,
//                                   hindi: "सभी ज़ोन सेवक देखें",
//                                   english: "VIEW GLOBAL SEVAKS",
//                                   color: const Color(0xFF004B87),
//                                   accentColor: Colors.white,
//                                   onTap: () {
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) =>
//                                             const GlobalSevakListPage(),
//                                       ),
//                                     );
//                                   },
//                                 ),

//                                 const SizedBox(height: 12),

//                                 _buildActionButton(
//                                   icon: Icons
//                                       .security, // Shield icon for highest privilege
//                                   hindi: "नया सुपर एडमिन बनाएं",
//                                   english: "ADD NEW SUPER ADMIN",
//                                   color: Colors.deepPurple.shade700,
//                                   accentColor: Colors.white,
//                                   onTap: () {
//                                     // 👇 Replace the comment with this!
//                                     Navigator.push(
//                                       context,
//                                       MaterialPageRoute(
//                                         builder: (_) =>
//                                             const RegisterSuperAdminPage(),
//                                       ),
//                                     );
//                                   },
//                                 ),

//                                 const SizedBox(height: 28),

//                                 // ── Footer tricolor ──
//                                 Row(
//                                   children: [
//                                     Expanded(
//                                       child: Container(
//                                         height: 3,
//                                         color: saffron,
//                                       ),
//                                     ),
//                                     Expanded(
//                                       child: Container(
//                                         height: 3,
//                                         color: warmWhite,
//                                       ),
//                                     ),
//                                     Expanded(
//                                       child: Container(
//                                         height: 3,
//                                         color: indiaGreen,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 10),
//                                 Center(
//                                   child: Text(
//                                     "© 2025 Super Admin Portal  •  जनसेवा सर्वोपरि",
//                                     style: TextStyle(
//                                       color: Colors.white.withOpacity(0.35),
//                                       fontSize: 10,
//                                       letterSpacing: 0.5,
//                                     ),
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                 ),
//               ],
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   // ─── THEMED GLOBAL STATS ───
//   Widget _buildGlobalStatsRow() {
//     return Row(
//       children: [
//         Expanded(child: _buildStatCard("ADMINS", totalAdmins.toString(), gold)),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _buildStatCard("ZONES", totalZones.toString(), indiaGreen),
//         ),
//         const SizedBox(width: 12),
//         Expanded(
//           child: _buildStatCard("ISSUES", totalComplaints.toString(), saffron),
//         ),
//       ],
//     );
//   }

//   Widget _buildStatCard(String title, String count, Color accentColor) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 16),
//       decoration: BoxDecoration(
//         color: warmWhite.withOpacity(0.05),
//         borderRadius: BorderRadius.circular(14),
//         border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.2),
//             blurRadius: 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             count,
//             style: TextStyle(
//               color: accentColor,
//               fontSize: 28,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 4),
//           Text(
//             title,
//             style: const TextStyle(
//               color: Colors.white70,
//               fontSize: 10,
//               fontWeight: FontWeight.w700,
//               letterSpacing: 1.5,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ─── PROFILE CARD ───
//   Widget _buildProfileCard(Animation<double> pulse) {
//     return ScaleTransition(
//       scale: pulse,
//       child: Container(
//         decoration: BoxDecoration(
//           color: warmWhite,
//           borderRadius: BorderRadius.circular(20),
//           boxShadow: [
//             BoxShadow(
//               color: gold.withOpacity(0.3),
//               blurRadius: 24,
//               spreadRadius: 2,
//             ),
//             BoxShadow(
//               color: Colors.black.withOpacity(0.3),
//               blurRadius: 16,
//               offset: const Offset(0, 8),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: BorderRadius.circular(20),
//           child: Column(
//             children: [
//               // Gold header
//               Container(
//                 width: double.infinity,
//                 padding: const EdgeInsets.symmetric(
//                   vertical: 10,
//                   horizontal: 16,
//                 ),
//                 decoration: const BoxDecoration(
//                   gradient: LinearGradient(colors: [darkNavy, navyBlue]),
//                 ),
//                 child: Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     const Text(
//                       "SUPER ADMIN PROFILE",
//                       style: TextStyle(
//                         color: gold,
//                         fontSize: 11,
//                         fontWeight: FontWeight.w900,
//                         letterSpacing: 2.5,
//                       ),
//                     ),
//                     Container(
//                       width: 40,
//                       height: 2,
//                       decoration: const BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [Colors.transparent, gold],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               // Profile Content (Static for Super Admin based on Seeder)
//               Padding(
//                 padding: const EdgeInsets.all(18),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.center,
//                   children: [
//                     Container(
//                       width: 72,
//                       height: 72,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         gradient: const RadialGradient(colors: [gold, saffron]),
//                         boxShadow: [
//                           BoxShadow(
//                             color: gold.withOpacity(0.5),
//                             blurRadius: 16,
//                           ),
//                         ],
//                       ),
//                       child: const Icon(
//                         Icons.admin_panel_settings,
//                         color: darkNavy,
//                         size: 38,
//                       ),
//                     ),
//                     const SizedBox(width: 16),
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           ShaderMask(
//                             shaderCallback: (b) => const LinearGradient(
//                               colors: [darkNavy, navyBlue],
//                             ).createShader(b),
//                             child: const Text(
//                               "System Administrator",
//                               style: TextStyle(
//                                 fontSize: 18,
//                                 fontWeight: FontWeight.w900,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                           const SizedBox(height: 8),
//                           _profileDetail(Icons.email_outlined, "admin@oit.com"),
//                           const SizedBox(height: 4),
//                           _profileDetail(
//                             Icons.phone_outlined,
//                             "+91 99999 99999",
//                           ),
//                           const SizedBox(height: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(
//                               horizontal: 10,
//                               vertical: 4,
//                             ),
//                             decoration: BoxDecoration(
//                               gradient: const LinearGradient(
//                                 colors: [saffron, deepSaffron],
//                               ),
//                               borderRadius: BorderRadius.circular(6),
//                             ),
//                             child: const Text(
//                               "✦  GLOBAL ADMIN",
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 10,
//                                 fontWeight: FontWeight.w900,
//                                 letterSpacing: 2,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//                     IconButton(
//                       icon: const Icon(Icons.logout, color: Colors.redAccent),
//                       onPressed: _logout,
//                       tooltip: "Logout",
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _profileDetail(IconData icon, String value) {
//     return Row(
//       children: [
//         Icon(icon, color: saffron, size: 13),
//         const SizedBox(width: 6),
//         Expanded(
//           child: Text(
//             value,
//             style: const TextStyle(
//               color: Color(0xFF444444),
//               fontSize: 13,
//               fontWeight: FontWeight.w500,
//             ),
//             overflow: TextOverflow.ellipsis,
//           ),
//         ),
//       ],
//     );
//   }

//   Widget _buildSloganBanner() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
//       decoration: BoxDecoration(
//         gradient: const LinearGradient(colors: [saffron, deepSaffron]),
//         borderRadius: BorderRadius.circular(10),
//         boxShadow: [
//           BoxShadow(
//             color: saffron.withOpacity(0.45),
//             blurRadius: 14,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: const [
//           Icon(Icons.star, color: Colors.white, size: 14),
//           SizedBox(width: 10),
//           Text(
//             "सेवा • विकास • संपूर्ण नियंत्रण", // Changed to "Total Control" for Super Admin
//             style: TextStyle(
//               color: Colors.white,
//               fontWeight: FontWeight.w900,
//               fontSize: 15,
//               letterSpacing: 2.5,
//             ),
//           ),
//           SizedBox(width: 10),
//           Icon(Icons.star, color: Colors.white, size: 14),
//         ],
//       ),
//     );
//   }

//   Widget _buildSectionLabel(String hindi, String english) {
//     return Row(
//       children: [
//         Container(
//           width: 4,
//           height: 22,
//           color: saffron,
//           margin: const EdgeInsets.only(right: 10),
//         ),
//         Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               hindi,
//               style: const TextStyle(
//                 color: Color(0xFFFFD580),
//                 fontSize: 10,
//                 fontWeight: FontWeight.w700,
//                 letterSpacing: 1.5,
//               ),
//             ),
//             Text(
//               english,
//               style: const TextStyle(
//                 color: Colors.white,
//                 fontSize: 14,
//                 fontWeight: FontWeight.w900,
//                 letterSpacing: 2,
//               ),
//             ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildActionButton({
//     required IconData icon,
//     required String hindi,
//     required String english,
//     required Color color,
//     required Color accentColor,
//     required VoidCallback onTap,
//   }) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
//         decoration: BoxDecoration(
//           gradient: LinearGradient(
//             colors: [color, color.withOpacity(0.75)],
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//           ),
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
//           boxShadow: [
//             BoxShadow(
//               color: color.withOpacity(0.45),
//               blurRadius: 14,
//               offset: const Offset(0, 5),
//             ),
//           ],
//         ),
//         child: Row(
//           children: [
//             Container(
//               width: 46,
//               height: 46,
//               decoration: BoxDecoration(
//                 color: accentColor.withOpacity(0.15),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(
//                   color: accentColor.withOpacity(0.3),
//                   width: 1,
//                 ),
//               ),
//               child: Icon(icon, color: accentColor, size: 24),
//             ),
//             const SizedBox(width: 16),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     hindi,
//                     style: TextStyle(
//                       color: accentColor.withOpacity(0.75),
//                       fontSize: 10,
//                       fontWeight: FontWeight.w600,
//                       letterSpacing: 1,
//                     ),
//                   ),
//                   Text(
//                     english,
//                     style: TextStyle(
//                       color: accentColor,
//                       fontSize: 15,
//                       fontWeight: FontWeight.w900,
//                       letterSpacing: 1.5,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             Icon(
//               Icons.arrow_forward_ios,
//               color: accentColor.withOpacity(0.5),
//               size: 16,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _ChakraPatternPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final p = Paint()
//       ..color = Colors.white.withOpacity(0.025)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1;
//     final centers = [
//       Offset(size.width * 0.88, size.height * 0.06),
//       Offset(size.width * 0.05, size.height * 0.45),
//       Offset(size.width * 0.7, size.height * 0.88),
//     ];
//     for (final c in centers) {
//       for (int r = 20; r <= 160; r += 20) canvas.drawCircle(c, r.toDouble(), p);
//       final sp = Paint()
//         ..color = Colors.white.withOpacity(0.03)
//         ..strokeWidth = 1;
//       for (int i = 0; i < 24; i++) {
//         final a = (i * math.pi * 2) / 24;
//         canvas.drawLine(
//           c,
//           Offset(c.dx + math.cos(a) * 160, c.dy + math.sin(a) * 160),
//           sp,
//         );
//       }
//     }
//     final lp = Paint()
//       ..color = Colors.white.withOpacity(0.02)
//       ..strokeWidth = 1;
//     for (double x = -size.height; x < size.width + size.height; x += 40)
//       canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter _) => false;
// }


import 'package:corporator_app/core/constants/constants.dart';
import 'package:corporator_app/core/widgets/custom_snack_bar.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/landing_page.dart';
import 'package:corporator_app/superadmin/presentation/pages/admin_list_page.dart';
import 'package:corporator_app/superadmin/presentation/pages/global_complaints_page.dart';
import 'package:corporator_app/superadmin/presentation/pages/global_zone_list_page.dart';
import 'package:corporator_app/superadmin/presentation/pages/global_zone_sevak_page.dart';
import 'package:corporator_app/superadmin/presentation/pages/super_admin_list_page.dart';
// We temporarily remove the direct Register imports from here because they belong in the List pages now!
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:http/http.dart' as http;

class SuperAdminDashboard extends StatefulWidget {
  const SuperAdminDashboard({Key? key}) : super(key: key);

  @override
  State<SuperAdminDashboard> createState() => _SuperAdminDashboardState();
}

class _SuperAdminDashboardState extends State<SuperAdminDashboard> with TickerProviderStateMixin {
  final _storage = const FlutterSecureStorage();
  
  bool _isLoading = true;
  int totalAdmins = 0;
  int totalZones = 0;
  int totalComplaints = 0;

  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  // Theme Colors
  static const saffron = Color(0xFFFF6700);
  static const deepSaffron = Color(0xFFE55C00);
  static const gold = Color(0xFFFFD700);
  static const navyBlue = Color(0xFF002868);
  static const darkNavy = Color(0xFF001A45);
  static const warmWhite = Color(0xFFFFFDF7);
  static const indiaGreen = Color(0xFF138808);
  static const rootPurple = Color(0xFF512DA8);

  @override
  void initState() {
    super.initState();
    _fetchGlobalStats();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
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

  Future<void> _fetchGlobalStats() async {
    setState(() => _isLoading = true);
    try {
      final String? token = await _storage.read(key: 'jwt_token');
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'ngrok-skip-browser-warning': '69420',
      };
      
      // Fetch Zones
      final zoneRes = await http.get(Uri.parse('${Constants.ngrokBaseUrl}/zones'), headers: headers);
      if (zoneRes.statusCode == 200) totalZones = (jsonDecode(zoneRes.body)['data'] as List).length;

      // Fetch Complaints
      final compRes = await http.get(Uri.parse('${Constants.ngrokBaseUrl}/complaints'), headers: headers);
      if (compRes.statusCode == 200) totalComplaints = (jsonDecode(compRes.body)['data'] as List).length;

      // Fetch Admins
      final adminRes = await http.get(Uri.parse('${Constants.ngrokBaseUrl}/admins'), headers: headers);
      if (adminRes.statusCode == 200) totalAdmins = (jsonDecode(adminRes.body)['data'] as List).length;

    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, "Failed to sync stats: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_role');
    if (!mounted) return;
    CustomSnackBar.showInfo(context, "Logged out of Super Admin Portal.");
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_)=>const LandingPage()));
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> pulse = _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

    return MainScaffold(
      title: "Command Center",
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
            Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
            Column(
              children: [
                Container(height: 4, decoration: const BoxDecoration(gradient: LinearGradient(colors: [saffron, gold, saffron]))),
                
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: gold))
                    : RefreshIndicator(
                        onRefresh: _fetchGlobalStats,
                        color: gold,
                        backgroundColor: darkNavy,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildProfileCard(pulse),
                              const SizedBox(height: 20),
                              
                              _buildGlobalStatsRow(),
                              const SizedBox(height: 30),

                              // ── SECTION 1: PERSONNEL MANAGEMENT ──
                              _buildSectionLabel("कार्मिक प्रबंधन", "PERSONNEL MANAGEMENT"),
                              const SizedBox(height: 14),

                              _buildActionButton(
                                icon: Icons.security,
                                hindi: "सुपर एडमिन प्रबंधित करें",
                                english: "SUPER ADMINS",
                                color: rootPurple,
                                accentColor: Colors.white,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const SuperAdminListPage()));
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildActionButton(
                                icon: Icons.admin_panel_settings,
                                hindi: "एडमिन प्रबंधित करें",
                                english: "CORPORATORS (ADMINS)",
                                color: navyBlue,
                                accentColor: gold,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => AdminListPage()));
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildActionButton(
                                icon: Icons.engineering,
                                hindi: "ज़ोन सेवक प्रबंधित करें",
                                english: "ZONE SEVAKS",
                                color: const Color(0xFF004B87), 
                                accentColor: Colors.white,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalSevakListPage()));
                                },
                              ),

                              const SizedBox(height: 30),

                              // ── SECTION 2: CITY OPERATIONS ──
                              _buildSectionLabel("शहर संचालन", "CITY OPERATIONS"),
                              const SizedBox(height: 14),

                              _buildActionButton(
                                icon: Icons.map_outlined,
                                hindi: "वैश्विक ज़ोन देखें",
                                english: "GLOBAL ZONES",
                                color: indiaGreen,
                                accentColor: Colors.white,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalZoneListPage()));
                                },
                              ),
                              const SizedBox(height: 12),

                              _buildActionButton(
                                icon: Icons.list_alt_outlined,
                                hindi: "वैश्विक शिकायतें",
                                english: "GLOBAL COMPLAINTS",
                                color: const Color(0xFF1A6FAB), 
                                accentColor: Colors.white,
                                onTap: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const GlobalComplaintsPage()));
                                },
                              ),
                              
                              const SizedBox(height: 32),

                              // ── Footer ──
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
                                  "© 2025 Super Admin Portal  •  जनसेवा सर्वोपरि",
                                  style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 10, letterSpacing: 0.5),
                                ),
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

  Widget _buildGlobalStatsRow() {
    return Row(
      children: [
        Expanded(child: _buildStatCard("ADMINS", totalAdmins.toString(), gold)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("ZONES", totalZones.toString(), indiaGreen)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard("ISSUES", totalComplaints.toString(), saffron)),
      ],
    );
  }

  Widget _buildStatCard(String title, String count, Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: warmWhite.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
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
    return ScaleTransition(
      scale: pulse,
      child: Container(
        decoration: BoxDecoration(
          color: warmWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: gold.withOpacity(0.3), blurRadius: 24, spreadRadius: 2),
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [darkNavy, navyBlue])),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("SUPER ADMIN PROFILE", style: TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
                    Container(width: 40, height: 2, decoration: const BoxDecoration(gradient: LinearGradient(colors: [Colors.transparent, gold]))),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(colors: [gold, saffron]),
                        boxShadow: [BoxShadow(color: gold.withOpacity(0.5), blurRadius: 16)],
                      ),
                      child: const Icon(Icons.admin_panel_settings, color: darkNavy, size: 38),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ShaderMask(
                            shaderCallback: (b) => const LinearGradient(colors: [darkNavy, navyBlue]).createShader(b),
                            child: const Text("System Administrator", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                          const SizedBox(height: 8),
                          _profileDetail(Icons.email_outlined, "admin@oit.com"),
                          const SizedBox(height: 4),
                          _profileDetail(Icons.phone_outlined, "+91 99999 99999"),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(gradient: const LinearGradient(colors: [saffron, deepSaffron]), borderRadius: BorderRadius.circular(6)),
                            child: const Text("✦  ROOT ACCESS", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          ),
                        ],
                      ),
                    ),
                    IconButton(icon: const Icon(Icons.logout, color: Colors.redAccent), onPressed: _logout, tooltip: "Logout")
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
        Expanded(child: Text(value, style: const TextStyle(color: Color(0xFF444444), fontSize: 13, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildSectionLabel(String hindi, String english) {
    return Row(
      children: [
        Container(width: 4, height: 22, color: saffron, margin: const EdgeInsets.only(right: 10)),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(hindi, style: const TextStyle(color: Color(0xFFFFD580), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
            Text(english, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon, required String hindi, required String english,
    required Color color, required Color accentColor, required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.75)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accentColor.withOpacity(0.25), width: 1),
          boxShadow: [BoxShadow(color: color.withOpacity(0.45), blurRadius: 14, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: accentColor.withOpacity(0.3), width: 1),
              ),
              child: Icon(icon, color: accentColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hindi, style: TextStyle(color: accentColor.withOpacity(0.75), fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                  Text(english, style: TextStyle(color: accentColor, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                ],
              ),
            ),
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