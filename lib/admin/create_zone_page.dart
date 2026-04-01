// import 'package:corporator_app/services/zone_service.dart';
// import 'package:flutter/material.dart';
// import 'dart:math' as math;

// // Helper class to manage dynamic area controllers
// class AreaInput {
//   final TextEditingController nameController = TextEditingController();
//   final TextEditingController cityController = TextEditingController();
//   final TextEditingController prabhagController = TextEditingController();
// }

// class CreateZonePage extends StatefulWidget {
//   final int? adminId; // ── OPTIONAL ADMIN ID ADDED HERE ──

//   const CreateZonePage({super.key, this.adminId});

//   @override
//   State<CreateZonePage> createState() => _CreateZonePageState();
// }

// class _CreateZonePageState extends State<CreateZonePage> with TickerProviderStateMixin {
//   final TextEditingController zoneNameController = TextEditingController();
//   final List<AreaInput> areas = [AreaInput()]; // Start with 1 empty area
  
//   final ZoneService _zoneService = ZoneService();
//   bool isLoading = false;

//   late AnimationController _shimmerController;
//   late AnimationController _pulseController;
//   late Animation<double> _pulseAnimation;

//   // ── Brand Colors ──
//   static const Color saffron     = Color(0xFFFF6700);
//   static const Color deepSaffron = Color(0xFFE55C00);
//   static const Color gold        = Color(0xFFFFD700);
//   static const Color navyBlue    = Color(0xFF002868);
//   static const Color darkNavy    = Color(0xFF001A45);
//   static const Color white       = Color(0xFFFFFDF7);

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
//     zoneNameController.dispose();
//     for (var area in areas) {
//       area.nameController.dispose();
//       area.cityController.dispose();
//       area.prabhagController.dispose();
//     }
//     _shimmerController.dispose();
//     _pulseController.dispose();
//     super.dispose();
//   }

//   void _addArea() {
//     setState(() {
//       areas.add(AreaInput());
//     });
//   }

//   void _removeArea(int index) {
//     if (areas.length > 1) {
//       setState(() {
//         areas[index].nameController.dispose();
//         areas[index].cityController.dispose();
//         areas[index].prabhagController.dispose();
//         areas.removeAt(index);
//       });
//     }
//   }

//   Future<void> submitZone() async {
//     // Validation
//     if (zoneNameController.text.trim().isEmpty) {
//       _showError("Zone Name is required");
//       return;
//     }

//     List<Map<String, String>> areasPayload = [];
//     for (int i = 0; i < areas.length; i++) {
//       final name = areas[i].nameController.text.trim();
//       final city = areas[i].cityController.text.trim();
//       final prabhag = areas[i].prabhagController.text.trim();

//       if (name.isEmpty || city.isEmpty || prabhag.isEmpty) {
//         _showError("Please fill all fields for Area ${i + 1}");
//         return;
//       }

//       areasPayload.add({
//         "name": name,
//         "city": city,
//         "prabhag": prabhag,
//       });
//     }

//     try {
//       setState(() => isLoading = true);
      
//       await _zoneService.createZoneWithAreas(
//         zoneNameController.text.trim(), 
//         areasPayload,
//         adminId: widget.adminId, 
//       );

//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Row(children: [
//             Icon(Icons.check_circle, color: Colors.white),
//             SizedBox(width: 10),
//             Text("Zone & Areas Created Successfully!",
//                 style: TextStyle(fontWeight: FontWeight.bold)),
//           ]),
//           backgroundColor: saffron,
//           behavior: SnackBarBehavior.floating,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//         ),
//       );

//       // Return true to indicate a successful creation to the parent page
//       Navigator.pop(context, true); 

//     } catch (e) {
//       _showError(e.toString().replaceAll("Exception: ", ""));
//     } finally {
//       if (mounted) setState(() => isLoading = false);
//     }
//   }

//   void _showError(String msg) {
//     if (!mounted) return;
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Row(children: [
//           const Icon(Icons.warning_amber_rounded, color: Colors.white),
//           const SizedBox(width: 10),
//           Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold))),
//         ]),
//         backgroundColor: Colors.red.shade800,
//         behavior: SnackBarBehavior.floating,
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
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
//           Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
//           Positioned(
//             top: 0, left: 0, right: 0,
//             child: Container(
//               height: 6,
//               decoration: const BoxDecoration(
//                 gradient: LinearGradient(colors: [saffron, gold, saffron]),
//               ),
//             ),
//           ),

//           SafeArea(
//             child: Column(
//               children: [
//                 // ── App Bar ──
//                 Padding(
//                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
//                           child: const Icon(Icons.arrow_back_ios_new, color: gold, size: 18),
//                         ),
//                       ),
//                       const SizedBox(width: 14),
//                       Expanded(
//                         child: ShaderMask(
//                           shaderCallback: (bounds) => const LinearGradient(
//                             colors: [gold, white, gold],
//                           ).createShader(bounds),
//                           child: const Text(
//                             "CREATE ZONE",
//                             style: TextStyle(
//                               fontSize: 18,
//                               fontWeight: FontWeight.w900,
//                               color: Colors.white,
//                               letterSpacing: 2.5,
//                             ),
//                           ),
//                         ),
//                       ),
//                       ScaleTransition(
//                         scale: _pulseAnimation,
//                         child: Container(
//                           width: 42,
//                           height: 42,
//                           decoration: BoxDecoration(
//                             shape: BoxShape.circle,
//                             gradient: const RadialGradient(
//                               colors: [gold, saffron, deepSaffron],
//                             ),
//                             boxShadow: [
//                               BoxShadow(color: gold.withOpacity(0.5), blurRadius: 12, spreadRadius: 2),
//                             ],
//                           ),
//                           child: const Icon(Icons.map, size: 20, color: darkNavy),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),

//                 const SizedBox(height: 16),

//                 Expanded(
//                   child: SingleChildScrollView(
//                     padding: const EdgeInsets.symmetric(horizontal: 24),
//                     child: Column(
//                       children: [
//                         // ── ZONE MASTER RECORD ──
//                         _buildSectionCard(
//                           headerTitle: "ZONE DETAILS",
//                           headerIcon: Icons.map_outlined,
//                           children: [
//                             _buildField(
//                               controller: zoneNameController,
//                               label: "Zone Name",
//                               hint: "e.g., North Zone",
//                               icon: Icons.location_city,
//                             ),
//                           ],
//                         ),

//                         const SizedBox(height: 24),

//                         // ── AREAS DYNAMIC LIST ──
//                         ...areas.asMap().entries.map((entry) {
//                           int index = entry.key;
//                           AreaInput area = entry.value;
//                           return Padding(
//                             padding: const EdgeInsets.only(bottom: 16),
//                             child: _buildSectionCard(
//                               headerTitle: "AREA ${index + 1}",
//                               headerIcon: Icons.location_on_outlined,
//                               trailing: index > 0 
//                                 ? IconButton(
//                                     icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
//                                     onPressed: () => _removeArea(index),
//                                     padding: EdgeInsets.zero,
//                                     constraints: const BoxConstraints(),
//                                   )
//                                 : null,
//                               children: [
//                                 _buildField(
//                                   controller: area.nameController,
//                                   label: "Area Name",
//                                   hint: "Enter area name",
//                                   icon: Icons.place_outlined,
//                                 ),
//                                 const SizedBox(height: 16),
//                                 _buildField(
//                                   controller: area.cityController,
//                                   label: "City",
//                                   hint: "Enter city name",
//                                   icon: Icons.location_city_outlined,
//                                 ),
//                                 const SizedBox(height: 16),
//                                 _buildField(
//                                   controller: area.prabhagController,
//                                   label: "Prabhag",
//                                   hint: "Enter prabhag number/name",
//                                   icon: Icons.signpost_outlined,
//                                 ),
//                               ],
//                             ),
//                           );
//                         }).toList(),

//                         // ── ADD AREA BUTTON ──
//                         Align(
//                           alignment: Alignment.centerRight,
//                           child: TextButton.icon(
//                             onPressed: _addArea,
//                             icon: const Icon(Icons.add_circle_outline, color: gold),
//                             label: const Text(
//                               "ADD ANOTHER AREA",
//                               style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 1),
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 24),

//                         // ── SUBMIT BUTTON ──
//                         SizedBox(
//                           width: double.infinity,
//                           height: 54,
//                           child: ElevatedButton(
//                             onPressed: isLoading ? null : submitZone,
//                             style: ElevatedButton.styleFrom(
//                               padding: EdgeInsets.zero,
//                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
//                                 color: isLoading ? Colors.grey.shade500 : null,
//                                 borderRadius: BorderRadius.circular(10),
//                                 boxShadow: isLoading ? [] : [
//                                   BoxShadow(color: saffron.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4)),
//                                 ],
//                               ),
//                               child: Container(
//                                 alignment: Alignment.center,
//                                 child: isLoading
//                                     ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
//                                     : const Row(
//                                         mainAxisAlignment: MainAxisAlignment.center,
//                                         children: [
//                                           Icon(Icons.save_rounded, color: Colors.white, size: 20),
//                                           SizedBox(width: 10),
//                                           Text(
//                                             "SAVE ZONE & AREAS",
//                                             style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2),
//                                           ),
//                                         ],
//                                       ),
//                               ),
//                             ),
//                           ),
//                         ),

//                         const SizedBox(height: 40),
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

//   Widget _buildSectionCard({
//     required String headerTitle,
//     required IconData headerIcon,
//     Widget? trailing,
//     required List<Widget> children,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: white,
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(color: gold.withOpacity(0.4), width: 1.5),
//         boxShadow: [
//           BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 10)),
//           BoxShadow(color: saffron.withOpacity(0.1), blurRadius: 14, spreadRadius: 2),
//         ],
//       ),
//       child: Column(
//         children: [
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
//                 Expanded(
//                   child: Text(
//                     headerTitle,
//                     style: const TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.5),
//                   ),
//                 ),
//                 if (trailing != null) trailing,
//               ],
//             ),
//           ),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
//             child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
//           ),
//         ],
//       ),
//     );
//   }

//   Widget _buildField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     required IconData icon,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         Text(
//           label.toUpperCase(),
//           style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: navyBlue, letterSpacing: 1.5),
//         ),
//         const SizedBox(height: 8),
//         TextField(
//           controller: controller,
//           style: const TextStyle(fontSize: 15, color: darkNavy, fontWeight: FontWeight.w600),
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
//             contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
//           ),
//         ),
//       ],
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
//     final centers = [Offset(size.width * 0.88, size.height * 0.06), Offset(size.width * 0.05, size.height * 0.45), Offset(size.width * 0.7, size.height * 0.88)];
//     for (final c in centers) {
//       for (int r = 20; r <= 160; r += 20) canvas.drawCircle(c, r.toDouble(), p);
//       final sp = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1;
//       for (int i = 0; i < 24; i++) {
//         final a = (i * math.pi * 2) / 24;
//         canvas.drawLine(c, Offset(c.dx + math.cos(a) * 160, c.dy + math.sin(a) * 160), sp);
//       }
//     }
//     final lp = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
//     for (double x = -size.height; x < size.width + size.height; x += 40) canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
//   }
//   @override
//   bool shouldRepaint(covariant CustomPainter _) => false;
// }


import 'package:corporator_app/services/super_admin_services.dart';
import 'package:corporator_app/services/zone_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class AreaInput {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController prabhagController = TextEditingController();
}

class CreateZonePage extends StatefulWidget {
  final int? adminId; 

  const CreateZonePage({super.key, this.adminId});

  @override
  State<CreateZonePage> createState() => _CreateZonePageState();
}

class _CreateZonePageState extends State<CreateZonePage> with TickerProviderStateMixin {
  final TextEditingController zoneNameController = TextEditingController();
  final List<AreaInput> areas = [AreaInput()]; 
  
  final ZoneService _zoneService = ZoneService();
  final SuperAdminService _superAdminService = SuperAdminService(); // 👈 Added
  
  bool isLoading = false;
  bool isFetchingAdmins = false;

  // ── Global Creation State ──
  List<dynamic> _admins = [];
  int? _selectedAdminId;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color saffron     = Color(0xFFFF6700);
  static const Color deepSaffron = Color(0xFFE55C00);
  static const Color gold        = Color(0xFFFFD700);
  static const Color navyBlue    = Color(0xFF002868);
  static const Color darkNavy    = Color(0xFF001A45);
  static const Color white       = Color(0xFFFFFDF7);

  @override
  void initState() {
    super.initState();
    _selectedAdminId = widget.adminId; // Default to passed ID if in Inspector Mode

    // ── FETCH ADMINS IF IN GLOBAL MODE ──
    if (widget.adminId == null) {
      _loadAdminsForDropdown();
    }

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  Future<void> _loadAdminsForDropdown() async {
    setState(() => isFetchingAdmins = true);
    try {
      final data = await _superAdminService.getAllAdmins();
      setState(() => _admins = data);
    } catch (e) {
      debugPrint("Failed to load admins: $e");
    } finally {
      setState(() => isFetchingAdmins = false);
    }
  }

  @override
  void dispose() {
    zoneNameController.dispose();
    for (var area in areas) {
      area.nameController.dispose();
      area.cityController.dispose();
      area.prabhagController.dispose();
    }
    _pulseController.dispose();
    super.dispose();
  }

  void _addArea() => setState(() => areas.add(AreaInput()));

  void _removeArea(int index) {
    if (areas.length > 1) {
      setState(() {
        areas[index].nameController.dispose();
        areas[index].cityController.dispose();
        areas[index].prabhagController.dispose();
        areas.removeAt(index);
      });
    }
  }

  Future<void> submitZone() async {
    // ── UX SAFEGUARD ──
    if (widget.adminId == null && _selectedAdminId == null) {
      _showError("Global Creation: Please assign this zone to a Corporator.");
      return;
    }

    if (zoneNameController.text.trim().isEmpty) {
      _showError("Zone Name is required");
      return;
    }

    List<Map<String, String>> areasPayload = [];
    for (int i = 0; i < areas.length; i++) {
      final name = areas[i].nameController.text.trim();
      final city = areas[i].cityController.text.trim();
      final prabhag = areas[i].prabhagController.text.trim();

      if (name.isEmpty || city.isEmpty || prabhag.isEmpty) {
        _showError("Please fill all fields for Area ${i + 1}");
        return;
      }
      areasPayload.add({"name": name, "city": city, "prabhag": prabhag});
    }

    try {
      setState(() => isLoading = true);
      
      await _zoneService.createZoneWithAreas(
        zoneNameController.text.trim(), 
        areasPayload,
        adminId: _selectedAdminId, // 👈 Dynamically passes the correct ID
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Zone Created Successfully!", style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          backgroundColor: saffron, behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true); 
    } catch (e) {
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.white),
        const SizedBox(width: 10),
        Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold))),
      ]),
      backgroundColor: Colors.red.shade800, behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [darkNavy, navyBlue, Color(0xFF003580)], stops: [0.0, 0.55, 1.0]))),
          Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
          Positioned(top: 0, left: 0, right: 0, child: Container(height: 6, decoration: const BoxDecoration(gradient: LinearGradient(colors: [saffron, gold, saffron])))),

          SafeArea(
            child: Column(
              children: [
                // ── App Bar ──
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: gold.withOpacity(0.4))), child: const Icon(Icons.arrow_back_ios_new, color: gold, size: 18)),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(colors: [gold, white, gold]).createShader(bounds),
                          child: const Text("CREATE ZONE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2.5)),
                        ),
                      ),
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(width: 42, height: 42, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [gold, saffron, deepSaffron]), boxShadow: [BoxShadow(color: gold.withOpacity(0.5), blurRadius: 12, spreadRadius: 2)]), child: const Icon(Icons.map, size: 20, color: darkNavy)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        // ── ZONE MASTER RECORD ──
                        _buildSectionCard(
                          headerTitle: "ZONE DETAILS",
                          headerIcon: Icons.map_outlined,
                          children: [
                            _buildField(controller: zoneNameController, label: "Zone Name", hint: "e.g., North Zone", icon: Icons.location_city),
                            
                            // ── UX UPGRADE: DYNAMIC ADMIN SELECTION ──
                            if (widget.adminId == null) ...[
                              const SizedBox(height: 16),
                              const Text("ASSIGN TO CORPORATOR", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: navyBlue, letterSpacing: 1.5)),
                              const SizedBox(height: 8),
                              isFetchingAdmins 
                                ? const Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator(color: saffron))
                                : DropdownButtonFormField<int>(
                                    value: _selectedAdminId,
                                    hint: const Text("Select Corporator"),
                                    decoration: InputDecoration(
                                      prefixIcon: const Icon(Icons.admin_panel_settings, color: saffron, size: 22),
                                      filled: true, fillColor: const Color(0xFFF7F5EF),
                                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
                                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: saffron, width: 2)),
                                    ),
                                    items: _admins.map((a) {
                                      final id = a['adminId'] ?? a['id'];
                                      final name = a['name'] ?? 'Unknown';
                                      return DropdownMenuItem<int>(value: id, child: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)));
                                    }).toList(),
                                    onChanged: (val) => setState(() => _selectedAdminId = val),
                                  ),
                            ]
                          ],
                        ),

                        const SizedBox(height: 24),

                        // ── AREAS DYNAMIC LIST ──
                        ...areas.asMap().entries.map((entry) {
                          int index = entry.key;
                          AreaInput area = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildSectionCard(
                              headerTitle: "AREA ${index + 1}",
                              headerIcon: Icons.location_on_outlined,
                              trailing: index > 0 ? IconButton(icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20), onPressed: () => _removeArea(index), padding: EdgeInsets.zero, constraints: const BoxConstraints()) : null,
                              children: [
                                _buildField(controller: area.nameController, label: "Area Name", hint: "Enter area name", icon: Icons.place_outlined),
                                const SizedBox(height: 16),
                                _buildField(controller: area.cityController, label: "City", hint: "Enter city name", icon: Icons.location_city_outlined),
                                const SizedBox(height: 16),
                                _buildField(controller: area.prabhagController, label: "Prabhag", hint: "Enter prabhag number/name", icon: Icons.signpost_outlined),
                              ],
                            ),
                          );
                        }).toList(),

                        // ── ADD AREA BUTTON ──
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _addArea,
                            icon: const Icon(Icons.add_circle_outline, color: gold),
                            label: const Text("ADD ANOTHER AREA", style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── SUBMIT BUTTON ──
                        SizedBox(
                          width: double.infinity, height: 54,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : submitZone,
                            style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                            child: Ink(
                              decoration: BoxDecoration(gradient: isLoading ? null : const LinearGradient(colors: [saffron, deepSaffron], begin: Alignment.topLeft, end: Alignment.bottomRight), color: isLoading ? Colors.grey.shade500 : null, borderRadius: BorderRadius.circular(10)),
                              child: Container(
                                alignment: Alignment.center,
                                child: isLoading
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.save_rounded, color: Colors.white, size: 20), SizedBox(width: 10), Text("SAVE ZONE & AREAS", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2))]),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({required String headerTitle, required IconData headerIcon, Widget? trailing, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), border: Border.all(color: gold.withOpacity(0.4), width: 1.5), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 10)), BoxShadow(color: saffron.withOpacity(0.1), blurRadius: 14, spreadRadius: 2)]),
      child: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18), decoration: const BoxDecoration(gradient: LinearGradient(colors: [darkNavy, navyBlue]), borderRadius: BorderRadius.vertical(top: Radius.circular(14))), child: Row(children: [Icon(headerIcon, color: gold, size: 18), const SizedBox(width: 10), Expanded(child: Text(headerTitle, style: const TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.5))), if (trailing != null) trailing])),
        Padding(padding: const EdgeInsets.fromLTRB(20, 20, 20, 20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children)),
      ]),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required String hint, required IconData icon}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: navyBlue, letterSpacing: 1.5)),
      const SizedBox(height: 8),
      TextField(controller: controller, style: const TextStyle(fontSize: 15, color: darkNavy, fontWeight: FontWeight.w600), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14), prefixIcon: Icon(icon, color: saffron, size: 22), filled: true, fillColor: const Color(0xFFF7F5EF), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: saffron, width: 2)), contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14))),
    ]);
  }
}

class _ChakraPatternPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.025)..style = PaintingStyle.stroke..strokeWidth = 1;
    final centers = [Offset(size.width * 0.88, size.height * 0.06), Offset(size.width * 0.05, size.height * 0.45), Offset(size.width * 0.7, size.height * 0.88)];
    for (final c in centers) { for (int r = 20; r <= 160; r += 20) canvas.drawCircle(c, r.toDouble(), p); final sp = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1; for (int i = 0; i < 24; i++) { final a = (i * math.pi * 2) / 24; canvas.drawLine(c, Offset(c.dx + math.cos(a) * 160, c.dy + math.sin(a) * 160), sp); } }
    final lp = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 40) canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
  }
  @override bool shouldRepaint(covariant CustomPainter _) => false;
}