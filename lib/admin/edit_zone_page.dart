import 'package:corporator_app/services/zone_service.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;

class EditZonePage extends StatefulWidget {
  final Map<String, dynamic> zone;
  final Map<int, String> availableSevaks; // Passed from the list page to populate dropdown

  const EditZonePage({
    super.key,
    required this.zone,
    required this.availableSevaks,
  });

  @override
  State<EditZonePage> createState() => _EditZonePageState();
}

class _EditZonePageState extends State<EditZonePage> with SingleTickerProviderStateMixin {
  final ZoneService _zoneService = ZoneService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  int? _selectedSevakId;
  
  // ── FIX: Now storing 3 controllers per Area ──
  List<Map<String, TextEditingController>> _areaControllers = [];

  bool isSubmitting = false;

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
    _nameCtrl = TextEditingController(text: widget.zone['name'] ?? '');
    _selectedSevakId = widget.zone['zoneSevakId'];

    // Populate existing areas with all 3 fields
    final List<dynamic> areas = widget.zone['areas'] ?? [];
    if (areas.isNotEmpty) {
      _areaControllers = areas.map((a) => {
        'name': TextEditingController(text: a['name']?.toString() ?? ''),
        'city': TextEditingController(text: a['city']?.toString() ?? ''),
        'prabhag': TextEditingController(text: a['prabhag']?.toString() ?? ''),
      }).toList();
    } else {
      _addNewArea(); // Ensure at least one field exists
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    for (var areaMap in _areaControllers) {
      areaMap['name']?.dispose();
      areaMap['city']?.dispose();
      areaMap['prabhag']?.dispose();
    }
    super.dispose();
  }

  void _addNewArea() {
    setState(() {
      _areaControllers.add({
        'name': TextEditingController(),
        'city': TextEditingController(),
        'prabhag': TextEditingController(),
      });
    });
  }

  Future<void> submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;

    // Map the controllers to the exact AreaCreate DTO format
    final validAreas = _areaControllers
        .where((map) => map['name']!.text.trim().isNotEmpty) // Basic safety filter
        .map((map) => {
              "name": map['name']!.text.trim(),
              "city": map['city']!.text.trim(),
              "prabhag": map['prabhag']!.text.trim()
            })
        .toList();

    if (validAreas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("कम से कम एक एरिया (Area) आवश्यक है।"),
          backgroundColor: dangerRed,
        ),
      );
      return;
    }

    setState(() => isSubmitting = true);

    try {
      final payload = {
        "name": _nameCtrl.text.trim(),
        "zoneSevakId": _selectedSevakId ?? -1, // Backend interprets -1 as "Unassign"
        "areas": validAreas,
      };

      await _zoneService.updateZone(widget.zone['id'].toString(), payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text(
                "ज़ोन सफलतापूर्वक अपडेट किया गया!",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: indiaGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: dangerRed,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkNavy,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [darkNavy, navyBlue]),
            boxShadow: [
              BoxShadow(
                color: Colors.black45,
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.15),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.white70,
                        size: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "ज़ोन संपादन",
                          style: TextStyle(
                            color: Color(0xFFFFD580),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          "EDIT ZONE",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
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
                Container(
                  height: 4,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [saffron, gold, saffron]),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              color: warmWhite,
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                      horizontal: 16,
                                    ),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [darkNavy, navyBlue],
                                      ),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(6),
                                          decoration: BoxDecoration(
                                            color: gold.withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Icon(
                                            Icons.map,
                                            color: gold,
                                            size: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        const Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "ज़ोन का विवरण",
                                              style: TextStyle(
                                                color: Colors.white54,
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 1.5,
                                              ),
                                            ),
                                            Text(
                                              "ZONE DETAILS",
                                              style: TextStyle(
                                                color: gold,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        TextFormField(
                                          controller: _nameCtrl,
                                          validator: (v) => v!.isEmpty
                                              ? "Zone Name is required"
                                              : null,
                                          style: const TextStyle(
                                            color: darkNavy,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                          decoration: InputDecoration(
                                            labelText: "Zone Name",
                                            labelStyle: const TextStyle(
                                              color: Color(0xFF888888),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                            prefixIcon: const Icon(
                                              Icons.location_city,
                                              color: saffron,
                                              size: 18,
                                            ),
                                            filled: true,
                                            fillColor: Colors.white,
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: const BorderSide(
                                                  color: saffron, width: 2),
                                            ),
                                            enabledBorder: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                              borderSide: BorderSide(
                                                  color:
                                                      saffron.withOpacity(0.4),
                                                  width: 1.5),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 20),

                                        // ── One Zone = One Sevak Dropdown ──
                                        const Text(
                                          "ASSIGNED SEVAK",
                                          style: TextStyle(
                                            color: darkNavy,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 12,
                                            letterSpacing: 1.2,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                                color: saffron.withOpacity(0.4),
                                                width: 1.5),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            color: Colors.white,
                                          ),
                                          child: DropdownButtonFormField<int?>(
                                            value: _selectedSevakId,
                                            decoration: const InputDecoration(
                                              contentPadding:
                                                  EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 14),
                                              border: InputBorder.none,
                                              prefixIcon: Icon(Icons.person,
                                                  color: saffron, size: 18),
                                            ),
                                            items: [
                                              const DropdownMenuItem(
                                                value: null,
                                                child: Text(
                                                    "Unassigned (No Sevak)",
                                                    style: TextStyle(
                                                        color: dangerRed,
                                                        fontWeight:
                                                            FontWeight.bold)),
                                              ),
                                              ...widget.availableSevaks.entries
                                                  .map((e) => DropdownMenuItem(
                                                      value: e.key,
                                                      child: Text(e.value,
                                                          style: const TextStyle(
                                                              color: darkNavy,
                                                              fontWeight:
                                                                  FontWeight.w700)))),
                                            ],
                                            onChanged: (v) => setState(
                                                () => _selectedSevakId = v),
                                          ),
                                        ),

                                        const SizedBox(height: 20),
                                        Container(
                                            height: 1,
                                            color: saffron.withOpacity(0.2)),
                                        const SizedBox(height: 16),

                                        // ── Dynamic Area Block ──
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "AREAS IN THIS ZONE",
                                              style: TextStyle(
                                                color: darkNavy,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            // Add Area Icon Button
                                            GestureDetector(
                                              onTap: _addNewArea,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                decoration: BoxDecoration(
                                                  color: indiaGreen.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(8),
                                                  border: Border.all(color: indiaGreen.withOpacity(0.5)),
                                                ),
                                                child: const Row(
                                                  children: [
                                                    Icon(Icons.add, color: indiaGreen, size: 14),
                                                    SizedBox(width: 4),
                                                    Text("ADD", style: TextStyle(color: indiaGreen, fontWeight: FontWeight.bold, fontSize: 10)),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),

                                        ...List.generate(_areaControllers.length, (index) {
                                          final areaMaps = _areaControllers[index];
                                          return Container(
                                            margin: const EdgeInsets.only(bottom: 16),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius: BorderRadius.circular(10),
                                              border: Border.all(color: saffron.withOpacity(0.3), width: 1.5),
                                              boxShadow: [BoxShadow(color: saffron.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))],
                                            ),
                                            child: Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                  children: [
                                                    Text(
                                                      "AREA ${index + 1}",
                                                      style: const TextStyle(color: saffron, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1),
                                                    ),
                                                    if (_areaControllers.length > 1)
                                                      GestureDetector(
                                                        onTap: () => setState(() => _areaControllers.removeAt(index)),
                                                        child: const Icon(Icons.delete_outline, color: dangerRed, size: 18),
                                                      )
                                                  ],
                                                ),
                                                const SizedBox(height: 10),
                                                _buildAreaTextField(areaMaps['name']!, "Area Name", Icons.place_outlined),
                                                const SizedBox(height: 10),
                                                Row(
                                                  children: [
                                                    Expanded(child: _buildAreaTextField(areaMaps['city']!, "City", Icons.location_city)),
                                                    const SizedBox(width: 10),
                                                    Expanded(child: _buildAreaTextField(areaMaps['prabhag']!, "Prabhag", Icons.map_outlined)),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: isSubmitting ? null : submitUpdate,
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                                disabledBackgroundColor: Colors.grey.shade300,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  gradient: isSubmitting
                                      ? null
                                      : const LinearGradient(
                                          colors: [saffron, deepSaffron],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                  color: isSubmitting ? Colors.grey.shade300 : null,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: isSubmitting
                                      ? []
                                      : [
                                          BoxShadow(
                                            color: saffron.withOpacity(0.5),
                                            blurRadius: 14,
                                            offset: const Offset(0, 5),
                                          )
                                        ],
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: isSubmitting
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.5,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.save_alt_rounded,
                                              color: Colors.white,
                                              size: 22,
                                            ),
                                            SizedBox(width: 10),
                                            Text(
                                              "SAVE ZONE",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 16,
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

  // Helper for the smaller text fields inside the Area block
  Widget _buildAreaTextField(TextEditingController controller, String hint, IconData icon) {
    return TextFormField(
      controller: controller,
      validator: (v) => v!.trim().isEmpty ? "Required" : null,
      style: const TextStyle(color: darkNavy, fontWeight: FontWeight.w600, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 12),
        prefixIcon: Icon(icon, color: saffron.withOpacity(0.7), size: 16),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: saffron, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dangerRed, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: dangerRed, width: 1.5),
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
      Offset(size.width * 0.9, size.height * 0.05),
      Offset(size.width * 0.08, size.height * 0.6),
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
    for (double x = -size.height; x < size.width + size.height; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}