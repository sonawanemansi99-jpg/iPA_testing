import 'package:corporator_app/core/widgets/appbar.dart';
import 'package:corporator_app/core/widgets/gradient.dart';
import 'package:corporator_app/features/QR/admin_qr_download_page.dart';
import 'package:corporator_app/features/auth/presentation/login.dart';
import 'package:corporator_app/features/auth/services/auth_service.dart';
import 'package:corporator_app/features/complaints/presentation/screens/admin_complaints_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MainScaffold extends StatefulWidget {
  final Widget body;
  final String title;
  final Widget? floatingActionButton;

  const MainScaffold({
    super.key,
    required this.body,
    required this.title,
    this.floatingActionButton,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  bool isMenuOpen = false;
  final AuthService _authService = AuthService();

  void toggleMenu() {
    setState(() => isMenuOpen = !isMenuOpen);
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final menuWidth = width * 0.65;

    void downloadQR() {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminQRDownloadPage(
            adminId: FirebaseAuth.instance.currentUser!.uid,
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          Scaffold(
            appBar: appBar(
              context,
              title: widget.title,
              hamburger: true,
              onMenuPressed: toggleMenu,
            ),

            body: widget.body,
            floatingActionButton: widget.floatingActionButton,
          ),

          if (isMenuOpen)
            GestureDetector(
              onTap: toggleMenu,
              child: Container(color: Colors.black.withOpacity(0.4)),
            ),

          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            left: isMenuOpen ? 0 : -menuWidth,
            top: 0,
            bottom: 0,
            child: Container(
              width: menuWidth,
              decoration: const BoxDecoration(
                gradient: AppGradients.glowGradient,
                color: Colors.white,
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(20),
                ),
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 15)],
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "User Name",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Divider(),
                      menuItem(Icons.analytics_rounded, "Dashboard"),
                      menuItem(Icons.person, "Profile"),
                      menuItem(Icons.admin_panel_settings_outlined, "Password"),
                      menuItem(Icons.article, "Complaints"),
                      menuItem(Icons.all_inbox_rounded, "Complaint History"),
                      menuItem(Icons.qr_code, "Download QR", onTap: downloadQR),
                      Padding(
                        padding: const EdgeInsets.all(10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            shadowColor: Colors.black87,
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () {
                            try {
                              _authService.logout();

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Login Successful"),
                                ),
                              );

                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: (_) => Login()),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(e.toString())),
                              );
                            }
                          },
                          child: Padding(
                            padding: EdgeInsetsGeometry.all(10),
                            child: Row(
                              children: [
                                Icon(Icons.logout_rounded, color: Colors.white),
                                SizedBox(width: 5),
                                const Text(
                                  "Logout",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
    );
  }

  Widget menuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: onTap,
    );
  }
}
