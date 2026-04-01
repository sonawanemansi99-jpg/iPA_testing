import 'package:corporator_app/core/widgets/custom_snack_bar.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/services/admin_group_service.dart';
import 'package:corporator_app/services/super_admin_services.dart';
import 'package:flutter/material.dart';

class AdminGroupInspectorPage extends StatefulWidget {
  final int groupId;

  const AdminGroupInspectorPage({Key? key, required this.groupId}) : super(key: key);

  @override
  State<AdminGroupInspectorPage> createState() => _AdminGroupInspectorPageState();
}

class _AdminGroupInspectorPageState extends State<AdminGroupInspectorPage> {
  final AdminGroupService _groupService = AdminGroupService();
  final SuperAdminService _adminService = SuperAdminService();

  bool _isLoading = true;
  Map<String, dynamic>? _groupData;
  List<dynamic> _allAdmins = [];
  List<dynamic> _groupMembers = [];

  static const gold = Color(0xFFFFD700);
  static const darkNavy = Color(0xFF001A45);
  static const navyBlue = Color(0xFF002868); 
  static const warmWhite = Color(0xFFFFFDF7);
  static const groupTeal = Color(0xFF007A33);
  static const dangerRed = Color(0xFFCC2200);

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _groupService.getGroupById(widget.groupId),
        _adminService.getAllAdmins(),
      ]);

      final group = results[0] as Map<String, dynamic>;
      final admins = results[1] as List<dynamic>;

      final List<dynamic> memberIds = group['adminIds'] ?? [];
      final members = admins.where((admin) => memberIds.contains(admin['adminId'])).toList();

      if (mounted) {
        setState(() {
          _groupData = group;
          _allAdmins = admins;
          _groupMembers = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, "Failed to load group details: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  // ── THEMED REMOVE DIALOG ──
  Future<void> _removeAdmin(int adminId, String adminName) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: warmWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dangerRed.withOpacity(0.3), width: 2),
            boxShadow: [BoxShadow(color: dangerRed.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [darkNavy, navyBlue]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.person_remove_alt_1, color: gold, size: 22),
                    SizedBox(width: 10),
                    Text("REMOVE CORPORATOR", style: TextStyle(color: gold, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  "Are you sure you want to remove $adminName from this group? They will be reassigned to a new auto-generated group.", 
                  style: const TextStyle(fontSize: 15, color: darkNavy, fontWeight: FontWeight.w600, height: 1.4)
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 1))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: dangerRed,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text("REMOVE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _groupService.removeAdminFromGroup(widget.groupId, adminId);
        if (!mounted) return;
        CustomSnackBar.showSuccess(context, "$adminName removed successfully.");
        await _fetchData();
      } catch (e) {
        if (!mounted) return;
        CustomSnackBar.showError(context, e.toString().replaceAll("Exception: ", ""));
        setState(() => _isLoading = false);
      }
    }
  }

  // ── THEMED ADD DIALOG ──
  void _showAddAdminsDialog() {
    final currentMemberIds = _groupMembers.map((m) => m['adminId']).toList();
    final availableAdmins = _allAdmins.where((a) => !currentMemberIds.contains(a['adminId'])).toList();

    if (availableAdmins.isEmpty) {
      CustomSnackBar.showInfo(context, "There are no available Corporators to add.");
      return;
    }

    List<int> selectedAdminIds = [];

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: warmWhite,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: groupTeal.withOpacity(0.3), width: 2),
                  boxShadow: [BoxShadow(color: groupTeal.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(colors: [darkNavy, navyBlue]),
                        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.person_add, color: gold, size: 22),
                          SizedBox(width: 10),
                          Text("ADD CORPORATORS", style: TextStyle(color: gold, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        ],
                      ),
                    ),
                    SizedBox(
                      width: double.maxFinite,
                      height: 300,
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: availableAdmins.length,
                        itemBuilder: (context, index) {
                          final admin = availableAdmins[index];
                          final adminId = admin['adminId'];
                          final isSelected = selectedAdminIds.contains(adminId);

                          return CheckboxListTile(
                            activeColor: groupTeal,
                            checkColor: Colors.white,
                            title: Text(admin['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold, color: darkNavy)),
                            subtitle: Text(admin['email'] ?? '', style: TextStyle(color: Colors.grey.shade700)),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setStateDialog(() {
                                if (value == true) selectedAdminIds.add(adminId);
                                else selectedAdminIds.remove(adminId);
                              });
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 1))),
                          const SizedBox(width: 12),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: groupTeal,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              elevation: 0,
                            ),
                            onPressed: selectedAdminIds.isEmpty
                                ? null
                                : () async {
                                    Navigator.pop(context);
                                    setState(() => _isLoading = true);
                                    try {
                                      await _groupService.assignAdminsToGroup(widget.groupId, selectedAdminIds);
                                      if (!mounted) return;
                                      CustomSnackBar.showSuccess(context, "Corporators assigned successfully.");
                                      await _fetchData();
                                    } catch (e) {
                                      if (!mounted) return;
                                      CustomSnackBar.showError(context, e.toString().replaceAll("Exception: ", ""));
                                      setState(() => _isLoading = false);
                                    }
                                  },
                            child: const Text("ADD SELECTED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── THEMED EDIT DIALOG ──
  void _editGroup() {
    if (_groupData == null) return;
    
    final nameCtrl = TextEditingController(text: _groupData!['groupName']);
    final descCtrl = TextEditingController(text: _groupData!['description']);

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: warmWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: groupTeal.withOpacity(0.3), width: 2),
            boxShadow: [BoxShadow(color: groupTeal.withOpacity(0.2), blurRadius: 20, spreadRadius: 2)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(colors: [darkNavy, navyBlue]),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.edit_note, color: gold, size: 22),
                    SizedBox(width: 10),
                    Text("EDIT GROUP INFO", style: TextStyle(color: gold, fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("GROUP NAME", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: navyBlue, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameCtrl, 
                      style: const TextStyle(fontSize: 15, color: darkNavy, fontWeight: FontWeight.w600),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.group_work, color: groupTeal, size: 20),
                        filled: true, 
                        fillColor: const Color(0xFFF7F5EF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      )
                    ),
                    const SizedBox(height: 16),
                    const Text("DESCRIPTION", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: navyBlue, letterSpacing: 1.2)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descCtrl, 
                      maxLines: 3,
                      style: const TextStyle(fontSize: 14, color: darkNavy, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        filled: true, 
                        fillColor: const Color(0xFFF7F5EF),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.all(14),
                      )
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w800, letterSpacing: 1))),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: groupTeal,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 0,
                      ),
                      onPressed: () async {
                        if (nameCtrl.text.trim().isEmpty) {
                          CustomSnackBar.showError(context, "Group name cannot be empty");
                          return;
                        }
                        
                        Navigator.pop(context);
                        setState(() => _isLoading = true);
                        
                        try {
                          await _groupService.updateAdminGroup(widget.groupId, nameCtrl.text.trim(), descCtrl.text.trim());
                          if (!mounted) return;
                          CustomSnackBar.showSuccess(context, "Group Details Updated");
                          await _fetchData(); 
                        } catch (e) {
                          if (!mounted) return;
                          CustomSnackBar.showError(context, e.toString().replaceAll("Exception: ", ""));
                          setState(() => _isLoading = false);
                        }
                      },
                      child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Group Inspector",
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _showAddAdminsDialog,
              backgroundColor: groupTeal,
              icon: const Icon(Icons.person_add, color: Colors.white),
              label: const Text("ADD MEMBER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
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
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: gold))
                  : _groupData == null
                      ? const Center(child: Text("Group data unavailable", style: TextStyle(color: Colors.white)))
                      : RefreshIndicator(
                          onRefresh: _fetchData,
                          color: gold,
                          backgroundColor: darkNavy,
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _groupMembers.isEmpty ? 2 : _groupMembers.length + 1,
                            itemBuilder: (context, index) {
                              if (index == 0) return _buildGroupHeader();
                              
                              if (_groupMembers.isEmpty) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 40),
                                  child: Center(
                                    child: Text("No members in this group yet.", style: TextStyle(color: Colors.white54, fontSize: 16))
                                  ),
                                );
                              }
                              
                              return _buildMemberCard(_groupMembers[index - 1]);
                            },
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupHeader() {
    final bool isActive = _groupData!['isActive'] ?? true;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: warmWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))],
        border: Border.all(color: isActive ? groupTeal.withOpacity(0.5) : dangerRed.withOpacity(0.5), width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ── PROPERLY INLINED TITLE AND PENCIL ──
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        _groupData!['groupName'] ?? "Unknown Group",
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: darkNavy),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _editGroup,
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(Icons.edit, color: groupTeal, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              
              // ── STATUS BADGE PUSHED TO THE RIGHT ──
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green.withOpacity(0.2) : dangerRed.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? "ACTIVE" : "SUSPENDED",
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: isActive ? Colors.green.shade800 : dangerRed),
                ),
              )
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _groupData!['description'] ?? "No description available.",
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.people_alt_outlined, color: groupTeal, size: 20),
              const SizedBox(width: 8),
              Text(
                "${_groupMembers.length} Active Members",
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: navyBlue),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildMemberCard(Map<String, dynamic> admin) {
    final String name = admin['name'] ?? 'Unknown';
    final String email = admin['email'] ?? 'No Email';
    final String photoUrl = admin['livePhotoUrl'] ?? '';
    final int adminId = admin['adminId'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: warmWhite, borderRadius: BorderRadius.circular(16)),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: groupTeal, width: 2),
                  image: photoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover) : null,
                  color: darkNavy.withOpacity(0.1),
                ),
                child: photoUrl.isEmpty ? const Icon(Icons.person, color: groupTeal) : null,
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
              IconButton(
                icon: const Icon(Icons.person_remove_alt_1, color: dangerRed),
                tooltip: "Remove from Group",
                onPressed: () => _removeAdmin(adminId, name),
              ),
            ],
          ),
        ),
      ),
    );
  }
}