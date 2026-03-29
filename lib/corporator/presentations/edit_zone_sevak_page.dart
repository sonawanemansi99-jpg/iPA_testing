import 'dart:io';
import 'package:corporator_app/services/media_service.dart';
import 'package:corporator_app/services/zone_service.dart';
import 'package:corporator_app/services/zone_sevak_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math' as math;

class EditZoneSevakPage extends StatefulWidget {
  final Map<String, dynamic> sevak;
  const EditZoneSevakPage({super.key, required this.sevak});

  @override
  State<EditZoneSevakPage> createState() => _EditZoneSevakPageState();
}

class _EditZoneSevakPageState extends State<EditZoneSevakPage> with SingleTickerProviderStateMixin {
  final ZoneSevakService _sevakService = ZoneSevakService();
  final ZoneService _zoneService = ZoneService(); 
  final MediaService _mediaService = MediaService(); 
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _nicknameCtrl;
  late TextEditingController _mobileCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _adharCtrl;
  bool _isActive = true;

  bool _isLoadingZones = true;
  List<Map<String, dynamic>> _availableZones = [];
  List<int> _selectedZoneIds = [];

  File? _newImageFile;
  final ImagePicker _picker = ImagePicker();
  String? _existingPhotoUrl;

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
    
    _nameCtrl = TextEditingController(text: widget.sevak['name'] ?? '');
    _nicknameCtrl = TextEditingController(text: widget.sevak['nickname'] ?? '');
    _mobileCtrl = TextEditingController(text: widget.sevak['mobileNumber'] ?? '');
    _emailCtrl = TextEditingController(text: widget.sevak['email'] ?? '');
    _adharCtrl = TextEditingController(text: widget.sevak['adharNo'] ?? '');
    _isActive = widget.sevak['isActive'] == true;
    _existingPhotoUrl = widget.sevak['livePhotoUrl']?.toString();

    _selectedZoneIds = List<int>.from(widget.sevak['zoneIds'] ?? []);

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(CurvedAnimation(parent: _pulseController!, curve: Curves.easeInOut));

    _loadAvailableZones();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _nicknameCtrl.dispose();
    _mobileCtrl.dispose();
    _emailCtrl.dispose();
    _adharCtrl.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  Future<void> _loadAvailableZones() async {
    try {
      final allMyZones = await _zoneService.fetchMyZones();
      final currentSevakIdStr = widget.sevak['id'].toString();

      setState(() {
        _availableZones = allMyZones.where((zone) {
          final assignedSevakIdStr = zone['zoneSevakId']?.toString();
          return assignedSevakIdStr == null || assignedSevakIdStr == currentSevakIdStr;
        }).toList();
        
        _isLoadingZones = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingZones = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to load zones: $e")));
      }
    }
  }

  Future<void> _pickImage() async {
    try {
      final pickedFile = await _picker.pickImage(source: ImageSource.camera, imageQuality: 70);
      if (pickedFile != null) {
        setState(() {
          _newImageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error capturing image: $e")));
    }
  }

  Future<void> submitUpdate() async {
    if (!_formKey.currentState!.validate()) return;
    
    // ── NEW VALIDATION: Only require a zone if the Sevak is ACTIVE ──
    if (_isActive && _selectedZoneIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("सक्रिय सेवक के लिए कम से कम एक ज़ोन चुनना अनिवार्य है (Active Sevak must have at least one zone)."),
        backgroundColor: dangerRed, behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    setState(() => isSubmitting = true);

    try {
      String? photoUrlToSubmit = _existingPhotoUrl;

      if (_newImageFile != null) {
        photoUrlToSubmit = await _mediaService.uploadMediaToCloudinary(_newImageFile!);
      }

      final Map<String, dynamic> payload = {
        "name": _nameCtrl.text.trim(),
        "nickname": _nicknameCtrl.text.trim(),
        "mobileNumber": _mobileCtrl.text.trim(),
        "email": _emailCtrl.text.trim(),
        "adharNo": _adharCtrl.text.trim(),
        "isActive": _isActive,
        // If inactive, send an empty array to detach everything
        "zoneIds": _isActive ? _selectedZoneIds : [], 
      };

      if (photoUrlToSubmit != null && photoUrlToSubmit.isNotEmpty) {
        payload["livePhotoUrl"] = photoUrlToSubmit;
      }

      final sevakId = widget.sevak['id'].toString();
      await _sevakService.updateZoneSevak(sevakId, payload);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(children: const [
          Icon(Icons.check_circle, color: Colors.white), SizedBox(width: 10),
          Text("प्रोफाइल सफलतापूर्वक अपडेट की गई!", style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        backgroundColor: indiaGreen, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      
      Navigator.pop(context, true); 
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.toString()), backgroundColor: dangerRed, behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Animation<double> pulse = _pulseAnimation ?? const AlwaysStoppedAnimation(1.0);
    final initialName = _nameCtrl.text.isNotEmpty ? _nameCtrl.text : 'S';

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
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white.withOpacity(0.15), width: 1)),
                    child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 16),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                  Text("ज़ोन सेवक संपादन", style: TextStyle(color: Color(0xFFFFD580), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  Text("EDIT ZONE SEVAK", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2)),
                ])),
                ScaleTransition(scale: pulse,
                  child: Container(width: 42, height: 42,
                    decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [gold, saffron]), boxShadow: [BoxShadow(color: gold.withOpacity(0.5), blurRadius: 10)], border: Border.all(color: gold, width: 1.5)),
                    child: Center(child: Text(initialName[0].toUpperCase(), style: const TextStyle(color: darkNavy, fontSize: 18, fontWeight: FontWeight.w900))))),
              ]),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [darkNavy, navyBlue, Color(0xFF003A8C)], stops: [0.0, 0.4, 1.0]),
        ),
        child: Stack(children: [
          Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
          Column(children: [
            Container(height: 4, decoration: const BoxDecoration(gradient: LinearGradient(colors: [saffron, gold, saffron]))),
            Expanded(child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
              child: Form(
                key: _formKey,
                child: Column(children: [
                  
                  Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(gradient: const LinearGradient(colors: [saffron, deepSaffron]), borderRadius: BorderRadius.circular(10), boxShadow: [BoxShadow(color: saffron.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]),
                    child: Row(children: const [
                      Icon(Icons.manage_accounts, color: Colors.white, size: 20), SizedBox(width: 10),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text("सेवक प्रोफाइल अपडेट करें", style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1)),
                        Text("MANAGE SEVAK PROFILE", style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      ]),
                    ])),

                  const SizedBox(height: 16),

                  ClipRRect(borderRadius: BorderRadius.circular(16),
                    child: Container(color: warmWhite, child: Column(children: [
                      Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: const BoxDecoration(gradient: LinearGradient(colors: [darkNavy, navyBlue])),
                        child: Row(children: [
                          Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.badge_outlined, color: gold, size: 16)),
                          const SizedBox(width: 10),
                          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text("जानकारी भरें", style: TextStyle(color: Colors.white54, fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.5)),
                            Text("ENTER DETAILS", style: TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2)),
                          ]),
                        ])),

                      Padding(padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                          
                          Center(
                            child: GestureDetector(
                              onTap: _pickImage,
                              child: Stack(
                                children: [
                                  Container(
                                    width: 100, height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade200,
                                      border: Border.all(color: saffron, width: 2.5),
                                      boxShadow: [BoxShadow(color: saffron.withOpacity(0.2), blurRadius: 10, spreadRadius: 2)],
                                      image: _newImageFile != null
                                          ? DecorationImage(image: FileImage(_newImageFile!), fit: BoxFit.cover)
                                          : (_existingPhotoUrl != null && _existingPhotoUrl!.isNotEmpty)
                                              ? DecorationImage(image: NetworkImage(_existingPhotoUrl!), fit: BoxFit.cover)
                                              : null,
                                    ),
                                    child: (_newImageFile == null && (_existingPhotoUrl == null || _existingPhotoUrl!.isEmpty))
                                        ? Center(child: Text(initialName[0].toUpperCase(), style: const TextStyle(fontSize: 40, color: darkNavy, fontWeight: FontWeight.w900)))
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0, right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(color: navyBlue, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)),
                                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          _buildTextField(controller: _nameCtrl, label: "Full Name", icon: Icons.person_outline, validator: (v) => v!.isEmpty ? "Name is required" : null),
                          const SizedBox(height: 14),
                          _buildTextField(controller: _nicknameCtrl, label: "Nickname", icon: Icons.face),
                          const SizedBox(height: 14),
                          _buildTextField(controller: _mobileCtrl, label: "Mobile Number", icon: Icons.phone_outlined, keyboardType: TextInputType.phone, validator: (v) => v!.length != 10 ? "Must be 10 digits" : null),
                          const SizedBox(height: 14),
                          _buildTextField(controller: _emailCtrl, label: "Email Address", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress, validator: (v) => !v!.contains('@') && v.isNotEmpty ? "Invalid email" : null),
                          const SizedBox(height: 14),
                          _buildTextField(controller: _adharCtrl, label: "Aadhar Number", icon: Icons.credit_card, keyboardType: TextInputType.number, validator: (v) => v!.length != 12 ? "Must be 12 digits" : null),
                          
                          const SizedBox(height: 16),
                          Container(height: 1, color: saffron.withOpacity(0.2)),
                          const SizedBox(height: 16),

                          // ── Active Status Toggle ──
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Account Status", style: TextStyle(color: darkNavy, fontWeight: FontWeight.w800, fontSize: 14)),
                                  Text(_isActive ? "Currently Active" : "Currently Suspended", style: TextStyle(color: _isActive ? indiaGreen : dangerRed, fontSize: 11, fontWeight: FontWeight.w700)),
                                ],
                              ),
                              Switch(
                                value: _isActive,
                                activeColor: indiaGreen,
                                inactiveThumbColor: dangerRed,
                                onChanged: (val) {
                                  setState(() {
                                    _isActive = val;
                                    // AUTO-CLEAR zones when deactivated for better UX
                                    if (!_isActive) {
                                      _selectedZoneIds.clear();
                                    }
                                  });
                                },
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          Container(height: 1, color: saffron.withOpacity(0.2)),
                          const SizedBox(height: 16),

                          // ── Zone Reassignment Section ──
                          Text("ASSIGNED ZONES", style: TextStyle(color: _isActive ? darkNavy : Colors.grey, fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 1.2)),
                          const SizedBox(height: 6),
                          Text("Select the zones this Sevak should manage:", style: TextStyle(color: _isActive ? const Color(0xFF777777) : Colors.grey, fontSize: 11)),
                          const SizedBox(height: 10),
                          
                          if (!_isActive)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                              child: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: dangerRed, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text("Suspended Sevaks cannot be assigned to zones. All current zones will be unassigned.", style: TextStyle(color: dangerRed, fontSize: 11, fontWeight: FontWeight.w600))),
                                ],
                              ),
                            )
                          else if (_isLoadingZones)
                            const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: saffron)))
                          else if (_availableZones.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
                              child: const Text("No available zones found. Ensure you have created zones and they are unassigned.", style: TextStyle(color: Colors.grey, fontSize: 12, fontStyle: FontStyle.italic)),
                            )
                          else
                            Wrap(
                              spacing: 8.0,
                              runSpacing: 8.0,
                              children: _availableZones.map((zone) {
                                final isSelected = _selectedZoneIds.contains(zone['id']);
                                return FilterChip(
                                  label: Text(zone['name'].toString().toUpperCase()),
                                  labelStyle: TextStyle(
                                    color: isSelected ? Colors.white : darkNavy,
                                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                                    fontSize: 11,
                                    letterSpacing: 1,
                                  ),
                                  backgroundColor: Colors.white,
                                  selectedColor: saffron,
                                  checkmarkColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(color: isSelected ? saffron : Colors.grey.shade300, width: 1.5),
                                  ),
                                  selected: isSelected,
                                  // Disable clicking if the account is suspended
                                  onSelected: _isActive ? (bool selected) {
                                    setState(() {
                                      if (selected) {
                                        _selectedZoneIds.add(zone['id']);
                                      } else {
                                        _selectedZoneIds.remove(zone['id']);
                                      }
                                    });
                                  } : null,
                                );
                              }).toList(),
                            ),
                        ])),
                    ]))),

                  const SizedBox(height: 24),

                  SizedBox(width: double.infinity, height: 56,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : submitUpdate,
                      style: ElevatedButton.styleFrom(padding: EdgeInsets.zero, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0, disabledBackgroundColor: Colors.grey.shade300),
                      child: Ink(
                        decoration: BoxDecoration(
                          gradient: isSubmitting ? null : const LinearGradient(colors: [saffron, deepSaffron], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          color: isSubmitting ? Colors.grey.shade300 : null,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSubmitting ? [] : [BoxShadow(color: saffron.withOpacity(0.5), blurRadius: 14, offset: const Offset(0, 5))]),
                        child: Container(alignment: Alignment.center,
                          child: isSubmitting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                                Icon(Icons.save_alt_rounded, color: Colors.white, size: 22), SizedBox(width: 10),
                                Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
                              ]))))),
                ]),
              ),
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(color: darkNavy, fontWeight: FontWeight.w700, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 12, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, color: saffron, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: saffron, width: 2)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: saffron.withOpacity(0.4), width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: dangerRed, width: 1.5)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: dangerRed, width: 2)),
      ),
    );
  }
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
    for (double x = -size.height; x < size.width + size.height; x += 40) canvas.drawLine(Offset(x, 0), Offset(x + size.height, size.height), lp);
  }
  @override
  bool shouldRepaint(covariant CustomPainter _) => false;
}