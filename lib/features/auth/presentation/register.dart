// import 'package:corporator_app/corporator/services/corporator_service.dart';
// import 'package:corporator_app/features/auth/services/auth_service.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import 'dart:math' as math;

// class Register extends StatefulWidget {
//   const Register({super.key});

//   @override
//   State<Register> createState() => _RegisterState();
// }

// class _RegisterState extends State<Register> with TickerProviderStateMixin {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final CorporatorService corporatorService = CorporatorService();
//   final AuthService authService = AuthService();

//   final nameController = TextEditingController();
//   final mobileController = TextEditingController();
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();
//   final confirmPasswordController = TextEditingController();
//   final locationController = TextEditingController();

//   List<TextEditingController> zoneControllers = [TextEditingController()];

//   bool isLoading = false;
//   bool isPasswordHidden = true;
//   bool isConfirmPasswordHidden = true;

//   late AnimationController _shimmerController;
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;

//   // ── Brand Colors (identical to Login) ──
//   static const Color saffron = Color(0xFFFF6700);
//   static const Color deepSaffron = Color(0xFFE55C00);
//   static const Color gold = Color(0xFFFFD700);
//   static const Color navyBlue = Color(0xFF002868);
//   static const Color darkNavy = Color(0xFF001A45);
//   static const Color white = Color(0xFFFFFDF7);
//   static const Color ashoka = Color(0xFF1A6FAB);

//   @override
//   void initState() {
//     super.initState();
//     _shimmerController = AnimationController(
//       vsync: this,
//       duration: const Duration(seconds: 2),
//     )..repeat();

//     _pulseController = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 1400),
//     )..repeat(reverse: true);

//     _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
//       CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
//     );
//   }

//   @override
//   void dispose() {
//     nameController.dispose();
//     mobileController.dispose();
//     emailController.dispose();
//     passwordController.dispose();
//     confirmPasswordController.dispose();
//     locationController.dispose();
//     for (final c in zoneControllers) c.dispose();
//     _shimmerController.dispose();
//     _pulseController.dispose();
//     super.dispose();
//   }

//   // ── BACKEND LOGIC UNTOUCHED ──
//   Future<void> registerAdmin() async {
//     if (passwordController.text.trim() !=
//         confirmPasswordController.text.trim()) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
//       return;
//     }

//     final corporator = _auth.currentUser;
//     if (corporator == null) return;

//     final corporatorId = corporator.uid;

//     final zoneNames = zoneControllers
//         .map((c) => c.text.trim())
//         .where((z) => z.isNotEmpty)
//         .toList();

//     if (zoneNames.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("At least one zone is required")),
//       );
//       return;
//     }

//     setState(() => isLoading = true);

//     final result = await authService.registerAdmin(
//       name: nameController.text.trim(),
//       mobile: mobileController.text.trim(),
//       email: emailController.text.trim(),
//       password: passwordController.text.trim(),
//       location: locationController.text.trim(),
//       corporatorId: corporatorId,
//     );

//     if (result == null || result.length < 10) {
//       ScaffoldMessenger.of(
//         context,
//       ).showSnackBar(SnackBar(content: Text(result ?? "Error")));
//       setState(() => isLoading = false);
//       return;
//     }

//     final adminId = result;

//     await corporatorService.allocateZonesToAdmin(
//       adminId: adminId,
//       corporatorId: corporatorId,
//       zoneNames: zoneNames,
//     );

//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(
//           children: const [
//             Icon(Icons.check_circle, color: Colors.white),
//             SizedBox(width: 10),
//             Text(
//               "Admin Registered Successfully!",
//               style: TextStyle(fontWeight: FontWeight.bold),
//             ),
//           ],
//         ),
//         backgroundColor: saffron,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );

//     setState(() => isLoading = false);
//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           // ── Deep navy gradient background ──
//           Container(
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(
//                 begin: Alignment.topCenter,
//                 end: Alignment.bottomCenter,
//                 colors: [darkNavy, navyBlue, Color(0xFF003580)],
//                 stops: [0.0, 0.55, 1.0],
//               ),
//             ),
//           ),

//           // ── Chakra pattern ──
//           Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),

//           // ── Saffron top strip ──
//           Positioned(
//             top: 0,
//             left: 0,
//             right: 0,
//             child: Container(
//               height: 6,
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(colors: [saffron, gold, saffron]),
//               ),
//             ),
//           ),

//           // ── Main content ──
//           SafeArea(
//             child: Column(
//               children: [
//                 // ── Custom AppBar ──
//                 Padding(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 16,
//                     vertical: 10,
//                   ),
//                   child: Row(
//                     children: [
//                       GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: Container(
//                           padding: const EdgeInsets.all(8),
//                           decoration: BoxDecoration(
//                             color: Colors.white.withOpacity(0.1),
//                             borderRadius: BorderRadius.circular(10),
//                             border: Border.all(color: gold.withOpacity(0.4)),
//                           ),
//                           child: const Icon(
//                             Icons.arrow_back_ios_new,
//                             color: gold,
//                             size: 18,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(width: 14),
//                       ShaderMask(
//                         shaderCallback: (bounds) => const LinearGradient(
//                           colors: [gold, white, gold],
//                         ).createShader(bounds),
//                         child: const Text(
//                           "CREATE ADMIN",
//                           style: TextStyle(
//                             fontSize: 20,
//                             fontWeight: FontWeight.w900,
//                             color: Colors.white,
//                             letterSpacing: 3,
//                           ),
//                         ),
//                       ),
//                       const Spacer(),
//                       ScaleTransition(
//                         scale: _pulseAnimation,
//                         child: Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             gradient: const RadialGradient(
//                               colors: [gold, saffron, deepSaffron],
//                             ),
//                             boxShadow: [
//                               BoxShadow(
//                                 color: gold.withOpacity(0.5),
//                                 blurRadius: 12,
//                                 spreadRadius: 2,
//                               ),
//                             ],
//                           ),
//                           child: const Icon(
//                             Icons.admin_panel_settings,
//                             size: 20,
//                             color: darkNavy,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 // ── Tagline strip ──
//                 AnimatedBuilder(
//                   animation: _shimmerController,
//                   builder: (context, child) {
//                     return Container(
//                       margin: const EdgeInsets.symmetric(horizontal: 24),
//                       padding: const EdgeInsets.symmetric(
//                         vertical: 8,
//                         horizontal: 16,
//                       ),
//                       decoration: BoxDecoration(
//                         gradient: const LinearGradient(
//                           colors: [saffron, Color(0xFFFF8C00), deepSaffron],
//                         ),
//                         borderRadius: BorderRadius.circular(6),
//                         boxShadow: [
//                           BoxShadow(
//                             color: saffron.withOpacity(0.4),
//                             blurRadius: 12,
//                             offset: const Offset(0, 3),
//                           ),
//                         ],
//                       ),
//                       child: Row(
//                         mainAxisAlignment: MainAxisAlignment.center,
//                         children: const [
//                           Icon(Icons.star, color: Colors.white, size: 13),
//                           SizedBox(width: 8),
//                           Text(
//                             "ADMIN REGISTRATION PORTAL",
//                             style: TextStyle(
//                               color: Colors.white,
//                               fontWeight: FontWeight.w900,
//                               fontSize: 12,
//                               letterSpacing: 2.5,
//                             ),
//                           ),
//                           SizedBox(width: 8),
//                           Icon(Icons.star, color: Colors.white, size: 13),
//                         ],
//                       ),
//                     );
//                   },
//                 ),

//                 const SizedBox(height: 14),

//                 // ── Scrollable form ──
//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.symmetric(horizontal: 24),
//                     child: Column(
//                       children: [
//                         // ── Personal Info Card ──
//                         _buildSectionCard(
//                           headerTitle: "PERSONAL INFORMATION",
//                           headerIcon: Icons.person_outline,
//                           children: [
//                             _buildField(
//                               controller: nameController,
//                               label: "Full Name",
//                               hint: "Enter admin's full name",
//                               icon: Icons.person_outline,
//                             ),
//                             const SizedBox(height: 16),
//                             _buildField(
//                               controller: mobileController,
//                               label: "Mobile Number",
//                               hint: "Enter mobile number",
//                               icon: Icons.phone_outlined,
//                               keyboardType: TextInputType.phone,
//                             ),
//                             const SizedBox(height: 16),
//                             _buildField(
//                               controller: emailController,
//                               label: "Email Address",
//                               hint: "Enter official email",
//                               icon: Icons.email_outlined,
//                               keyboardType: TextInputType.emailAddress,
//                             ),
//                             const SizedBox(height: 16),
//                             _buildField(
//                               controller: locationController,
//                               label: "Location",
//                               hint: "Enter ward / area location",
//                               icon: Icons.location_on_outlined,
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 16),

//                         // ── Security Card ──
//                         _buildSectionCard(
//                           headerTitle: "SECURITY CREDENTIALS",
//                           headerIcon: Icons.lock_outline,
//                           children: [
//                             _buildPasswordField(
//                               controller: passwordController,
//                               label: "Password",
//                               hint: "Create a strong password",
//                               isHidden: isPasswordHidden,
//                               onToggle: () => setState(
//                                 () => isPasswordHidden = !isPasswordHidden,
//                               ),
//                             ),
//                             const SizedBox(height: 16),
//                             _buildPasswordField(
//                               controller: confirmPasswordController,
//                               label: "Confirm Password",
//                               hint: "Re-enter your password",
//                               isHidden: isConfirmPasswordHidden,
//                               onToggle: () => setState(
//                                 () => isConfirmPasswordHidden =
//                                     !isConfirmPasswordHidden,
//                               ),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 16),

//                         // ── Zone Assignment Card ──
//                         _buildSectionCard(
//                           headerTitle: "ZONE ASSIGNMENT",
//                           headerIcon: Icons.map_outlined,
//                           children: [
//                             ...List.generate(zoneControllers.length, (index) {
//                               return Padding(
//                                 padding: const EdgeInsets.only(bottom: 12),
//                                 child: Row(
//                                   children: [
//                                     Expanded(
//                                       child: _buildZoneField(
//                                         zoneControllers[index],
//                                         index + 1,
//                                       ),
//                                     ),
//                                     if (index != 0) ...[
//                                       const SizedBox(width: 8),
//                                       GestureDetector(
//                                         onTap: () => setState(
//                                           () => zoneControllers.removeAt(index),
//                                         ),
//                                         child: Container(
//                                           padding: const EdgeInsets.all(8),
//                                           decoration: BoxDecoration(
//                                             color: Colors.red.shade50,
//                                             borderRadius: BorderRadius.circular(
//                                               10,
//                                             ),
//                                             border: Border.all(
//                                               color: Colors.red.shade300,
//                                             ),
//                                           ),
//                                           child: Icon(
//                                             Icons.remove_circle,
//                                             color: Colors.red.shade600,
//                                             size: 22,
//                                           ),
//                                         ),
//                                       ),
//                                     ],
//                                   ],
//                                 ),
//                               );
//                             }),

//                             // Add Zone button
//                             GestureDetector(
//                               onTap: () => setState(
//                                 () => zoneControllers.add(
//                                   TextEditingController(),
//                                 ),
//                               ),
//                               child: Container(
//                                 padding: const EdgeInsets.symmetric(
//                                   vertical: 12,
//                                   horizontal: 16,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   border: Border.all(
//                                     color: saffron.withOpacity(0.6),
//                                     width: 1.5,
//                                     style: BorderStyle.solid,
//                                   ),
//                                   borderRadius: BorderRadius.circular(10),
//                                   color: saffron.withOpacity(0.06),
//                                 ),
//                                 child: Row(
//                                   mainAxisAlignment: MainAxisAlignment.center,
//                                   children: const [
//                                     Icon(
//                                       Icons.add_circle_outline,
//                                       color: saffron,
//                                       size: 20,
//                                     ),
//                                     SizedBox(width: 8),
//                                     Text(
//                                       "ADD MORE ZONE",
//                                       style: TextStyle(
//                                         color: saffron,
//                                         fontWeight: FontWeight.w800,
//                                         fontSize: 13,
//                                         letterSpacing: 1.5,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ),
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 24),

//                         // ── Register Button ──
//                         SizedBox(
//                           width: double.infinity,
//                           height: 54,
//                           child: ElevatedButton(
//                             onPressed: isLoading ? null : registerAdmin,
//                             style: ElevatedButton.styleFrom(
//                               padding: EdgeInsets.zero,
//                               shape: RoundedRectangleBorder(
//                                 borderRadius: BorderRadius.circular(10),
//                               ),
//                               elevation: 0,
//                             ),
//                             child: Ink(
//                               decoration: BoxDecoration(
//                                 gradient: isLoading
//                                     ? null
//                                     : const LinearGradient(
//                                         colors: [saffron, deepSaffron],
//                                         begin: Alignment.topLeft,
//                                         end: Alignment.bottomRight,
//                                       ),
//                                 color: isLoading ? Colors.grey.shade400 : null,
//                                 borderRadius: BorderRadius.circular(10),
//                                 boxShadow: isLoading
//                                     ? []
//                                     : [
//                                         BoxShadow(
//                                           color: saffron.withOpacity(0.5),
//                                           blurRadius: 12,
//                                           offset: const Offset(0, 4),
//                                         ),
//                                       ],
//                               ),
//                               child: Container(
//                                 alignment: Alignment.center,
//                                 child: isLoading
//                                     ? const SizedBox(
//                                         width: 24,
//                                         height: 24,
//                                         child: CircularProgressIndicator(
//                                           color: Colors.white,
//                                           strokeWidth: 2.5,
//                                         ),
//                                       )
//                                     : const Row(
//                                         mainAxisAlignment:
//                                             MainAxisAlignment.center,
//                                         children: [
//                                           Icon(
//                                             Icons.how_to_reg,
//                                             color: Colors.white,
//                                             size: 20,
//                                           ),
//                                           SizedBox(width: 10),
//                                           Text(
//                                             "REGISTER ADMIN",
//                                             style: TextStyle(
//                                               color: Colors.white,
//                                               fontSize: 16,
//                                               fontWeight: FontWeight.w900,
//                                               letterSpacing: 2.5,
//                                             ),
//                                           ),
//                                         ],
//                                       ),
//                               ),
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 24),

//                         // ── Footer ──
//                         Row(
//                           children: [
//                             Expanded(
//                               child: Container(height: 3, color: saffron),
//                             ),
//                             Expanded(child: Container(height: 3, color: white)),
//                             Expanded(
//                               child: Container(
//                                 height: 3,
//                                 color: const Color(0xFF138808),
//                               ),
//                             ),
//                           ],
//                         ),
//                         const SizedBox(height: 12),
//                         Text(
//                           "© 2025 Corporator Portal. All Rights Reserved.",
//                           style: TextStyle(
//                             color: Colors.white.withOpacity(0.35),
//                             fontSize: 10,
//                           ),
//                         ),
//                         const SizedBox(height: 20),
//                       ],
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Reusable section card with navy header ──
//   Widget _buildSectionCard({
//     required String headerTitle,
//     required IconData headerIcon,
//     required List<Widget> children,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: gold.withOpacity(0.4), width: 1.5),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.35),
//             blurRadius: 28,
//             offset: const Offset(0, 10),
//           ),
//           BoxShadow(
//             color: saffron.withOpacity(0.1),
//             blurRadius: 14,
//             spreadRadius: 2,
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           // Card header
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
//             decoration: const BoxDecoration(
//               gradient: LinearGradient(colors: [darkNavy, navyBlue]),
//               borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
//             ),
//             child: Row(
//               children: [
//                 Icon(headerIcon, color: gold, size: 18),
//                 const SizedBox(width: 10),
//                 Text(
//                   headerTitle,
//                   style: const TextStyle(
//                     color: gold,
//                     fontSize: 12,
//                     fontWeight: FontWeight.w900,
//                     letterSpacing: 2.5,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Card body
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: children,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   // ── Standard field ──
//   Widget _buildField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label.toUpperCase(),
//           style: const TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w800,
//             color: navyBlue,
//             letterSpacing: 1.5,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           keyboardType: keyboardType,
//           style: const TextStyle(
//             fontSize: 15,
//             color: darkNavy,
//             fontWeight: FontWeight.w600,
//           ),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
//             prefixIcon: Icon(icon, color: saffron, size: 22),
//             filled: true,
//             fillColor: const Color(0xFFF7F5EF),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: const BorderSide(color: saffron, width: 2),
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               vertical: 16,
//               horizontal: 14,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Password field ──
//   Widget _buildPasswordField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required bool isHidden,
//     required VoidCallback onToggle,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label.toUpperCase(),
//           style: const TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w800,
//             color: navyBlue,
//             letterSpacing: 1.5,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           obscureText: isHidden,
//           style: const TextStyle(
//             fontSize: 15,
//             color: darkNavy,
//             fontWeight: FontWeight.w600,
//           ),
//           decoration: InputDecoration(
//             hintText: hint,
//             hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
//             prefixIcon: const Icon(
//               Icons.lock_outline,
//               color: saffron,
//               size: 22,
//             ),
//             suffixIcon: IconButton(
//               icon: Icon(
//                 isHidden
//                     ? Icons.visibility_off_outlined
//                     : Icons.visibility_outlined,
//                 color: Colors.grey.shade500,
//                 size: 20,
//               ),
//               onPressed: onToggle,
//             ),
//             filled: true,
//             fillColor: const Color(0xFFF7F5EF),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: const BorderSide(color: saffron, width: 2),
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               vertical: 16,
//               horizontal: 14,
//             ),
//           ),
//         ),
//       ],
//     );
//   }

//   // ── Zone field ──
//   Widget _buildZoneField(TextEditingController controller, int index) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           "ZONE $index",
//           style: const TextStyle(
//             fontSize: 11,
//             fontWeight: FontWeight.w800,
//             color: navyBlue,
//             letterSpacing: 1.5,
//           ),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           style: const TextStyle(
//             fontSize: 15,
//             color: darkNavy,
//             fontWeight: FontWeight.w600,
//           ),
//           decoration: InputDecoration(
//             hintText: "Enter zone name",
//             hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
//             prefixIcon: const Icon(
//               Icons.map_outlined,
//               color: saffron,
//               size: 22,
//             ),
//             filled: true,
//             fillColor: const Color(0xFFF7F5EF),
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10),
//               borderSide: const BorderSide(color: saffron, width: 2),
//             ),
//             contentPadding: const EdgeInsets.symmetric(
//               vertical: 16,
//               horizontal: 14,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ── Ashoka Chakra background painter (identical to Login) ──
// class _ChakraPatternPainter extends CustomPainter {
//   @override
//   void paint(Canvas canvas, Size size) {
//     final paint = Paint()
//       ..color = Colors.white.withOpacity(0.03)
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 1;

//     final centers = [
//       Offset(size.width * 0.85, size.height * 0.12),
//       Offset(size.width * 0.1, size.height * 0.75),
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
