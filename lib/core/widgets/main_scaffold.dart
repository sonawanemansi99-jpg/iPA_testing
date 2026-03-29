// import 'package:corporator_app/features/QR/corporator_qr_download_page.dart';
// import 'package:corporator_app/features/auth/presentation/login.dart';
// import 'package:corporator_app/features/auth/services/auth_service.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:corporator_app/features/videos/corporator_videos_page.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'dart:math' as math;

// class MainScaffold extends StatefulWidget {
//   final Widget body;
//   final String title;
//   final Widget? floatingActionButton;

//   const MainScaffold({
//     super.key,
//     required this.body,
//     required this.title,
//     this.floatingActionButton,
//   });

//   @override
//   State<MainScaffold> createState() => _MainScaffoldState();
// }

// class _MainScaffoldState extends State<MainScaffold>
//     with TickerProviderStateMixin {
//   bool isMenuOpen = false;
//   final AuthService _authService = AuthService();

//   String _userName = "Loading...";
//   String _userRole = "";
//   bool _userLoaded = false;

//   AnimationController? _slideController;
//   AnimationController? _pulseController;
//   Animation<double>? _pulseAnimation;
//   Animation<double>? _fadeAnimation;

//   // ── Brand Colors ──
//   static const Color saffron     = Color(0xFFFF6700);
//   static const Color deepSaffron = Color(0xFFE55C00);
//   static const Color gold        = Color(0xFFFFD700);
//   static const Color navyBlue    = Color(0xFF002868);
//   static const Color darkNavy    = Color(0xFF001A45);
//   static const Color white       = Color(0xFFFFFDF7);
//   static const Color ashoka      = Color(0xFF1A6FAB);

//   @override
//   void initState() {
//     super.initState();
//     _fetchUserData();

//     _slideController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );

//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1400),
//     )..repeat(reverse: true);

//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
//       CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
//     );

//     _fadeAnimation = CurvedAnimation(
//       parent: _slideController!,
//       curve: Curves.easeInOut,
//     );
//   }

//   Future<void> _fetchUserData() async {
//     try {
//       final currentUser = FirebaseAuth.instance.currentUser;
//       if (currentUser == null) {
//         if (mounted) setState(() { _userName = "User"; _userLoaded = true; });
//         return;
//       }

//       final uid = currentUser.uid;

//       final doc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(uid)
//           .get();

//       if (!mounted) return;

//       if (doc.exists) {
//         final data = doc.data() ?? {};

//         // Try common field name variants
//         final name = data['name']?.toString()
//             ?? data['Name']?.toString()
//             ?? data['fullName']?.toString()
//             ?? data['full_name']?.toString()
//             ?? currentUser.displayName
//             ?? currentUser.email?.split('@').first
//             ?? "User";

//         final role = data['role']?.toString()
//             ?? data['Role']?.toString()
//             ?? "";

//         setState(() {
//           _userName = name;
//           _userRole = role.toUpperCase();
//           _userLoaded = true;
//         });
//       } else {
//         // Document doesn't exist — fall back to FirebaseAuth profile
//         setState(() {
//           _userName = currentUser.displayName
//               ?? currentUser.email?.split('@').first
//               ?? "User";
//           _userRole = "";
//           _userLoaded = true;
//         });
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() {
//           _userName = FirebaseAuth.instance.currentUser?.email?.split('@').first ?? "User";
//           _userLoaded = true;
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     _slideController?.dispose();
//     _pulseController?.dispose();
//     super.dispose();
//   }

//   void toggleMenu() {
//     setState(() => isMenuOpen = !isMenuOpen);
//     if (isMenuOpen) {
//       _slideController?.forward();
//     } else {
//       _slideController?.reverse();
//     }
//   }

//   void downloadQR() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => CorporatorQRDownloadPage()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final width = MediaQuery.of(context).size.width;
//     final menuWidth = width * 0.72;

//     return Scaffold(
//       body: Stack(
//         children: [
//           // ── Main page scaffold ──
//           Scaffold(
//             backgroundColor: Colors.transparent,
//             appBar: _buildAppBar(),
//             body: widget.body,
//             floatingActionButton: widget.floatingActionButton,
//           ),

//           // ── Dim overlay ──
//           if (isMenuOpen)
//             FadeTransition(
//               opacity: _fadeAnimation ?? kAlwaysCompleteAnimation,
//               child: GestureDetector(
//                 onTap: toggleMenu,
//                 child: Container(color: Colors.black.withOpacity(0.55)),
//               ),
//             ),

//           // ── Sliding Drawer ──
//           AnimatedPositioned(
//             duration: const Duration(milliseconds: 300),
//             curve: Curves.easeInOut,
//             left: isMenuOpen ? 0 : -menuWidth,
//             top: 0,
//             bottom: 0,
//             child: _buildDrawer(menuWidth),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Themed AppBar ──
//   PreferredSizeWidget _buildAppBar() {
//     return PreferredSize(
//       preferredSize: const Size.fromHeight(64),
//       child: Stack(
//         children: [
//           // Background
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 colors: [darkNavy, navyBlue],
//                 begin: Alignment.topLeft,
//                 end: Alignment.bottomRight,
//               ),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black45,
//                   blurRadius: 12,
//                   offset: Offset(0, 4),
//                 ),
//               ],
//             ),
//           ),
//           // Bottom saffron accent line
//           Positioned(
//             bottom: 0, left: 0, right: 0,
//             child: Container(
//               height: 3,
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(colors: [saffron, gold, saffron]),
//               ),
//             ),
//           ),
//           SafeArea(
//             child: Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 14),
//               child: Row(
//                 children: [
//                   // Hamburger
//                   GestureDetector(
//                     onTap: toggleMenu,
//                     child: Container(
//                       width: 40,
//                       height: 40,
//                       decoration: BoxDecoration(
//                         color: Colors.white.withOpacity(0.08),
//                         borderRadius: BorderRadius.circular(10),
//                         border: Border.all(color: gold.withOpacity(0.35)),
//                       ),
//                       child: Column(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: [
//                           _hamburgerLine(wide: true),
//                           const SizedBox(height: 4),
//                           _hamburgerLine(wide: false),
//                           const SizedBox(height: 4),
//                           _hamburgerLine(wide: true),
//                         ],
//                       ),
//                     ),
//                   ),
//                   const SizedBox(width: 14),

//                   // Title
//                   Expanded(
//                     child: ShaderMask(
//                       shaderCallback: (bounds) => const LinearGradient(
//                         colors: [gold, white, gold],
//                       ).createShader(bounds),
//                       child: Text(
//                         widget.title.toUpperCase(),
//                         style: const TextStyle(
//                           fontSize: 17,
//                           fontWeight: FontWeight.w900,
//                           color: Colors.white,
//                           letterSpacing: 2.5,
//                         ),
//                         overflow: TextOverflow.ellipsis,
//                       ),
//                     ),
//                   ),

//                   // Pulsing emblem
//                   ScaleTransition(
//                     scale: _pulseAnimation ?? kAlwaysCompleteAnimation,
//                     child: Container(
//                       width: 38,
//                       height: 38,
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         gradient: const RadialGradient(
//                           colors: [gold, saffron, deepSaffron],
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: gold.withOpacity(0.5),
//                             blurRadius: 10,
//                             spreadRadius: 2,
//                           ),
//                         ],
//                       ),
//                       child: const Icon(Icons.account_balance,
//                           size: 18, color: darkNavy),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _hamburgerLine({required bool wide}) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 300),
//       height: 2,
//       width: wide ? 20 : 14,
//       decoration: BoxDecoration(
//         color: gold,
//         borderRadius: BorderRadius.circular(2),
//       ),
//     );
//   }

//   // ── Themed Side Drawer ──
//   Widget _buildDrawer(double menuWidth) {
//     return Container(
//       width: menuWidth,
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topCenter,
//           end: Alignment.bottomCenter,
//           colors: [darkNavy, navyBlue, Color(0xFF003580)],
//           stops: [0.0, 0.55, 1.0],
//         ),
//         borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
//         boxShadow: [
//           BoxShadow(color: Colors.black54, blurRadius: 24, spreadRadius: 2),
//         ],
//       ),
//       child: Stack(
//         children: [
//           // Chakra pattern inside drawer
//           Positioned.fill(
//             child: ClipRRect(
//               borderRadius:
//                   const BorderRadius.horizontal(right: Radius.circular(24)),
//               child: CustomPaint(painter: _ChakraPatternPainter()),
//             ),
//           ),

//           // Saffron left accent bar
//           Positioned(
//             left: 0, top: 0, bottom: 0,
//             child: Container(
//               width: 4,
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topCenter,
//                   end: Alignment.bottomCenter,
//                   colors: [saffron, gold, saffron],
//                 ),
//                 borderRadius:
//                     BorderRadius.horizontal(right: Radius.circular(4)),
//               ),
//             ),
//           ),

//           SafeArea(
//             child: SingleChildScrollView(
//               child: Column(
//                 children: [
//                   const SizedBox(height: 24),

//                   // ── Avatar + Name ──
//                   ScaleTransition(
//                     scale: _pulseAnimation ?? kAlwaysCompleteAnimation,
//                     child: Container(
//                       padding: const EdgeInsets.all(4),
//                       decoration: BoxDecoration(
//                         shape: BoxShape.circle,
//                         gradient: const RadialGradient(
//                           colors: [gold, saffron, deepSaffron],
//                         ),
//                         boxShadow: [
//                           BoxShadow(
//                             color: gold.withOpacity(0.6),
//                             blurRadius: 20,
//                             spreadRadius: 4,
//                           ),
//                         ],
//                       ),
//                       child: const CircleAvatar(
//                         radius: 44,
//                         backgroundColor: darkNavy,
//                         child: Icon(Icons.person, size: 44, color: gold),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 12),

//                   // User name
//                   Text(
//                     _userName,
//                     style: const TextStyle(
//                       fontSize: 17,
//                       fontWeight: FontWeight.w900,
//                       color: white,
//                       letterSpacing: 1.2,
//                     ),
//                   ),

//                   const SizedBox(height: 4),

//                   // Role badge
//                   if (_userLoaded)
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 12, vertical: 4),
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                             colors: [saffron, deepSaffron]),
//                         borderRadius: BorderRadius.circular(20),
//                       ),
//                       child: Text(
//                         _userRole,
//                         style: const TextStyle(
//                           fontSize: 10,
//                           fontWeight: FontWeight.w900,
//                           color: Colors.white,
//                           letterSpacing: 2,
//                         ),
//                       ),
//                     ),

//                   const SizedBox(height: 16),

//                   // Gold divider
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Container(
//                       height: 1.5,
//                       decoration: const BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             Colors.transparent,
//                             gold,
//                             Colors.transparent
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 8),

//                   // ── Menu Items ──
//                   _menuItem(Icons.analytics_rounded, "Dashboard"),
//                   _menuItem(Icons.person_outline, "Profile"),
//                   _menuItem(Icons.admin_panel_settings_outlined, "Password"),
//                   _menuItem(Icons.article_outlined, "Complaints"),
//                   _menuItem(Icons.all_inbox_rounded, "Complaint History"),
//                   if (_userRole != "ADMIN")...[
//                     _menuItem(Icons.qr_code_2, "Download QR", onTap: downloadQR),
//   _menuItem(Icons.video_library_rounded, "My Videos", onTap: () {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const CorporatorVideosPage()),
//     );
//   })

//                   const SizedBox(height: 16),

//                   // Gold divider
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Container(
//                       height: 1.5,
//                       decoration: const BoxDecoration(
//                         gradient: LinearGradient(
//                           colors: [
//                             Colors.transparent,
//                             gold,
//                             Colors.transparent
//                           ],
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 16),

//                   // ── Logout Button ──
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: SizedBox(
//                       width: double.infinity,
//                       height: 50,
//                       child: ElevatedButton(
//                         style: ElevatedButton.styleFrom(
//                           padding: EdgeInsets.zero,
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                           elevation: 0,
//                         ),
//                         onPressed: () {
//                           try {
//                             _authService.logout();
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(
//                                 content: Row(
//                                   children: const [
//                                     Icon(Icons.check_circle,
//                                         color: Colors.white),
//                                     SizedBox(width: 10),
//                                     Text("Logged out successfully",
//                                         style: TextStyle(
//                                             fontWeight: FontWeight.bold)),
//                                   ],
//                                 ),
//                                 backgroundColor: saffron,
//                                 behavior: SnackBarBehavior.floating,
//                                 shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(12)),
//                               ),
//                             );
//                             Navigator.pushReplacement(
//                               context,
//                               MaterialPageRoute(builder: (_) => Login()),
//                             );
//                           } catch (e) {
//                             ScaffoldMessenger.of(context).showSnackBar(
//                               SnackBar(content: Text(e.toString())),
//                             );
//                           }
//                         },
//                         child: Ink(
//                           decoration: BoxDecoration(
//                             gradient: const LinearGradient(
//                               colors: [Color(0xFFCC0000), Color(0xFF8B0000)],
//                               begin: Alignment.topLeft,
//                               end: Alignment.bottomRight,
//                             ),
//                             borderRadius: BorderRadius.circular(12),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: Colors.red.withOpacity(0.4),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: Container(
//                             alignment: Alignment.center,
//                             child: const Row(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Icon(Icons.logout_rounded,
//                                     color: Colors.white, size: 20),
//                                 SizedBox(width: 10),
//                                 Text(
//                                   "LOGOUT",
//                                   style: TextStyle(
//                                     color: Colors.white,
//                                     fontSize: 15,
//                                     fontWeight: FontWeight.w900,
//                                     letterSpacing: 2.5,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   // Tricolor footer strip
//                   Padding(
//                     padding: const EdgeInsets.symmetric(horizontal: 20),
//                     child: Row(
//                       children: [
//                         Expanded(child: Container(height: 3, color: saffron)),
//                         Expanded(child: Container(height: 3, color: white)),
//                         Expanded(
//                             child: Container(
//                                 height: 3,
//                                 color: const Color(0xFF138808))),
//                       ],
//                     ),
//                   ),

//                   const SizedBox(height: 10),

//                   Text(
//                     "© 2025 Corporator Portal",
//                     style: TextStyle(
//                       color: Colors.white.withOpacity(0.3),
//                       fontSize: 10,
//                     ),
//                   ),

//                   const SizedBox(height: 20),
//                 ],
                
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _menuItem(IconData icon, String title, {VoidCallback? onTap}) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         splashColor: saffron.withOpacity(0.15),
//         highlightColor: gold.withOpacity(0.08),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
//           child: Container(
//             padding:
//                 const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
//             decoration: BoxDecoration(
//               borderRadius: BorderRadius.circular(10),
//               border: Border.all(color: gold.withOpacity(0.12)),
//               color: Colors.white.withOpacity(0.04),
//             ),
//             child: Row(
//               children: [
//                 Container(
//                   width: 34,
//                   height: 34,
//                   decoration: BoxDecoration(
//                     shape: BoxShape.circle,
//                     color: saffron.withOpacity(0.15),
//                     border: Border.all(color: saffron.withOpacity(0.4)),
//                   ),
//                   child: Icon(icon, color: saffron, size: 17),
//                 ),
//                 const SizedBox(width: 14),
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     color: white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w600,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//                 const Spacer(),
//                 Icon(Icons.chevron_right,
//                     color: gold.withOpacity(0.5), size: 18),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ── Ashoka Chakra background painter ──
// class _ChakraPatternPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white.withOpacity(0.03)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1;

//     final centers = [
//       Offset(size.width * 0.85, size.height * 0.12),
//       Offset(size.width * 0.1, size.height * 0.78),
//     ];

//     for (final center in centers) {
//       for (int r = 20; r <= 180; r += 22) {
//         canvas.drawCircle(center, r.toDouble(), paint);
//       }
//       final spokePaint = Paint()
//         ..color = Colors.white.withOpacity(0.04)
//         ..strokeWidth = 1;
//       for (int i = 0; i < 24; i++) {
//         final angle = (i * math.pi * 2) / 24;
//         canvas.drawLine(
//           center,
//           Offset(
//             center.dx + math.cos(angle) * 180,
//             center.dy + math.sin(angle) * 180,
//           ),
//           spokePaint,
//         );
//       }
//     }

//     final linePaint = Paint()
//       ..color = Colors.white.withOpacity(0.025)
//       ..strokeWidth = 1;
//     for (double x = -size.height; x < size.width + size.height; x += 36) {
//       canvas.drawLine(
//         Offset(x, 0),
//         Offset(x + size.height, size.height),
//         linePaint,
//       );
//     }
//   }

//   @override
//   bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
// }

import 'package:corporator_app/features/QR/corporator_qr_download_page.dart';
import 'package:corporator_app/features/auth/presentation/login.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corporator_app/features/videos/corporator_videos_page.dart';
import 'package:corporator_app/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class MainScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final Widget? floatingActionButton;

  const MainScaffold({
    super.key,
    required this.body,
    required this.title,
    this.floatingActionButton,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold>
    with TickerProviderStateMixin {
  bool isMenuOpen = false;
  final AuthService _authService = AuthService();

  String _userName = "Loading...";
  String _userRole = "";
  bool _userLoaded = false;

  AnimationController? _slideController;
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;
  Animation<double>? _fadeAnimation;

  // ── Brand Colors ──
  static const Color saffron     = Color(0xFFFF6700);
  static const Color deepSaffron = Color(0xFFE55C00);
  static const Color gold        = Color(0xFFFFD700);
  static const Color navyBlue    = Color(0xFF002868);
  static const Color darkNavy    = Color(0xFF001A45);
  static const Color white       = Color(0xFFFFFDF7);
  static const Color ashoka      = Color(0xFF1A6FAB);

  @override
  void initState() {
    super.initState();
    _fetchUserData();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _slideController!,
      curve: Curves.easeInOut,
    );
  }

  Future<void> _fetchUserData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        if (mounted) setState(() { _userName = "User"; _userLoaded = true; });
        return;
      }

      final uid = currentUser.uid;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!mounted) return;

      if (doc.exists) {
        final data = doc.data() ?? {};

        final name = data['name']?.toString()
            ?? data['Name']?.toString()
            ?? data['fullName']?.toString()
            ?? data['full_name']?.toString()
            ?? currentUser.displayName
            ?? currentUser.email?.split('@').first
            ?? "User";

        final role = data['role']?.toString()
            ?? data['Role']?.toString()
            ?? "";

        setState(() {
          _userName = name;
          _userRole = role.toUpperCase();
          _userLoaded = true;
        });
      } else {
        setState(() {
          _userName = currentUser.displayName
              ?? currentUser.email?.split('@').first
              ?? "User";
          _userRole = "";
          _userLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _userName = FirebaseAuth.instance.currentUser?.email?.split('@').first ?? "User";
          _userLoaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _slideController?.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  void toggleMenu() {
    setState(() => isMenuOpen = !isMenuOpen);
    if (isMenuOpen) {
      _slideController?.forward();
    } else {
      _slideController?.reverse();
    }
  }

  void downloadQR() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CorporatorQRDownloadPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final menuWidth = width * 0.72;

    return Scaffold(
      body: Stack(
        children: [
          // ── Main page scaffold ──
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: _buildAppBar(),
            body: widget.body,
            floatingActionButton: widget.floatingActionButton,
          ),

          // ── Dim overlay ──
          if (isMenuOpen)
            FadeTransition(
              opacity: _fadeAnimation ?? kAlwaysCompleteAnimation,
              child: GestureDetector(
                onTap: toggleMenu,
                child: Container(color: Colors.black.withOpacity(0.55)),
              ),
            ),

          // ── Sliding Drawer ──
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            left: isMenuOpen ? 0 : -menuWidth,
            top: 0,
            bottom: 0,
            child: _buildDrawer(menuWidth),
          ),
        ],
      ),
    );
  }

  // ── Themed AppBar ──
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [darkNavy, navyBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
          ),
          // Bottom saffron accent line
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: Container(
              height: 3,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [saffron, gold, saffron]),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  // Hamburger
                  GestureDetector(
                    onTap: toggleMenu,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: gold.withOpacity(0.35)),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _hamburgerLine(wide: true),
                          const SizedBox(height: 4),
                          _hamburgerLine(wide: false),
                          const SizedBox(height: 4),
                          _hamburgerLine(wide: true),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Title
                  Expanded(
                    child: ShaderMask(
                      shaderCallback: (bounds) => const LinearGradient(
                        colors: [gold, white, gold],
                      ).createShader(bounds),
                      child: Text(
                        widget.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),

                  // Pulsing emblem
                  ScaleTransition(
                    scale: _pulseAnimation ?? kAlwaysCompleteAnimation,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [gold, saffron, deepSaffron],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gold.withOpacity(0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.account_balance,
                          size: 18, color: darkNavy),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _hamburgerLine({required bool wide}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 2,
      width: wide ? 20 : 14,
      decoration: BoxDecoration(
        color: gold,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ── Themed Side Drawer ──
  Widget _buildDrawer(double menuWidth) {
    return Container(
      width: menuWidth,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [darkNavy, navyBlue, Color(0xFF003580)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.horizontal(right: Radius.circular(24)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Stack(
        children: [
          // Chakra pattern inside drawer
          Positioned.fill(
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.horizontal(right: Radius.circular(24)),
              child: CustomPaint(painter: _ChakraPatternPainter()),
            ),
          ),

          // Saffron left accent bar
          Positioned(
            left: 0, top: 0, bottom: 0,
            child: Container(
              width: 4,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [saffron, gold, saffron],
                ),
                borderRadius:
                    BorderRadius.horizontal(right: Radius.circular(4)),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 24),

                  // ── Avatar + Name ──
                  ScaleTransition(
                    scale: _pulseAnimation ?? kAlwaysCompleteAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const RadialGradient(
                          colors: [gold, saffron, deepSaffron],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gold.withOpacity(0.6),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const CircleAvatar(
                        radius: 44,
                        backgroundColor: darkNavy,
                        child: Icon(Icons.person, size: 44, color: gold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // User name
                  Text(
                    _userName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: white,
                      letterSpacing: 1.2,
                    ),
                  ),

                  const SizedBox(height: 4),

                  // Role badge
                  if (_userLoaded)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [saffron, deepSaffron]),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _userRole,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                        ),
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Gold divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 1.5,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            gold,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // ── Menu Items ──
                  _menuItem(Icons.analytics_rounded, "Dashboard"),
                  _menuItem(Icons.person_outline, "Profile"),
                  _menuItem(Icons.admin_panel_settings_outlined, "Password"),
                  _menuItem(Icons.article_outlined, "Complaints"),
                  _menuItem(Icons.all_inbox_rounded, "Complaint History"),
                  if (_userRole != "ADMIN") ...[
                    _menuItem(Icons.qr_code_2, "Download QR", onTap: downloadQR),
                    _menuItem(Icons.video_library_rounded, "My Videos", onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CorporatorVideosPage()),
                      );
                    }),
                  ],

                  const SizedBox(height: 16),

                  // Gold divider
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      height: 1.5,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            gold,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ── Logout Button ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () {
                          try {
                            _authService.logout();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: const [
                                    Icon(Icons.check_circle,
                                        color: Colors.white),
                                    SizedBox(width: 10),
                                    Text("Logged out successfully",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                backgroundColor: saffron,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => Login()),
                            );
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(e.toString())),
                            );
                          }
                        },
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFCC0000), Color(0xFF8B0000)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.withOpacity(0.4),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Container(
                            alignment: Alignment.center,
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.logout_rounded,
                                    color: Colors.white, size: 20),
                                SizedBox(width: 10),
                                Text(
                                  "LOGOUT",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
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

                  // Tricolor footer strip
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(child: Container(height: 3, color: saffron)),
                        Expanded(child: Container(height: 3, color: white)),
                        Expanded(
                            child: Container(
                                height: 3,
                                color: const Color(0xFF138808))),
                      ],
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    "© 2025 Corporator Portal",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.3),
                      fontSize: 10,
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: saffron.withOpacity(0.15),
        highlightColor: gold.withOpacity(0.08),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: gold.withOpacity(0.12)),
              color: Colors.white.withOpacity(0.04),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: saffron.withOpacity(0.15),
                    border: Border.all(color: saffron.withOpacity(0.4)),
                  ),
                  child: Icon(icon, color: saffron, size: 17),
                ),
                const SizedBox(width: 14),
                Text(
                  title,
                  style: const TextStyle(
                    color: white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(),
                Icon(Icons.chevron_right,
                    color: gold.withOpacity(0.5), size: 18),
              ],
            ),
          ),
        ),
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
      Offset(size.width * 0.1, size.height * 0.78),
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