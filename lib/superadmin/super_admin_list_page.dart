import 'package:corporator_app/core/widgets/custom_snack_bar.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/services/super_admin_services.dart';
import 'package:corporator_app/superadmin/register_super_admin_page.dart';
import 'package:corporator_app/superadmin/super_admin_inspector_page.dart';
import 'package:flutter/material.dart';

class SuperAdminListPage extends StatefulWidget {
  const SuperAdminListPage({Key? key}) : super(key: key);

  @override
  State<SuperAdminListPage> createState() => _SuperAdminListPageState();
}

class _SuperAdminListPageState extends State<SuperAdminListPage> {
  final SuperAdminService _services = SuperAdminService();
  
  List<dynamic> _allSuperAdmins = [];
  List<dynamic> _filteredSuperAdmins = [];
  bool _isLoading = true;
  String _searchQuery = "";

  static const gold = Color(0xFFFFD700);
  static const darkNavy = Color(0xFF001A45);
  static const warmWhite = Color(0xFFFFFDF7);
  static const rootPurple = Color(0xFF512DA8);

  @override
  void initState() {
    super.initState();
    _fetchSuperAdmins();
  }

  Future<void> _fetchSuperAdmins() async {
    setState(() => _isLoading = true);
    try {
      final data = await _services.getAllSuperAdmins();
      setState(() {
        _allSuperAdmins = data;
        _filteredSuperAdmins = data;
      });
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(int id, bool currentStatus, int index) async {
    final newStatus = !currentStatus;
    setState(() => _filteredSuperAdmins[index]['isActive'] = newStatus);

    try {
      await _services.toggleSuperAdminStatus(id, newStatus);
      if (!mounted) return;
      CustomSnackBar.showSuccess(context, newStatus ? "Super Admin Activated" : "Super Admin Suspended");
    } catch (e) {
      setState(() => _filteredSuperAdmins[index]['isActive'] = currentStatus);
      if (mounted) CustomSnackBar.showError(context, e.toString());
    }
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
      _filteredSuperAdmins = _allSuperAdmins.where((s) {
        final name = (s['name'] ?? '').toLowerCase();
        final email = (s['email'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) || email.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Super Admins",
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterSuperAdminPage()));
          _fetchSuperAdmins();
        },
        backgroundColor: rootPurple,
        icon: const Icon(Icons.security, color: Colors.white),
        label: const Text("NEW ROOT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [darkNavy, Color(0xFF002868), Color(0xFF003A8C)]),
        ),
        child: Column(
          children: [
            Container(height: 3, color: rootPurple),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _filter,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search Name or Email...",
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                  prefixIcon: const Icon(Icons.search, color: gold),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.1),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
                ),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: gold))
                  : _filteredSuperAdmins.isEmpty
                      ? Center(child: Text("No Super Admins found.", style: TextStyle(color: Colors.white.withOpacity(0.5))))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: _filteredSuperAdmins.length,
                          itemBuilder: (context, index) => _buildCard(_filteredSuperAdmins[index], index),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> admin, int index) {
    final bool isActive = admin['isActive'] ?? false;
    final String name = admin['name'] ?? 'Unknown';
    final String email = admin['email'] ?? 'No Email';
    final String photoUrl = admin['photoUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: warmWhite, borderRadius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SuperAdminInspectorPage(adminData: admin))),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isActive ? rootPurple : Colors.grey, width: 2),
                    image: photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                    color: darkNavy.withOpacity(0.1),
                  ),
                  child: photoUrl.isEmpty ? const Icon(Icons.security, color: rootPurple) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkNavy)),
                      const SizedBox(height: 4),
                      Text(email, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Switch(
                      value: isActive,
                      activeColor: rootPurple,
                      onChanged: (val) => _toggleStatus(admin['id'], isActive, index),
                    ),
                    Text(
                      isActive ? "ACTIVE" : "SUSPENDED",
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.green[700] : Colors.red[700]),
                    )
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}