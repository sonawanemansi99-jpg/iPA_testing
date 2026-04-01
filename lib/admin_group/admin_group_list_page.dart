import 'package:corporator_app/admin_group/admin_group_inspector_page.dart';
import 'package:corporator_app/admin_group/create_admin_group_page.dart';
import 'package:corporator_app/core/widgets/custom_snack_bar.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/services/admin_group_service.dart';
import 'package:flutter/material.dart';

class AdminGroupListPage extends StatefulWidget {
  const AdminGroupListPage({Key? key}) : super(key: key);

  @override
  State<AdminGroupListPage> createState() => _AdminGroupListPageState();
}

class _AdminGroupListPageState extends State<AdminGroupListPage> {
  final AdminGroupService _services = AdminGroupService();
  
  List<dynamic> _allGroups = [];
  List<dynamic> _filteredGroups = [];
  bool _isLoading = true;
  String _searchQuery = "";

  static const gold = Color(0xFFFFD700);
  static const darkNavy = Color(0xFF001A45);
  static const warmWhite = Color(0xFFFFFDF7);
  static const groupTeal = Color(0xFF007A33); // Distinct color for Organizational Groups

  @override
  void initState() {
    super.initState();
    _fetchGroups();
  }

  Future<void> _fetchGroups() async {
    setState(() => _isLoading = true);
    try {
      final data = await _services.getAllGroups();
      setState(() {
        _allGroups = data;
        _filteredGroups = data;
      });
    } catch (e) {
      if (mounted) CustomSnackBar.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleStatus(int id, bool currentStatus, int index) async {
    final newStatus = !currentStatus;
    
    // Optimistic UI update
    setState(() => _filteredGroups[index]['isActive'] = newStatus);

    try {
      await _services.toggleGroupStatus(id, newStatus);
      if (!mounted) return;
      CustomSnackBar.showSuccess(
        context, 
        newStatus ? "Group Activated successfully" : "Group Suspended (All corporators locked)"
      );
    } catch (e) {
      // Revert on failure
      setState(() => _filteredGroups[index]['isActive'] = currentStatus);
      if (mounted) CustomSnackBar.showError(context, e.toString());
    }
  }

  void _filter(String query) {
    setState(() {
      _searchQuery = query;
      _filteredGroups = _allGroups.where((g) {
        final name = (g['groupName'] ?? '').toLowerCase();
        final desc = (g['description'] ?? '').toLowerCase();
        return name.contains(query.toLowerCase()) || desc.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Organizational Groups",
      // floatingActionButton: FloatingActionButton.extended(
      //   onPressed: () async {
      //     final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateAdminGroupPage()));
      //     if (result == true) {
      //        _fetchGroups(); // Reload the list if a group was created!
      //     }
      //   },
      //   backgroundColor: groupTeal,
      //   icon: const Icon(Icons.group_work, color: Colors.white),
      //   label: const Text("NEW GROUP", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
      // ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, 
            end: Alignment.bottomCenter, 
            colors: [darkNavy, Color(0xFF002868), Color(0xFF003A8C)]
          ),
        ),
        child: Column(
          children: [
            Container(height: 3, color: groupTeal),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                onChanged: _filter,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "Search Group Name or Details...",
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
                  : RefreshIndicator(
                      onRefresh: _fetchGroups,
                      color: gold,
                      child: _filteredGroups.isEmpty
                          ? ListView( // Using ListView ensures pull-to-refresh works even when empty
                              children: [
                                SizedBox(
                                  height: MediaQuery.of(context).size.height * 0.5,
                                  child: Center(
                                    child: Text(
                                      "No Groups found.", 
                                      style: TextStyle(color: Colors.white.withOpacity(0.5))
                                    )
                                  ),
                                ),
                              ],
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _filteredGroups.length,
                              itemBuilder: (context, index) => _buildCard(_filteredGroups[index], index),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> group, int index) {
    // Safely extract properties
    final bool isActive = group['isActive'] ?? true;
    final String name = group['groupName'] ?? 'Unknown Group';
    final String desc = group['description'] ?? 'No description provided';
    final List<dynamic> adminIds = group['adminIds'] ?? [];
    final int groupId = group['adminGroupId'] ?? group['id'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: warmWhite, borderRadius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () async {
            await Navigator.push(
              context, 
              MaterialPageRoute(builder: (_) => AdminGroupInspectorPage(groupId: groupId))
            );
            _fetchGroups(); // Refresh data on return
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isActive ? groupTeal : Colors.grey, width: 2),
                    color: darkNavy.withOpacity(0.1),
                  ),
                  child: Icon(Icons.account_balance, color: isActive ? groupTeal : Colors.grey),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name, 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: isActive ? darkNavy : Colors.grey.shade700
                        )
                      ),
                      const SizedBox(height: 4),
                      Text(
                        desc, 
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: groupTeal.withOpacity(0.1), 
                          borderRadius: BorderRadius.circular(4)
                        ),
                        child: Text(
                          "${adminIds.length} Corporators", 
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: groupTeal)
                        ),
                      )
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Switch(
                      value: isActive,
                      activeColor: groupTeal,
                      onChanged: (val) => _toggleStatus(groupId, isActive, index),
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