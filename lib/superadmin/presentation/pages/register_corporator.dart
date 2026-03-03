import 'package:corporator_app/features/auth/presentation/login.dart';
import 'package:corporator_app/superadmin/services/superadmin_services.dart';
import 'package:flutter/material.dart';

class CorporatorRegistrationPage extends StatefulWidget {
  const CorporatorRegistrationPage({super.key});

  @override
  State<CorporatorRegistrationPage> createState() =>
      _CorporatorRegistrationPageState();
}

class _CorporatorRegistrationPageState
    extends State<CorporatorRegistrationPage> {

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final mobileController = TextEditingController();
  final wardController = TextEditingController();
  final zoneController = TextEditingController();

  final SuperadminServices superadminServices = SuperadminServices();
  bool isLoading = false;
  bool isPasswordHidden = true;

  Future<void> registerCorporator() async {
    if (nameController.text.isEmpty ||
        emailController.text.isEmpty ||
        passwordController.text.isEmpty ||
        mobileController.text.isEmpty ||
        wardController.text.isEmpty ||
        zoneController.text.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    try {
      setState(() => isLoading = true);

      await superadminServices.registerCorporator(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
        mobileNo: mobileController.text.trim(),
        ward: wardController.text.trim(),
        zone: zoneController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Corporator Registered Successfully")),
      );

      // Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    mobileController.dispose();
    wardController.dispose();
    zoneController.dispose();
    super.dispose();
  }

  Future<void> logout() async {
  try {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_)=> const Login()));
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Logout failed: $e")),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: const Text("Create Corporator"),
  actions: [
    IconButton(
      icon: const Icon(Icons.logout),
      onPressed: logout,
    ),
  ],
),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            children: [

              _buildTextField("Name", nameController, Icons.person),
              const SizedBox(height: 15),

              _buildTextField("Email", emailController, Icons.email),
              const SizedBox(height: 15),

              TextField(
                controller: passwordController,
                obscureText: isPasswordHidden,
                decoration: InputDecoration(
                  labelText: "Password",
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(isPasswordHidden
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () {
                      setState(() {
                        isPasswordHidden = !isPasswordHidden;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              _buildTextField("Mobile Number", mobileController, Icons.phone),
              const SizedBox(height: 15),

              _buildTextField("Ward", wardController, Icons.map),
              const SizedBox(height: 15),

              _buildTextField("Zone", zoneController, Icons.location_city),
              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : registerCorporator,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Register Corporator"),
                ),
              ),
            ],
          ),
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
        border: const OutlineInputBorder(),
      ),
    );
  }
}