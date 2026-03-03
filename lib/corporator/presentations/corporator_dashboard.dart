import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corporator_app/core/widgets/gradient.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/corporator/presentations/create_zone_dialog.dart';
import 'package:corporator_app/features/auth/presentation/register.dart';
import 'package:corporator_app/corporator/presentations/admin_list_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CorporatorDashboard extends StatefulWidget {
  const CorporatorDashboard({super.key});

  @override
  State<CorporatorDashboard> createState() => _CorporatorDashboardState();

  static Widget _statTile({required String title, required String count}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: BoxDecoration(
        gradient: AppGradients.darkGradient,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Text(
            count,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _CorporatorDashboardState extends State<CorporatorDashboard> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> fetchCurrentUserData() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final docSnap = await _firestore.collection('users').doc(user.uid).get();
    if (!docSnap.exists) return null;

    return docSnap.data(); // Contains name, email, mobileNo, role, etc.
  }

  void adminList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AdminListPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Dashboard",
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppGradients.glowGradient,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    blurRadius: 8,
                    color: Colors.black.withOpacity(0.08),
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    // backgroundImage:
                    //     AssetImage("assets/images/logo.jpg"),
                  ),

                  const SizedBox(width: 16),

                  FutureBuilder<Map<String, dynamic>?>(
                    future: fetchCurrentUserData(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      }
                      if (!snapshot.hasData || snapshot.data == null) {
                        return const Text("User data not found");
                      }

                      final userData = snapshot.data!;
                      final name = userData['name'] ?? '';
                      final email = userData['email'] ?? '';
                      final mobileNo = userData['mobileNo'] ?? '';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Email: $email",
                            style: TextStyle(color: Colors.white),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Mob: $mobileNo",
                            style: TextStyle(color: Colors.white),
                          ),
                          // Optionally add ward/zone if stored in Firestore
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: adminList,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "View All Admins",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const Register()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Add Admin",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),

            // const SizedBox(height: 14),
            // SizedBox(
            //   width: double.infinity,
            //   child: ElevatedButton(
            //     onPressed: () {
            //       showDialog(
            //         context: context,
            //         builder: (_) => const CreateZoneDialog(),
            //       );
            //     },
            //     style: ElevatedButton.styleFrom(
            //       backgroundColor: Colors.white,
            //       padding: const EdgeInsets.symmetric(vertical: 14),
            //       shape: RoundedRectangleBorder(
            //         borderRadius: BorderRadius.circular(12),
            //       ),
            //     ),
            //     child: const Text(
            //       "Create Zone",
            //       style: TextStyle(fontSize: 16, color: Colors.black),
            //     ),
            //   ),
            // ),

            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Customize design",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
