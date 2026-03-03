import 'package:corporator_app/corporator/services/corporator_service.dart';
import 'package:corporator_app/features/auth/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final CorporatorService corporatorService = CorporatorService();
  final AuthService authService = AuthService();

  final nameController = TextEditingController();
  final mobileController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final locationController = TextEditingController();

  List<TextEditingController> zoneControllers = [TextEditingController()];

  bool isLoading = false;
  bool isPasswordHidden = true;
  bool isConfirmPasswordHidden = true;

  Future<void> registerAdmin() async {
    if (passwordController.text.trim() !=
        confirmPasswordController.text.trim()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));
      return;
    }

    final corporator = _auth.currentUser;
    if (corporator == null) return;

    final corporatorId = corporator.uid;

    final zoneNames = zoneControllers
        .map((c) => c.text.trim())
        .where((z) => z.isNotEmpty)
        .toList();

    if (zoneNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("At least one zone is required")),
      );
      return;
    }

    setState(() => isLoading = true);

    final result = await authService.registerAdmin(
      name: nameController.text.trim(),
      mobile: mobileController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      location: locationController.text.trim(),
      corporatorId: corporatorId,
    );

    if (result == null || result.length < 10) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result ?? "Error")));
      setState(() => isLoading = false);
      return;
    }

    final adminId = result;

    await corporatorService.allocateZonesToAdmin(
      adminId: adminId,
      corporatorId: corporatorId,
      zoneNames: zoneNames,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Admin Registered Successfully")),
    );

    setState(() => isLoading = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Create Admin"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField("Name", nameController, Icons.person),
            const SizedBox(height: 15),

            _buildTextField("Mobile", mobileController, Icons.phone),
            const SizedBox(height: 15),

            _buildTextField("Email", emailController, Icons.email),
            const SizedBox(height: 15),

            _buildPasswordField(),
            const SizedBox(height: 15),

            _buildConfirmPasswordField(),
            const SizedBox(height: 15),

            _buildTextField("Location", locationController, Icons.location_on),
            const SizedBox(height: 25),

            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Assign Zones",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),

            const SizedBox(height: 10),

            Column(
              children: List.generate(zoneControllers.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: zoneControllers[index],
                          decoration: const InputDecoration(
                            labelText: "Enter Zone Name",
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (index != 0)
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              zoneControllers.removeAt(index);
                            });
                          },
                        ),
                    ],
                  ),
                );
              }),
            ),

            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    zoneControllers.add(TextEditingController());
                  });
                },
                icon: const Icon(Icons.add),
                label: const Text("Add More Zone"),
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : registerAdmin,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Register Admin",
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
  ) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: passwordController,
      obscureText: isPasswordHidden,
      decoration: InputDecoration(
        labelText: "Password",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordHidden ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              isPasswordHidden = !isPasswordHidden;
            });
          },
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: confirmPasswordController,
      obscureText: isConfirmPasswordHidden,
      decoration: InputDecoration(
        labelText: "Confirm Password",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        suffixIcon: IconButton(
          icon: Icon(
            isConfirmPasswordHidden ? Icons.visibility_off : Icons.visibility,
          ),
          onPressed: () {
            setState(() {
              isConfirmPasswordHidden = !isConfirmPasswordHidden;
            });
          },
        ),
      ),
    );
  }
}
