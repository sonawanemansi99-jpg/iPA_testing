import 'package:corporator_app/core/widgets/custom_snack_bar.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/services/super_admin_services.dart';
import 'package:corporator_app/superadmin/admin_inspector_page.dart';
import 'package:corporator_app/superadmin/register_corporator.dart'; // Import the registration page
import 'package:flutter/material.dart';

class AdminListPage extends StatefulWidget {
  final int? superAdminId;
  AdminListPage({Key? key, this.superAdminId}) : super(key: key);
  @override
  State<AdminListPage> createState() => _AdminListPageState();
}

class _AdminListPageState extends State<AdminListPage> {
  final SuperAdminService _superAdminServices = SuperAdminService(); 
  
  List<dynamic> _allAdmins = [];
  List<dynamic> _filteredAdmins = [];
  bool _isLoading = true;
  String _searchQuery = "";

  // Theme Colors
  static const saffron = Color(0xFFFF6700);
  static const gold = Color(0xFFFFD700);
  static const navyBlue = Color(0xFF002868);
  static const darkNavy = Color(0xFF001A45);
  static const warmWhite = Color(0xFFFFFDF7);

  @override
  void initState() {
    super.initState();
    _fetchAdmins();
  }

  Future<void> _fetchAdmins() async {
    setState(() => _isLoading = true);
    try {
      final data = widget.superAdminId != null
          ? await _superAdminServices.getAdminsBySuperAdmin(widget.superAdminId!)
          : await _superAdminServices.getAllAdmins();
          
      setState(() {
        _allAdmins = data;
        _filteredAdmins = _allAdmins;
      });
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleAdminStatus(int adminId, bool currentStatus, int index) async {
    final newStatus = !currentStatus;
    // Optimistic UI Update
    setState(() => _filteredAdmins[index]['isActive'] = newStatus);

    try {
      await _superAdminServices.toggleAdminStatus(adminId, newStatus);
      if (!mounted) return;
      CustomSnackBar.showSuccess(
        context,
        newStatus ? "Admin Activated Successfully" : "Admin Account Suspended",
      );
    } catch (e) {
      // Revert UI on failure
      setState(() => _filteredAdmins[index]['isActive'] = currentStatus);
      if (mounted) CustomSnackBar.showError(context, e.toString());
    }
  }

  void _filterAdmins(String query) {
    setState(() {
      _searchQuery = query;
      _filteredAdmins = _allAdmins.where((admin) {
        final name = (admin['name'] ?? '').toLowerCase();
        final email = (admin['email'] ?? '').toLowerCase();
        final mobile = (admin['mobileNumber'] ?? '').toLowerCase();
        final searchLower = query.toLowerCase();
        return name.contains(searchLower) || email.contains(searchLower) || mobile.contains(searchLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: widget.superAdminId != null ? "Inspecting Admins" : "Global Admins",
      // ── ADDED FLOATING ACTION BUTTON ──
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to registration page and wait for result
          final bool? isCreated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CorporatorRegistrationPage()),
          );
          
          // If a new admin was created, instantly refresh the list
          if (isCreated == true) {
            _fetchAdmins();
          }
        },
        backgroundColor: saffron,
        icon: const Icon(Icons.person_add_alt_1, color: Colors.white),
        label: const Text("NEW ADMIN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [darkNavy, navyBlue, Color(0xFF003A8C)],
          ),
        ),
        child: Column(
          children: [
            Container(height: 3, decoration: const BoxDecoration(gradient: LinearGradient(colors: [saffron, gold, saffron]))),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _filterAdmins,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search by Name, Email, or Mobile...",
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
                  : _filteredAdmins.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchAdmins,
                          color: gold,
                          backgroundColor: darkNavy,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80), // Added bottom padding to clear FAB
                            itemCount: _filteredAdmins.length,
                            itemBuilder: (context, index) {
                              final admin = _filteredAdmins[index];
                              return _buildAdminCard(admin, index);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.group_off, size: 64, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(_searchQuery.isEmpty ? "No Admins Found" : "No results for '$_searchQuery'",
              style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildAdminCard(Map<String, dynamic> admin, int index) {
    final bool isActive = admin['isActive'] ?? false;
    final String name = admin['name'] ?? 'Unknown Admin';
    final String groupName = admin['adminGroupName'] ?? 'No Group Assigned';
    final String mobile = admin['mobileNumber'] ?? 'No Mobile';
    final String photoUrl = admin['livePhotoUrl'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: warmWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => AdminInspectorPage(adminData: admin)));
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isActive ? gold : Colors.grey, width: 2),
                    image: photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                    color: darkNavy.withOpacity(0.1),
                  ),
                  child: photoUrl.isEmpty ? const Icon(Icons.person, color: darkNavy) : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: darkNavy)),
                      const SizedBox(height: 4),
                      Text(groupName, style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                          const SizedBox(width: 4),
                          Text(mobile, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      )
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Switch(
                      value: isActive,
                      activeColor: gold,
                      activeTrackColor: darkNavy,
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey[300],
                      onChanged: (val) => _toggleAdminStatus(admin['adminId'], isActive, index),
                    ),
                    Text(
                      isActive ? "ACTIVE" : "SUSPENDED",
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.bold, 
                        color: isActive ? Colors.green[700] : Colors.red[700],
                        letterSpacing: 0.5
                      ),
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