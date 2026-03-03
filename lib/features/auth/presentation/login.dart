import 'package:corporator_app/features/auth/presentation/forgot_password_page.dart';
import 'package:corporator_app/features/complaints/presentation/screens/list_complaints.dart';
import 'package:corporator_app/corporator/presentations/corporator_dashboard.dart';
import 'package:corporator_app/superadmin/presentation/pages/register_corporator.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isPasswordHidden = true;

  final AuthService authService = AuthService();

  Future<void> loginUser() async {
  try {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    /// 1️⃣ Check for Super Admin FIRST (Hardcoded)
    if (email == "superadmin@gmail.com" && password == "superadmin@123") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => CorporatorRegistrationPage()),
      );
      return;
    }

    /// 🔵 2️⃣ Otherwise check Firebase for Admin & Corporator
    final userData = await authService.login(
      email: email,
      password: password,
    );

    if (userData == null) {
      throw Exception("User data not found");
    }

    String role =
        (userData["role"]?.toString() ?? "").trim().toUpperCase();
    String uid = userData["uid"];

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Login Successful")),
    );

    if (role == "ADMIN") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ListComplaints(adminId: uid),
        ),
      );
    } else if (role == "CORPORATOR") {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CorporatorDashboard(),
        ),
      );
    } else {
      throw Exception("Unknown role");
    }
  } catch (e) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage("assets/images/bg.png"),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Card(
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Login",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 20),

                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      labelText: "Email",
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 15),

                  TextField(
                    controller: passwordController,
                    obscureText: isPasswordHidden,
                    decoration: InputDecoration(
                      labelText: "Password",
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),

                      suffixIcon: IconButton(
                        icon: Icon(
                          isPasswordHidden
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            isPasswordHidden = !isPasswordHidden;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: loginUser,
                      child: const Text("Login"),
                    ),
                  ),

                  const SizedBox(height: 10),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ForgotPasswordPage(),
                        ),
                      );
                    },
                    child: const Text(
                      "Forgot password?",
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
