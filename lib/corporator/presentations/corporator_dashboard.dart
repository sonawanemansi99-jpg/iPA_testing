// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:corporator_app/core/widgets/gradient.dart';
// import 'package:corporator_app/core/widgets/main_scaffold.dart';
// import 'package:corporator_app/corporator/presentations/create_zone_dialog.dart';
// import 'package:corporator_app/features/auth/presentation/register.dart';
// import 'package:corporator_app/corporator/presentations/admin_list_page.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class CorporatorDashboard extends StatefulWidget {
//   const CorporatorDashboard({super.key});

//   @override
//   State<CorporatorDashboard> createState() => _CorporatorDashboardState();

//   static Widget _statTile({required String title, required String count}) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 22),
//       decoration: BoxDecoration(
//         gradient: AppGradients.darkGradient,
//         borderRadius: BorderRadius.circular(14),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.3),
//             blurRadius: 10,
//             offset: const Offset(0, 5),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Text(
//             title,
//             textAlign: TextAlign.center,
//             style: const TextStyle(color: Colors.white, fontSize: 14),
//           ),
//           const SizedBox(height: 10),
//           Text(
//             count,
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 32,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _CorporatorDashboardState extends State<CorporatorDashboard> {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _firestore = FirebaseFirestore.instance;

//   Future<Map<String, dynamic>?> fetchCurrentUserData() async {
//     final user = _auth.currentUser;
//     if (user == null) return null;

//     final docSnap = await _firestore.collection('users').doc(user.uid).get();
//     if (!docSnap.exists) return null;

//     return docSnap.data(); // Contains name, email, mobileNo, role, etc.
//   }

//   void adminList() {
//     Navigator.push(
//       context,
//       MaterialPageRoute(builder: (_) => const AdminListPage()),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MainScaffold(
//       title: "Dashboard",
//       body: SingleChildScrollView(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 gradient: AppGradients.glowGradient,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     blurRadius: 8,
//                     color: Colors.black.withOpacity(0.08),
//                     offset: const Offset(0, 4),
//                   ),
//                 ],
//               ),
//               child: Row(
//                 children: [
//                   const CircleAvatar(
//                     radius: 35,
//                     // backgroundImage:
//                     //     AssetImage("assets/images/logo.jpg"),
//                   ),

//                   const SizedBox(width: 16),

//                   FutureBuilder<Map<String, dynamic>?>(
//                     future: fetchCurrentUserData(),
//                     builder: (context, snapshot) {
//                       if (snapshot.connectionState == ConnectionState.waiting) {
//                         return const CircularProgressIndicator();
//                       }
//                       if (!snapshot.hasData || snapshot.data == null) {
//                         return const Text("User data not found");
//                       }

//                       final userData = snapshot.data!;
//                       final name = userData['name'] ?? '';
//                       final email = userData['email'] ?? '';
//                       final mobileNo = userData['mobileNo'] ?? '';

//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             name,
//                             style: const TextStyle(
//                               fontSize: 20,
//                               fontWeight: FontWeight.bold,
//                               color: Colors.white,
//                             ),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             "Email: $email",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                           const SizedBox(height: 6),
//                           Text(
//                             "Mob: $mobileNo",
//                             style: TextStyle(color: Colors.white),
//                           ),
//                           // Optionally add ward/zone if stored in Firestore
//                         ],
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 30),

//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: adminList,
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   "View All Admins",
//                   style: TextStyle(fontSize: 16, color: Colors.black),
//                 ),
//               ),
//             ),

//             const SizedBox(height: 14),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {
//                   Navigator.push(
//                     context,
//                     MaterialPageRoute(builder: (_) => const Register()),
//                   );
//                 },
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   "Add Admin",
//                   style: TextStyle(fontSize: 16, color: Colors.black),
//                 ),
//               ),
//             ),

//             // const SizedBox(height: 14),
//             // SizedBox(
//             //   width: double.infinity,
//             //   child: ElevatedButton(
//             //     onPressed: () {
//             //       showDialog(
//             //         context: context,
//             //         builder: (_) => const CreateZoneDialog(),
//             //       );
//             //     },
//             //     style: ElevatedButton.styleFrom(
//             //       backgroundColor: Colors.white,
//             //       padding: const EdgeInsets.symmetric(vertical: 14),
//             //       shape: RoundedRectangleBorder(
//             //         borderRadius: BorderRadius.circular(12),
//             //       ),
//             //     ),
//             //     child: const Text(
//             //       "Create Zone",
//             //       style: TextStyle(fontSize: 16, color: Colors.black),
//             //     ),
//             //   ),
//             // ),

//             const SizedBox(height: 14),
//             SizedBox(
//               width: double.infinity,
//               child: ElevatedButton(
//                 onPressed: () {},
//                 style: ElevatedButton.styleFrom(
//                   backgroundColor: Colors.white,
//                   padding: const EdgeInsets.symmetric(vertical: 14),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//                 child: const Text(
//                   "Customize design",
//                   style: TextStyle(fontSize: 16, color: Colors.black),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corporator_app/core/widgets/gradient.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/corporator/presentations/corporator_complaints_page.dart';
import 'package:corporator_app/corporator/presentations/create_zone_dialog.dart';
import 'package:corporator_app/features/auth/presentation/register.dart';
import 'package:corporator_app/corporator/presentations/admin_list_page.dart';
import 'package:corporator_app/features/complaints/presentation/screens/list_complaints.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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

  Future<Map<String, dynamic>?> fetchCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final docSnap = await _firestore.collection('users').doc(user.uid).get();
    if (!docSnap.exists) return null;
    return docSnap.data();
  }

  void adminList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> pulse =
        _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Corporator Profile Card ──
                        _buildProfileCard(pulse),

                        const SizedBox(height: 20),

                        // ── Seva Slogan Banner ──
                        _buildSloganBanner(),

                        const SizedBox(height: 24),

                        // ── Section Label ──
                        _buildSectionLabel(
                          "प्रशासन पैनल",
                          "ADMINISTRATION PANEL",
                        ),

                        const SizedBox(height: 14),

                        // ── Action Buttons ──
                        _buildActionButton(
                          icon: Icons.admin_panel_settings,
                          hindi: "सभी एडमिन देखें",
                          english: "VIEW ALL ADMINS",
                          color: navyBlue,
                          accentColor: gold,
                          onTap: adminList,
                        ),

                        const SizedBox(height: 12),

                        _buildActionButton(
                          icon: Icons.person_add_alt_1,
                          hindi: "नया एडमिन जोड़ें",
                          english: "ADD NEW ADMIN",
                          color: saffron,
                          accentColor: Colors.white,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const Register()),
                          ),
                        ),

                        const SizedBox(height: 12),

                        _buildActionButton(
                          icon: Icons.list_alt_outlined,
                          hindi: "शिकायतें देखें",
                          english: "VIEW COMPLAINTS",
                          color: const Color(0xFF1A6FAB), // ashoka blue
                          accentColor: Colors.white,
                          onTap: () {
                            final uid = _auth.currentUser?.uid ?? '';
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ListComplaints(adminId: uid),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 12),

                        _buildActionButton(
                          icon: Icons.palette_outlined,
                          hindi: "डिज़ाइन कस्टमाइज़",
                          english: "CUSTOMIZE DESIGN",
                          color: const Color(0xFF5C2D8E),
                          accentColor: Colors.white,
                          onTap: () {},
                        ),

                        const SizedBox(height: 28),

                        // ── Footer tricolor ──
                        Row(
                          children: [
                            Expanded(
                              child: Container(height: 3, color: saffron),
                            ),
                            Expanded(
                              child: Container(height: 3, color: warmWhite),
                            ),
                            Expanded(
                              child: Container(height: 3, color: indiaGreen),
                            ),
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

  Widget _buildProfileCard(Animation<double> pulse) {
    return ScaleTransition(
      scale: pulse,
      child: Container(
        decoration: BoxDecoration(
          color: warmWhite,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gold.withOpacity(0.3),
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
              // Gold header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 10,
                  horizontal: 16,
                ),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [darkNavy, navyBlue]),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "CORPORATOR PROFILE",
                      style: TextStyle(
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
                child: FutureBuilder<Map<String, dynamic>?>(
                  future: fetchCurrentUserData(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 80,
                        child: Center(
                          child: CircularProgressIndicator(color: saffron),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      return const Text(
                        "User data not found",
                        style: TextStyle(color: Colors.grey),
                      );
                    }

                    final userData = snapshot.data!;
                    final name = userData['name'] ?? '';
                    final email = userData['email'] ?? '';
                    final mobileNo = userData['mobileNo'] ?? '';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Avatar with gold ring
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(
                              colors: [gold, saffron],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: gold.withOpacity(0.5),
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
                              // Name with shimmer-style gold
                              ShaderMask(
                                shaderCallback: (b) => const LinearGradient(
                                  colors: [darkNavy, navyBlue],
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
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [saffron, deepSaffron],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "✦  CORPORATOR",
                                  style: TextStyle(
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
                      ],
                    );
                  },
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

  Widget _buildSloganBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [saffron, deepSaffron]),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: saffron.withOpacity(0.45),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.star, color: Colors.white, size: 14),
          SizedBox(width: 10),
          Text(
            "सेवा • विकास • समर्पण",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 15,
              letterSpacing: 2.5,
            ),
          ),
          SizedBox(width: 10),
          Icon(Icons.star, color: Colors.white, size: 14),
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
