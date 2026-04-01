import 'dart:io';
import 'dart:math' as math;
import 'package:corporator_app/services/media_service.dart';
import 'package:corporator_app/services/super_admin_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class CorporatorRegistrationPage extends StatefulWidget {
  const CorporatorRegistrationPage({super.key});

  @override
  State<CorporatorRegistrationPage> createState() => _CorporatorRegistrationPageState();
}

class _CorporatorRegistrationPageState extends State<CorporatorRegistrationPage> with TickerProviderStateMixin {
  final nameController = TextEditingController();
  final nicknameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mobileController = TextEditingController();
  final adharController = TextEditingController();
  final areaController = TextEditingController();

  final MediaService _mediaServices = MediaService();
  final SuperAdminService _superAdminServices = SuperAdminService();
  
  bool isLoading = false;
  bool isPasswordHidden = true;

  // ── Group Assignment State ──
  bool _autoCreateGroup = true; 
  List<Map<String, dynamic>> _existingGroups = [];
  int? _selectedGroupId;

  // ── Camera & Cloudinary State ──
  File? _capturedImage;
  String? _uploadedPhotoUrl;
  bool _isUploadingPhoto = false;

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  static const Color saffron = Color(0xFFFF6700);
  static const Color deepSaffron = Color(0xFFE55C00); 
  static const Color gold = Color(0xFFFFD700);
  static const Color navyBlue = Color(0xFF002868);
  static const Color darkNavy = Color(0xFF001A45);
  static const Color white = Color(0xFFFFFDF7);

  @override
  void initState() {
    super.initState();
    _fetchGroups();
    _pulseController = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  Future<void> _fetchGroups() async {
    try {
      final groups = await _superAdminServices.getAdminGroupsForDropdown();
      setState(() => _existingGroups = groups);
    } catch (e) {
      debugPrint("Error loading groups: $e");
    }
  }

  @override
  void dispose() {
    [nameController, nicknameController, emailController, passwordController, mobileController, adharController, areaController].forEach((c) => c.dispose());
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _captureLivePhoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (pickedFile != null) {
      setState(() { _capturedImage = File(pickedFile.path); _isUploadingPhoto = true; });
      try {
        String url = await _mediaServices.uploadMediaToCloudinary(_capturedImage!);
        setState(() { _uploadedPhotoUrl = url; _isUploadingPhoto = false; });
      } catch (e) {
        setState(() { _capturedImage = null; _isUploadingPhoto = false; });
      }
    }
  }

  Future<void> registerCorporator() async {
    // ── 1. STRICT FRONTEND VALIDATION ──
    if (nameController.text.trim().isEmpty ||
        nicknameController.text.trim().isEmpty ||
        emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        mobileController.text.trim().length != 10 ||
        adharController.text.trim().length != 12 ||
        _uploadedPhotoUrl == null ||
        (!_autoCreateGroup && _selectedGroupId == null)) {
      
      _showMsg(
        "Validation Failed", 
        "Please fill all fields, ensure 10-digit Mobile, 12-digit Aadhaar, and capture a Live Photo.", 
        Colors.red.shade800
      );
      return;
    }

    try {
      setState(() => isLoading = true);
      
      await _superAdminServices.registerCorporator(
        nickname: nicknameController.text.trim(),
        name: nameController.text.trim(),
        mobileNo: mobileController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        livePhotoUrl: _uploadedPhotoUrl!,
        area: areaController.text.trim(),
        adharNo: adharController.text.trim(),
        autoCreateGroup: _autoCreateGroup,
        existingAdminGroupId: _selectedGroupId,
      );

      _showMsg("Success", "Corporator Registered Successfully!", saffron);
      _resetForm();
    } catch (e) {
      _showMsg("Error", e.toString().replaceAll("Exception: ", ""), Colors.red.shade800);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showMsg(String title, String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.bold)),
      backgroundColor: color, behavior: SnackBarBehavior.floating,
    ));
  }

  void _resetForm() {
    [nameController, nicknameController, emailController, passwordController, mobileController, adharController, areaController].forEach((c) => c.clear());
    setState(() { _capturedImage = null; _uploadedPhotoUrl = null; _selectedGroupId = null; _autoCreateGroup = true; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [darkNavy, navyBlue, Color(0xFF003580)]))),
          Positioned.fill(child: CustomPaint(painter: _ChakraPatternPainter())),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        _buildSectionCard(headerTitle: "PERSONAL INFO", headerIcon: Icons.person_outline, children: [
                          _buildField(controller: nameController, label: "Full Name", hint: "Full name", icon: Icons.person_outline),
                          const SizedBox(height: 16),
                          Row(children: [
                            Expanded(child: _buildField(controller: nicknameController, label: "Nickname", hint: "Short name", icon: Icons.badge_outlined)),
                            const SizedBox(width: 12),
                            Expanded(child: _buildField(controller: mobileController, label: "Mobile", hint: "10-digits", icon: Icons.phone_android, isNumeric: true, limit: 10)),
                          ]),
                          const SizedBox(height: 16),
                          _buildField(controller: adharController, label: "Aadhar", hint: "12-digits", icon: Icons.credit_card, isNumeric: true, limit: 12),
                          const SizedBox(height: 16),
                          _buildField(controller: areaController, label: "Area (Optional)", hint: "Enter jurisdiction area", icon: Icons.location_on_outlined),
                        ]),
                        const SizedBox(height: 16),
                        _buildGroupAssignmentCard(),
                        const SizedBox(height: 16),
                        _buildSectionCard(headerTitle: "SECURITY & VERIFICATION", headerIcon: Icons.verified_user_outlined, children: [
                          _buildField(controller: emailController, label: "Email", hint: "Official email", icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                          const SizedBox(height: 16),
                          _buildPasswordField(),
                          const SizedBox(height: 20),
                          _buildPhotoCaptureSection(),
                        ]),
                        const SizedBox(height: 32),
                        _buildRegisterButton(),
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

  Widget _buildGroupAssignmentCard() {
    return _buildSectionCard(
      headerTitle: "GROUP ASSIGNMENT", 
      headerIcon: Icons.group_work_outlined, 
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Auto-Create Unique Group", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: navyBlue)),
            Switch(
              value: _autoCreateGroup, 
              activeColor: saffron,
              onChanged: (val) => setState(() => _autoCreateGroup = val),
            ),
          ],
        ),
        if (!_autoCreateGroup) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            value: _selectedGroupId,
            hint: Text(_existingGroups.isEmpty ? "Loading groups..." : "Select Existing Group", style: const TextStyle(fontSize: 14)),
            decoration: InputDecoration(
              filled: true, fillColor: const Color(0xFFF7F5EF),
              prefixIcon: const Icon(Icons.list_alt, color: saffron),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            items: _existingGroups.map((g) => DropdownMenuItem<int>(value: g['id'], child: Text(g['groupName']))).toList(),
            onChanged: (val) => setState(() => _selectedGroupId = val),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          _autoCreateGroup ? "A dedicated group will be created using the corporator's nickname." : "Corporator will join a shared organizational group.",
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600, fontStyle: FontStyle.italic),
        )
      ]
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(children: [
        ScaleTransition(scale: _pulseAnimation, child: Container(width: 42, height: 42, decoration: const BoxDecoration(shape: BoxShape.circle, gradient: RadialGradient(colors: [gold, saffron])), child: const Icon(Icons.account_balance, size: 20, color: darkNavy))),
        const SizedBox(width: 14),
        const Text("ONBOARD CORPORATOR", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.5)),
      ]),
    );
  }

  Widget _buildField({required TextEditingController controller, required String label, required String hint, required IconData icon, TextInputType keyboardType = TextInputType.text, int? limit, bool isNumeric = false}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: navyBlue, letterSpacing: 1.2)),
      const SizedBox(height: 6),
      TextField(
        controller: controller, keyboardType: isNumeric ? TextInputType.number : keyboardType,
        inputFormatters: [if (isNumeric) FilteringTextInputFormatter.digitsOnly, if (limit != null) LengthLimitingTextInputFormatter(limit)],
        style: const TextStyle(fontSize: 15, color: darkNavy, fontWeight: FontWeight.w600),
        decoration: InputDecoration(hintText: hint, counterText: "", prefixIcon: Icon(icon, color: saffron, size: 20), filled: true, fillColor: const Color(0xFFF7F5EF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none), contentPadding: const EdgeInsets.symmetric(vertical: 14)),
      ),
    ]);
  }

  Widget _buildPasswordField() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text("PASSWORD", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: navyBlue, letterSpacing: 1.2)),
      const SizedBox(height: 6),
      TextField(
        controller: passwordController, obscureText: isPasswordHidden,
        style: const TextStyle(fontSize: 15, color: darkNavy, fontWeight: FontWeight.w600),
        decoration: InputDecoration(hintText: "••••••••", prefixIcon: const Icon(Icons.lock_outline, color: saffron, size: 20), suffixIcon: IconButton(icon: Icon(isPasswordHidden ? Icons.visibility_off : Icons.visibility, size: 18), onPressed: () => setState(() => isPasswordHidden = !isPasswordHidden)), filled: true, fillColor: const Color(0xFFF7F5EF), border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none)),
      ),
    ]);
  }

  Widget _buildPhotoCaptureSection() {
    return InkWell(
      onTap: _isUploadingPhoto ? null : _captureLivePhoto,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: const Color(0xFFF7F5EF), borderRadius: BorderRadius.circular(10), border: Border.all(color: _uploadedPhotoUrl != null ? Colors.green : Colors.grey.shade300)),
        child: Row(children: [
          Icon(_uploadedPhotoUrl != null ? Icons.check_circle : Icons.camera_alt, color: _uploadedPhotoUrl != null ? Colors.green : saffron),
          const SizedBox(width: 12),
          Text(_isUploadingPhoto ? "Uploading..." : _uploadedPhotoUrl != null ? "Photo Verified" : "Capture Live Photo", style: const TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          if (_isUploadingPhoto) const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: saffron))
        ]),
      ),
    );
  }

  Widget _buildRegisterButton() {
    // ── TRIGGERS SPINNER IF API IS LOADING *OR* PHOTO IS UPLOADING ──
    final bool isBusy = isLoading || _isUploadingPhoto;
    
    return Container(
      width: double.infinity, 
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12), 
        // Remove the gradient and turn grey when busy
        gradient: isBusy ? null : const LinearGradient(colors: [saffron, deepSaffron]),
        color: isBusy ? Colors.grey.shade500 : null,
      ),
      child: ElevatedButton(
        // Disable the button entirely if busy
        onPressed: isBusy ? null : registerCorporator,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent, 
          shadowColor: Colors.transparent
        ),
        child: isBusy 
            ? const SizedBox(
                width: 24, 
                height: 24, 
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
              ) 
            : const Text(
                "FINALIZE REGISTRATION", 
                style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)
              ),
      ),
    );
  }

  Widget _buildSectionCard({required String headerTitle, required IconData headerIcon, required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(color: white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)]),
      child: Column(children: [
        Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16), decoration: const BoxDecoration(color: navyBlue, borderRadius: BorderRadius.vertical(top: Radius.circular(16))), child: Row(children: [Icon(headerIcon, color: gold, size: 16), const SizedBox(width: 8), Text(headerTitle, style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1.5))])),
        Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children))
      ]),
    );
  }
}

class _ChakraPatternPainter extends CustomPainter {
  @override void paint(Canvas canvas, Size size) {
    final p = Paint()..color = Colors.white.withOpacity(0.02)..style = PaintingStyle.stroke;
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.1), 150, p);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.8), 200, p);
  }
  @override bool shouldRepaint(CustomPainter old) => false;
}