// import 'package:corporator_app/corporator/services/corporator_service.dart';
// import 'package:flutter/material.dart';

// class EditAdminPage extends StatefulWidget {
//   final Map<String, dynamic> admin;

//   const EditAdminPage({super.key, required this.admin});

//   @override
//   State<EditAdminPage> createState() => _EditAdminPageState();
// }

// class _EditAdminPageState extends State<EditAdminPage> {
//   final CorporatorService _service = CorporatorService();

//   List<TextEditingController> zoneControllers = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     loadZones();
//   }

//   Future<void> loadZones() async {
//     final zoneIds = List<String>.from(widget.admin['zoneIds'] ?? []);

//     final zoneNames = await _service.getZoneNamesFromIds(zoneIds);

//     setState(() {
//       zoneControllers =
//           zoneNames.map((z) => TextEditingController(text: z)).toList();

//       if (zoneControllers.isEmpty) {
//         zoneControllers.add(TextEditingController());
//       }

//       isLoading = false;
//     });
//   }

//   Future<void> updateZones() async {
//     final updatedZones = zoneControllers
//         .map((c) => c.text.trim())
//         .where((z) => z.isNotEmpty)
//         .toList();

//     if (updatedZones.isEmpty) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text("At least one zone required")),
//       );
//       return;
//     }

//     await _service.updateAdminZones(
//       adminId: widget.admin['uid'],
//       corporatorId: widget.admin['corporatorId'],
//       newZoneNames: updatedZones,
//     );

//     Navigator.pop(context);
//   }

//   @override
//   Widget build(BuildContext context) {
//     final admin = widget.admin;

//     return Scaffold(
//       appBar: AppBar(title: const Text("Edit Admin")),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : SingleChildScrollView(
//               padding: const EdgeInsets.all(20),
//               child: Column(
//                 children: [
//                   _readOnlyField("Name", admin['name'] ?? ""),
//                   _readOnlyField("Email", admin['email'] ?? ""),
//                   _readOnlyField("Mobile", admin['mobile'] ?? ""),
//                   _readOnlyField("Location", admin['location'] ?? ""),

//                   const SizedBox(height: 20),

//                   const Align(
//                     alignment: Alignment.centerLeft,
//                     child: Text(
//                       "Edit Zones",
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 10),

//                   Column(
//                     children:
//                         List.generate(zoneControllers.length, (index) {
//                       return Padding(
//                         padding: const EdgeInsets.only(bottom: 10),
//                         child: Row(
//                           children: [
//                             Expanded(
//                               child: TextField(
//                                 controller: zoneControllers[index],
//                                 decoration: const InputDecoration(
//                                   labelText: "Zone Name",
//                                   border: OutlineInputBorder(),
//                                 ),
//                               ),
//                             ),
//                             const SizedBox(width: 8),
//                             if (index != 0)
//                               IconButton(
//                                 icon: const Icon(
//                                   Icons.remove_circle,
//                                   color: Colors.red,
//                                 ),
//                                 onPressed: () {
//                                   setState(() {
//                                     zoneControllers.removeAt(index);
//                                   });
//                                 },
//                               ),
//                           ],
//                         ),
//                       );
//                     }),
//                   ),

//                   Align(
//                     alignment: Alignment.centerLeft,
//                     child: TextButton.icon(
//                       onPressed: () {
//                         setState(() {
//                           zoneControllers
//                               .add(TextEditingController());
//                         });
//                       },
//                       icon: const Icon(Icons.add),
//                       label: const Text("Add Zone"),
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   ElevatedButton(
//                     onPressed: updateZones,
//                     child: const Text("Update"),
//                   ),
//                 ],
//               ),
//             ),
//     );
//   }

//   Widget _readOnlyField(String label, String value) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: TextField(
//         readOnly: true,
//         controller: TextEditingController(text: value),
//         decoration: InputDecoration(
//           labelText: label,
//           border: const OutlineInputBorder(),
//         ),
//       ),
//     );
//   }
// }

import 'package:corporator_app/corporator/services/corporator_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class EditAdminPage extends StatefulWidget {
  final Map<String, dynamic> admin;
  const EditAdminPage({super.key, required this.admin});

  @override
  State<EditAdminPage> createState() => _EditAdminPageState();
}

class _EditAdminPageState extends State<EditAdminPage>
    with SingleTickerProviderStateMixin {
  final CorporatorService _service = CorporatorService();
  List<TextEditingController> zoneControllers = [];
  bool isLoading = true;
  bool isSubmitting = false;

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
    loadZones();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    for (final c in zoneControllers) c.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> loadZones() async {
    final zoneIds = List<String>.from(widget.admin['zoneIds'] ?? []);
    final zoneNames = await _service.getZoneNamesFromIds(zoneIds);
    setState(() {
      zoneControllers = zoneNames.map((z) => TextEditingController(text: z)).toList();
      if (zoneControllers.isEmpty) zoneControllers.add(TextEditingController());
      isLoading = false;
    });
  }

  Future<void> updateZones() async {
    final updatedZones = zoneControllers
        .map((c) => c.text.trim())
        .where((z) => z.isNotEmpty)
        .toList();

    if (updatedZones.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: const [
          Icon(Icons.warning_amber, color: Colors.white),
          SizedBox(width: 10),
          Text("कम से कम एक ज़ोन आवश्यक है!", style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        backgroundColor: dangerRed, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }

    setState(() => isSubmitting = true);
    await _service.updateAdminZones(
      adminId: widget.admin['uid'],
      corporatorId: widget.admin['corporatorId'],
      newZoneNames: updatedZones,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: const [
        Icon(Icons.check_circle, color: Colors.white),
        SizedBox(width: 10),
        Text("ज़ोन सफलतापूर्वक अपडेट किए गए!", style: TextStyle(fontWeight: FontWeight.bold)),
      ]),
      backgroundColor: indiaGreen, behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
    setState(() => isSubmitting = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final admin = widget.admin;
    final name = admin['name'] ?? '';
    final Animation<double> pulse = _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);

    return Scaffold(
      backgroundColor: darkNavy,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [darkNavy, navyBlue]),
            boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 3))],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16)),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("एडमिन संपादन", style: TextStyle(color: Color(0xFFFFD580),
                    fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  const Text("EDIT ADMIN", style: TextStyle(color: Colors.white,
                    fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ])),
                // Admin initial avatar
                ScaleTransition(scale: pulse,
                  child: Container(width: 42, height: 42,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [gold, saffron]),
                      boxShadow: [BoxShadow(color: gold.withOpacity(0.5), blurRadius: 10)],
                      border: Border.all(color: gold, width: 1.5)),
                    child: Center(child: Text(name.isNotEmpty ? name[0].toUpperCase() : "A",
                      style: const TextStyle(color: darkNavy, fontSize: 18, fontWeight: FontWeight.w900))))),
              ]),
            ),
          ),
        ),
      ),

      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [darkNavy, navyBlue, Color(0xFF003A8C)], stops: [0.0, 0.4, 1.0]),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
          Column(children: [
            Container(height: 4, decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [saffron, gold, saffron]))),

            isLoading
              ? Expanded(child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(width: 64, height: 64,
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: const RadialGradient(colors: [gold, saffron]),
                      boxShadow: [BoxShadow(color: gold.withOpacity(0.4), blurRadius: 20)]),
                    child: const Padding(padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(color: darkNavy, strokeWidth: 3))),
                  const SizedBox(height: 16),
                  const Text("लोड हो रहा है...",
                    style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 1)),
                ])))
              : Expanded(child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  child: Column(children: [

                    // ── Title banner ──
                    Container(width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [saffron, deepSaffron]),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: saffron.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
                      child: Row(children: const [
                        Icon(Icons.manage_accounts, color: Colors.white, size: 20),
                        SizedBox(width: 10),
                        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("एडमिन प्रोफाइल अपडेट करें",
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                          Text("MANAGE ADMIN PROFILE",
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
                        ]),
                      ])),

                    const SizedBox(height: 16),

                    // ── Admin Info Card (read-only) ──
                    ClipRRect(borderRadius: BorderRadius.circular(16),
                      child: Container(color: warmWhite, child: Column(children: [
                        // Card header
                        Container(width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [darkNavy, navyBlue])),
                          child: Row(children: [
                            Container(padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(color: gold.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8)),
                              child: const Icon(Icons.badge_outlined, color: gold, size: 16)),
                            const SizedBox(width: 10),
                            const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text("अधिकारी जानकारी", style: TextStyle(color: Colors.white54,
                                fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                              Text("ADMIN INFORMATION", style: TextStyle(color: gold,
                                fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                            ]),
                          ])),

                        Padding(padding: const EdgeInsets.all(16),
                          child: Column(children: [
                            _readOnlyTile(Icons.person_outline, "NAME", admin['name'] ?? ""),
                            _divider(),
                            _readOnlyTile(Icons.email_outlined, "EMAIL", admin['email'] ?? ""),
                            _divider(),
                            _readOnlyTile(Icons.phone_outlined, "MOBILE", admin['mobile'] ?? ""),
                            _divider(),
                            _readOnlyTile(Icons.location_on_outlined, "LOCATION", admin['location'] ?? ""),
                          ])),
                      ]))),

                    const SizedBox(height: 16),

                    // ── Zone Editor Card ──
                    ClipRRect(borderRadius: BorderRadius.circular(16),
                      child: Container(color: warmWhite, child: Column(children: [
                        Container(width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [darkNavy, navyBlue])),
                          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                            Row(children: [
                              Container(padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: gold.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.map_outlined, color: gold, size: 16)),
                              const SizedBox(width: 10),
                              const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text("ज़ोन प्रबंधन", style: TextStyle(color: Colors.white54,
                                  fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                                Text("ZONE MANAGEMENT", style: TextStyle(color: gold,
                                  fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                              ]),
                            ]),
                            // Zone count badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: saffron.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: saffron, width: 1)),
                              child: Text("${zoneControllers.length} ZONES",
                                style: const TextStyle(color: saffron, fontSize: 10,
                                  fontWeight: FontWeight.w900, letterSpacing: 1))),
                          ])),

                        Padding(padding: const EdgeInsets.all(16),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                            // Zone fields
                            ...List.generate(zoneControllers.length, (index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(children: [
                                  // Zone number badge
                                  Container(width: 32, height: 32,
                                    decoration: BoxDecoration(shape: BoxShape.circle,
                                      color: navyBlue,
                                      boxShadow: [BoxShadow(color: navyBlue.withOpacity(0.3), blurRadius: 6)]),
                                    child: Center(child: Text("${index + 1}",
                                      style: const TextStyle(color: gold, fontSize: 12,
                                        fontWeight: FontWeight.w900)))),
                                  const SizedBox(width: 10),
                                  // Zone text field
                                  Expanded(child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(color: saffron.withOpacity(0.4), width: 1.5),
                                      borderRadius: BorderRadius.circular(10)),
                                    child: TextField(
                                      controller: zoneControllers[index],
                                      style: const TextStyle(color: darkNavy, fontWeight: FontWeight.w700, fontSize: 14),
                                      decoration: InputDecoration(
                                        labelText: "Zone Name",
                                        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 12),
                                        prefixIcon: const Icon(Icons.place_outlined, color: saffron, size: 18),
                                        border: InputBorder.none,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: const BorderSide(color: saffron, width: 2)),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: saffron.withOpacity(0.4), width: 1.5)),
                                      )),
                                  )),
                                  const SizedBox(width: 8),
                                  // Remove button (not first)
                                  if (index != 0)
                                    GestureDetector(
                                      onTap: () => setState(() => zoneControllers.removeAt(index)),
                                      child: Container(
                                        width: 36, height: 36,
                                        decoration: BoxDecoration(
                                          color: dangerRed.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(color: dangerRed.withOpacity(0.4), width: 1)),
                                        child: const Icon(Icons.remove, color: dangerRed, size: 18)))
                                  else
                                    const SizedBox(width: 36),
                                ]));
                            }),

                            const SizedBox(height: 4),

                            // Add Zone button
                            GestureDetector(
                              onTap: () => setState(() => zoneControllers.add(TextEditingController())),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: indiaGreen.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: indiaGreen.withOpacity(0.4), width: 1.5)),
                                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                                  Icon(Icons.add_circle_outline, color: indiaGreen, size: 18),
                                  SizedBox(width: 8),
                                  Text("नया ज़ोन जोड़ें",
                                    style: TextStyle(color: Color(0xFF777777), fontSize: 10,
                                      fontWeight: FontWeight.w600, letterSpacing: 1)),
                                  SizedBox(width: 4),
                                  Text("ADD ZONE",
                                    style: TextStyle(color: indiaGreen, fontSize: 13,
                                      fontWeight: FontWeight.w900, letterSpacing: 1)),
                                ])),
                            ),
                          ])),
                      ]))),

                    const SizedBox(height: 24),

                    // ── Submit Button ──
                    SizedBox(width: double.infinity, height: 56,
                      child: ElevatedButton(
                        onPressed: isSubmitting ? null : updateZones,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                          disabledBackgroundColor: Colors.grey.shade300),
                        child: Ink(
                          decoration: BoxDecoration(
                            gradient: isSubmitting ? null : const LinearGradient(
                              colors: [saffron, deepSaffron],
                              begin: Alignment.topLeft, end: Alignment.bottomRight),
                            color: isSubmitting ? Colors.grey.shade300 : null,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSubmitting ? [] : [
                              BoxShadow(color: saffron.withOpacity(0.5), blurRadius: 14, offset: const Offset(0, 5))]),
                          child: Container(alignment: Alignment.center,
                            child: isSubmitting
                              ? const SizedBox(width: 24, height: 24,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                              : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                  Icon(Icons.save_alt_rounded, color: Colors.white, size: 22),
                                  SizedBox(width: 10),
                                  Text("SAVE CHANGES",
                                    style: TextStyle(color: Colors.white, fontSize: 16,
                                      fontWeight: FontWeight.w900, letterSpacing: 2.5)),
                                ])))),
                    ),
                  ]),
                )),
          ]),
        ]),
      ),
    );
  }

  Widget _readOnlyTile(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: saffron, size: 16),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF999999),
            fontWeight: FontWeight.w700, letterSpacing: 1.2)),
          const SizedBox(height: 3),
          Text(value.isNotEmpty ? value : "—",
            style: const TextStyle(fontSize: 14, color: darkNavy, fontWeight: FontWeight.w700)),
        ])),
      ]));
  }

  Widget _divider() => Container(height: 1, margin: const EdgeInsets.symmetric(vertical: 2),
    decoration: BoxDecoration(
      gradient: LinearGradient(colors: [saffron.withOpacity(0.15), Colors.transparent])));
}

class _ChakraPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.025)..style = PaintingStyle.stroke..strokeWidth = 1;
    final centers = [Offset(size.width * 0.9, size.height * 0.05), Offset(size.width * 0.06, size.height * 0.55)];
    for (final c in centers) {
      for (int r = 20; r <= 160; r += 20) canvas.drawCircle(c, r.toDouble(), p);
      final sp = Paint()..color = Colors.white.withOpacity(0.03)..strokeWidth = 1;
      for (int i = 0; i < 24; i++) {
        final a = (i * math.pi * 2) / 24;
        canvas.drawLine(c, Offset(c.dx + math.cos(a) * 160, c.dy + math.sin(a) * 160), sp);
      }
    }
    final lp = Paint()..color = Colors.white.withOpacity(0.02)..strokeWidth = 1;
    for (double x = -size.height; x < size.width + size.height; x += 40)
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}