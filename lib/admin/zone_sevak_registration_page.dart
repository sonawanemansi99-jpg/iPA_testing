import 'dart:io';
import 'dart:math' as math;
import 'package:corporator_app/services/media_service.dart';
import 'package:corporator_app/services/zone_service.dart';
import 'package:corporator_app/services/zone_sevak_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class ZoneSevakRegistrationPage extends StatefulWidget {
  const ZoneSevakRegistrationPage({super.key});

  @override
  State<ZoneSevakRegistrationPage> createState() => _ZoneSevakRegistrationPageState();
}

class _ZoneSevakRegistrationPageState extends State<ZoneSevakRegistrationPage> with TickerProviderStateMixin {
  final nameController         = TextEditingController();
  final nicknameController     = TextEditingController();
  final emailController        = TextEditingController();
  final passwordController     = TextEditingController();
  final mobileController       = TextEditingController();
  final adharController        = TextEditingController();

  final MediaService _mediaServices = MediaService();
  final ZoneService _zoneServices = ZoneService();
  final ZoneSevakService _zoneSevakServices = ZoneSevakService();
  
  bool isLoading = false;
  bool isPasswordHidden = true;

  // Camera & Photo State
  File? _capturedImage;
  String? _uploadedPhotoUrl;
  bool _isUploadingPhoto = false;

  // Zones State
  List<dynamic> _availableZones = [];
  final List<int> _selectedZoneIds = [];
  bool _isLoadingZones = true;

  late AnimationController _shimmerController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  // Brand Colors
  static const Color saffron     = Color(0xFFFF6700);
  static const Color deepSaffron = Color(0xFFE55C00);
  static const Color gold        = Color(0xFFFFD700);
  static const Color navyBlue    = Color(0xFF002868);
  static const Color darkNavy    = Color(0xFF001A45);
  static const Color white       = Color(0xFFFFFDF7);

  @override
  void initState() {
    super.initState();
    _loadUnassignedZones();

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    nicknameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    mobileController.dispose();
    adharController.dispose();
    _shimmerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadUnassignedZones() async {
    try {
      final zones = await _zoneServices.fetchUnassignedZones(); 
      if (mounted) {
        setState(() {
          _availableZones = zones;
          _isLoadingZones = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingZones = false);
        _showError("Failed to load zones: $e");
      }
    }
  }

  Future<void> _captureLivePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (pickedFile != null) {
      setState(() {
        _capturedImage = File(pickedFile.path);
        _isUploadingPhoto = true;
      });

      try {
        String url = await _mediaServices.uploadMediaToCloudinary(_capturedImage!);
        setState(() {
          _uploadedPhotoUrl = url;
          _isUploadingPhoto = false;
        });
      } catch (e) {
        setState(() {
          _capturedImage = null;
          _isUploadingPhoto = false;
        });
        _showError("Photo upload failed: $e");
      }
    }
  }

  Future<void> registerSevak() async {
    if (nameController.text.isEmpty ||
        nicknameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        mobileController.text.isEmpty ||
        adharController.text.isEmpty ||
        _uploadedPhotoUrl == null) {
      _showError("Please fill all fields and capture Live Photo.");
      return;
    }

    if (_selectedZoneIds.isEmpty) {
      _showError("You must assign at least one Zone to the Sevak.");
      return;
    }

    try {
      setState(() => isLoading = true);

      await _zoneSevakServices.createZoneSevak(
        nickname:     nicknameController.text.trim(),
        name:         nameController.text.trim(),
        mobileNumber:     mobileController.text.trim(),
        email:        emailController.text.trim(),
        password:     passwordController.text.trim(),
        livePhotoUrl: _uploadedPhotoUrl!,
        adharNo:      adharController.text.trim(),
        zoneIds:      _selectedZoneIds,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Text("Zone Sevak Registered Successfully!", style: TextStyle(fontWeight: FontWeight.bold)),
          ]),
          backgroundColor: saffron,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      Navigator.pop(context); // Go back to dashboard on success

    } catch (e) {
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold))),
        ]),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [darkNavy, navyBlue, Color(0xFF003580)],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),
          Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              height: 6,
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [saffron, gold, saffron]),
              ),
            ),
          ),

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
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: gold.withOpacity(0.4)),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: gold, size: 18),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [gold, white, gold],
                          ).createShader(bounds),
                          child: const Text(
                            "CREATE ZONE SEVAK",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 2.0,
                            ),
                          ),
                        ),
                      ),
                      ScaleTransition(
                        scale: _pulseAnimation,
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const RadialGradient(colors: [gold, saffron, deepSaffron]),
                            boxShadow: [
                              BoxShadow(color: gold.withOpacity(0.5), blurRadius: 12, spreadRadius: 2),
                            ],
                          ),
                          child: const Icon(Icons.security, size: 20, color: darkNavy),
                        ),
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
                        _buildSectionCard(
                          headerTitle: "PERSONAL INFORMATION",
                          headerIcon: Icons.person_outline,
                          children: [
                            _buildField(controller: nameController, label: "Full Name", hint: "Enter sevak's full name", icon: Icons.person_outline),
                            const SizedBox(height: 16),
                            _buildField(controller: nicknameController, label: "Nickname", hint: "Enter nickname", icon: Icons.badge_outlined),
                            const SizedBox(height: 16),
                            _buildField(controller: mobileController, label: "Mobile Number", hint: "Enter 10-digit mobile number", icon: Icons.phone_outlined, keyboardType: TextInputType.phone,limit: 10),
                            const SizedBox(height: 16),
                            _buildField(controller: adharController, label: "Aadhar Number", hint: "Enter 12-digit Aadhar number", icon: Icons.credit_card_outlined, keyboardType: TextInputType.number,limit: 12),
                            const SizedBox(height: 16),
                            _buildPhotoCaptureSection(),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // ── ZONE ASSIGNMENT SECTION ──
                        _buildSectionCard(
                          headerTitle: "ZONE ASSIGNMENT",
                          headerIcon: Icons.map_outlined,
                          children: [
                            const Text(
                              "SELECT JURISDICTION (MIN 1)",
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: navyBlue, letterSpacing: 1.5),
                            ),
                            const SizedBox(height: 12),
                            _isLoadingZones
                                ? const Center(child: CircularProgressIndicator(color: saffron))
                                : _availableZones.isEmpty
                                    ? Container(
                                        padding: const EdgeInsets.all(14),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withOpacity(0.08),
                                          borderRadius: BorderRadius.circular(10),
                                          border: Border.all(color: Colors.red.withOpacity(0.3), width: 1.5),
                                        ),
                                        child: Row(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.block_flipped, color: Colors.red.shade700, size: 22),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                "No Unassigned Zones Available.\n\nAll existing Zones currently have an assigned Zone Sevak. You must create a new Zone before registering a new Sevak.",
                                                style: TextStyle(
                                                  color: Colors.red.shade900,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1.4,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                    // Standard Wrap for available zones
                                    : Wrap(
                                        spacing: 10,
                                        runSpacing: 10,
                                        children: _availableZones.map((zone) {
                                          final int zoneId = zone['id'] ?? zone['zoneId']; 
                                          final bool isSelected = _selectedZoneIds.contains(zoneId);
                                          return FilterChip(
                                            label: Text(zone['name'] ?? 'Unknown', style: TextStyle(
                                              color: isSelected ? Colors.white : navyBlue,
                                              fontWeight: FontWeight.bold,
                                            )),
                                            selected: isSelected,
                                            selectedColor: saffron,
                                            backgroundColor: const Color(0xFFF7F5EF),
                                            checkmarkColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              side: BorderSide(color: isSelected ? saffron : Colors.grey.shade300)
                                            ),
                                            onSelected: (bool selected) {
                                              setState(() {
                                                if (selected) {
                                                  _selectedZoneIds.add(zoneId);
                                                } else {
                                                  _selectedZoneIds.remove(zoneId);
                                                }
                                              });
                                            },
                                          );
                                        }).toList(),
                                      ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        _buildSectionCard(
                          headerTitle: "LOGIN CREDENTIALS",
                          headerIcon: Icons.lock_outline,
                          children: [
                            _buildField(controller: emailController, label: "Email Address", hint: "Enter official email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildPasswordField(),
                          ],
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            // 👇 NEW: Button strictly disabled if _availableZones is empty!
                            onPressed: (isLoading || _isUploadingPhoto || _availableZones.isEmpty) ? null : registerSevak,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            child: Ink(
                              decoration: BoxDecoration(
                                // Grey out the button if loading or no zones available
                                gradient: (isLoading || _isUploadingPhoto || _availableZones.isEmpty)
                                    ? null
                                    : const LinearGradient(colors: [saffron, deepSaffron], begin: Alignment.topLeft, end: Alignment.bottomRight),
                                color: (isLoading || _isUploadingPhoto || _availableZones.isEmpty) ? Colors.grey.shade400 : null,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: (isLoading || _isUploadingPhoto || _availableZones.isEmpty) ? [] : [
                                  BoxShadow(color: saffron.withOpacity(0.5), blurRadius: 12, offset: const Offset(0, 4)),
                                ],
                              ),
                              child: Container(
                                alignment: Alignment.center,
                                child: (isLoading || _isUploadingPhoto)
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          // Change icon to a lock if disabled
                                          Icon(_availableZones.isEmpty ? Icons.lock_outline : Icons.how_to_reg, color: Colors.white, size: 20),
                                          const SizedBox(width: 10),
                                          Text(
                                            _availableZones.isEmpty ? "REGISTRATION LOCKED" : "REGISTER ZONE SEVAK", 
                                            style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 2)
                                          ),
                                        ],
                                      ),
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

  Widget _buildSectionCard({
    required String headerTitle,
    required IconData headerIcon,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: gold.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 28, offset: const Offset(0, 10)),
          BoxShadow(color: saffron.withOpacity(0.1), blurRadius: 14, spreadRadius: 2),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [darkNavy, navyBlue]),
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Icon(headerIcon, color: gold, size: 18),
                const SizedBox(width: 10),
                Text(headerTitle, style: const TextStyle(color: gold, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 2.5)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
          ),
        ],
      ),
    );
  }

Widget _buildField({
  required TextEditingController controller,
  required String label,
  required String hint,
  required IconData icon,
  TextInputType keyboardType = TextInputType.text,
  int? limit, // 👈 Rename to 'limit' for clarity
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Color(0xFF002868), // navyBlue
            letterSpacing: 1.5),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        // ── THE PHYSICAL WALL ──
        inputFormatters: [
          // 1. Only allow numbers if it's a phone/number field
          if (keyboardType == TextInputType.phone || keyboardType == TextInputType.number)
            FilteringTextInputFormatter.digitsOnly,
          
          // 2. This physically prevents the 11th (or 13th) character from being entered
          if (limit != null) 
            LengthLimitingTextInputFormatter(limit), 
        ],
        style: const TextStyle(
            fontSize: 15, 
            color: Color(0xFF001A45), // darkNavy
            fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          hintText: hint,
          counterText: "", // Hides the counter so it looks clean
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFFFF6700), size: 22), // saffron
          filled: true,
          fillColor: const Color(0xFFF7F5EF),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFFF6700), width: 2), // saffron
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        ),
      ),
    ],
  );
}

  Widget _buildPhotoCaptureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("LIVE PHOTO VERIFICATION", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: navyBlue, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _isUploadingPhoto ? null : _captureLivePhoto,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F5EF),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _uploadedPhotoUrl != null ? Colors.green : Colors.grey.shade300, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(_uploadedPhotoUrl != null ? Icons.check_circle : Icons.camera_alt_outlined, color: _uploadedPhotoUrl != null ? Colors.green : saffron, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _isUploadingPhoto ? "Uploading securely..." : _uploadedPhotoUrl != null ? "Photo Verified (Tap to retake)" : "Tap to open camera",
                    style: TextStyle(color: _uploadedPhotoUrl != null ? Colors.green.shade700 : darkNavy, fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                ),
                if (_isUploadingPhoto)
                  const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: saffron))
                else if (_capturedImage != null)
                  ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.file(_capturedImage!, width: 36, height: 36, fit: BoxFit.cover)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("PASSWORD", style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: navyBlue, letterSpacing: 1.5)),
        const SizedBox(height: 8),
        TextField(
          controller: passwordController,
          obscureText: isPasswordHidden,
          style: const TextStyle(fontSize: 15, color: darkNavy, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: "Create a strong password",
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
            prefixIcon: const Icon(Icons.lock_outline, color: saffron, size: 22),
            suffixIcon: IconButton(
              icon: Icon(isPasswordHidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: Colors.grey.shade500, size: 20),
              onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden),
            ),
            filled: true,
            fillColor: const Color(0xFFF7F5EF),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey.shade300, width: 1.5)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: saffron, width: 2)),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
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
    final centers = [Offset(size.width * 0.88, size.height * 0.06), Offset(size.width * 0.05, size.height * 0.45), Offset(size.width * 0.7, size.height * 0.88)];
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