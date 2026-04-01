import 'dart:io';
import 'package:corporator_app/core/widgets/custom_snack_bar.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/services/super_admin_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

class EditAdminPage extends StatefulWidget {
  final Map<String, dynamic> adminData;
  const EditAdminPage({Key? key, required this.adminData}) : super(key: key);

  @override
  State<EditAdminPage> createState() => _EditAdminPageState();
}

class _EditAdminPageState extends State<EditAdminPage> {
  final _formKey = GlobalKey<FormState>();
  final SuperAdminService _services = SuperAdminService();

  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _mobileController;
  late TextEditingController _adharController;
  late TextEditingController _areaController;

  bool _isLoading = false;
  File? _selectedImage;

  // Theme Colors consistent with Dashboard
  static const saffron = Color(0xFFFF6700);
  static const gold = Color(0xFFFFD700);
  static const navyBlue = Color(0xFF002868);
  static const darkNavy = Color(0xFF001A45);

  @override
  void initState() {
    super.initState();
    final data = widget.adminData;
    _nameController = TextEditingController(text: data['name']);
    _nicknameController = TextEditingController(text: data['nickname']);
    _emailController = TextEditingController(text: data['email']);
    _mobileController = TextEditingController(text: data['mobileNumber']);
    _adharController = TextEditingController(text: data['adharNo']);
    _areaController = TextEditingController(text: data['area']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _adharController.dispose();
    _areaController.dispose();
    super.dispose();
  }

  Future<void> _updateAdmin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      String? photoUrl = widget.adminData['livePhotoUrl'];

      // Handle Image Upload Logic here if necessary

      final payload = {
        "name": _nameController.text.trim(),
        "nickname": _nicknameController.text.trim(),
        "email": _emailController.text.trim(),
        "mobileNumber": _mobileController.text.trim(),
        "adharNo": _adharController.text.trim(),
        "area": _areaController.text.trim(),
        "livePhotoUrl": photoUrl,
      };

      await _services.updateAdmin(widget.adminData['adminId'], payload);
      if (!mounted) return;

      CustomSnackBar.showSuccess(context, "Corporator Profile Updated");
      Navigator.pop(context, true);
    } catch (e) {
      CustomSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Edit Corporator",
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkNavy, navyBlue, Color(0xFF003A8C)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildImagePicker(),
                const SizedBox(height: 32),

                _buildField(_nameController, "Full Name", Icons.person_outline),
                _buildField(
                  _nicknameController,
                  "Nickname",
                  Icons.badge_outlined,
                ),
                _buildField(
                  _emailController,
                  "Email Address",
                  Icons.email_outlined,
                ),
                _buildField(
                  _mobileController,
                  "Mobile Number",
                  Icons.phone_android_outlined,
                  limit: 10
                ),
                _buildField(
                  _adharController,
                  "Aadhaar Number",
                  Icons.credit_card,
                  limit: 10
                ),
                _buildField(
                  _areaController,
                  "Assigned Area/Ward",
                  Icons.location_city_outlined,
                  isRequired: false,
                ),
                const SizedBox(height: 32),

                // ── TRICOLOR STYLE BUTTON ──
                Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: saffron.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updateAdmin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: saffron,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "SAVE CHANGES",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

Widget _buildField(
  TextEditingController ctrl,
  String label,
  IconData icon, {
  bool isRequired = true,
  int? limit,           // 👈 Added for physical digit block
  bool isNumeric = false, // 👈 Added to force numeric keyboard/logic
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: TextFormField(
      controller: ctrl,
      // ── SET KEYBOARD TYPE ──
      keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
      
      // ── THE PHYSICAL WALL (Formatters) ──
      inputFormatters: [
        if (isNumeric) FilteringTextInputFormatter.digitsOnly,
        if (limit != null) LengthLimitingTextInputFormatter(limit),
      ],
      
      style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w600,
        fontSize: 16,
      ),
      cursorColor: gold,
      decoration: InputDecoration(
        labelText: label,
        // ── HIDE CHARACTER COUNTER ──
        counterText: "", 
        labelStyle: TextStyle(
          color: Colors.white.withOpacity(0.6),
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: gold,
          fontWeight: FontWeight.bold,
        ),
        prefixIcon: Icon(icon, color: gold, size: 22),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        hintText: isRequired ? null : "Optional",
        hintStyle: TextStyle(
          color: Colors.white.withOpacity(0.2),
          fontSize: 12,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: gold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.redAccent),
        ),
      ),
      // ── UPDATED VALIDATOR LOGIC ──
      validator: (v) {
        final val = v?.trim() ?? "";
        if (isRequired && val.isEmpty) {
          return "$label cannot be empty";
        }
        // Strict length check for Mobile/Aadhaar
        if (limit != null && val.isNotEmpty && val.length != limit) {
          return "$label must be exactly $limit digits";
        }
        return null;
      },
    ),
  );
}

  Widget _buildImagePicker() {
    return Center(
      child: GestureDetector(
        onTap: () async {
          final img = await ImagePicker().pickImage(
            source: ImageSource.gallery,
          );
          if (img != null) setState(() => _selectedImage = File(img.path));
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(colors: [gold, saffron]),
                boxShadow: [
                  BoxShadow(
                    color: gold.withOpacity(0.4),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: 54,
                backgroundColor: darkNavy,
                backgroundImage: _selectedImage != null
                    ? FileImage(_selectedImage!)
                    : (widget.adminData['livePhotoUrl'] != null &&
                              widget.adminData['livePhotoUrl'].isNotEmpty
                          ? NetworkImage(widget.adminData['livePhotoUrl'])
                                as ImageProvider
                          : null),
                child:
                    (_selectedImage == null &&
                        (widget.adminData['livePhotoUrl'] == null ||
                            widget.adminData['livePhotoUrl'].isEmpty))
                    ? const Icon(Icons.person, size: 50, color: gold)
                    : null,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 4,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: saffron,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
