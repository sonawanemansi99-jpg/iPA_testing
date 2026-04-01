import 'package:corporator_app/core/widgets/custom_snack_bar.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/services/super_admin_services.dart';
import 'package:corporator_app/superadmin/admin_list_page.dart';
import 'package:flutter/material.dart';

class SuperAdminInspectorPage extends StatefulWidget {
  final Map<String, dynamic> adminData;

  const SuperAdminInspectorPage({Key? key, required this.adminData}) : super(key: key);

  @override
  State<SuperAdminInspectorPage> createState() => _SuperAdminInspectorPageState();
}

class _SuperAdminInspectorPageState extends State<SuperAdminInspectorPage> {
  final SuperAdminService _services = SuperAdminService();
  
  bool _isLoading = true;
  late bool _isActive;
  int _assignedAdminsCount = 0;

  static const gold = Color(0xFFFFD700);
  static const darkNavy = Color(0xFF001A45);
  static const warmWhite = Color(0xFFFFFDF7);
  static const rootPurple = Color(0xFF512DA8);

  @override
  void initState() {
    super.initState();
    _isActive = widget.adminData['isActive'] ?? false;
    _fetchAssignedAdminsCount();
  }

  Future<void> _fetchAssignedAdminsCount() async {
    try {
      final admins = await _services.getAdminsBySuperAdmin(widget.adminData['id']);
      setState(() => _assignedAdminsCount = admins.length);
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, "Could not fetch assigned admins.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAccountStatus() async {
    final bool newStatus = !_isActive;
    setState(() => _isActive = newStatus); 

    try {
      await _services.toggleSuperAdminStatus(widget.adminData['id'], newStatus);
      if (!mounted) return;
      CustomSnackBar.showSuccess(context, newStatus ? "Root Account Activated" : "Root Account Suspended");
    } catch (e) {
      setState(() => _isActive = !newStatus); 
      if (mounted) CustomSnackBar.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Root Inspector",
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [darkNavy, Color(0xFF002868), Color(0xFF003A8C)]),
        ),
        child: Column(
          children: [
            Container(height: 4, color: rootPurple),
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator(color: rootPurple))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildProfileCard(),
                        const SizedBox(height: 24),
                        
                        _buildStatCard("ASSIGNED CORPORATORS", _assignedAdminsCount.toString()),
                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(
                                builder: (_) => AdminListPage(superAdminId: widget.adminData['id']),
                              ));
                            },
                            icon: const Icon(Icons.group, color: Colors.white),
                            label: const Text("VIEW ASSIGNED CORPORATORS", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: rootPurple,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: warmWhite.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: rootPurple.withOpacity(0.5), width: 1),
      ),
      child: Column(
        children: [
          Text(count, style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
        ],
      ),
    );
  }

  Widget _buildProfileCard() {
    final admin = widget.adminData;
    final photoUrl = admin['photoUrl'] ?? '';

    return Container(
      decoration: BoxDecoration(color: warmWhite, borderRadius: BorderRadius.circular(20)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              decoration: BoxDecoration(color: _isActive ? rootPurple : Colors.red[900]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(_isActive ? "ROOT ACCESS ACTIVE" : "ROOT ACCESS SUSPENDED", style: const TextStyle(color: gold, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  Switch(value: _isActive, activeColor: gold, onChanged: (val) => _toggleAccountStatus())
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: _isActive ? rootPurple : Colors.red, width: 2), image: photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null),
                    child: photoUrl.isEmpty ? const Icon(Icons.security, color: darkNavy, size: 38) : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(admin['name'] ?? 'Unknown', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: darkNavy)),
                        const SizedBox(height: 8),
                        Row(children: [const Icon(Icons.email, size: 14, color: rootPurple), const SizedBox(width: 6), Text(admin['email'] ?? 'N/A', style: const TextStyle(fontSize: 12))]),
                        const SizedBox(height: 4),
                        Row(children: [const Icon(Icons.phone, size: 14, color: rootPurple), const SizedBox(width: 6), Text(admin['mobileNumber'] ?? 'N/A', style: const TextStyle(fontSize: 12))]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}