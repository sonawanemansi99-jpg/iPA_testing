import 'package:corporator_app/core/widgets/custom_snack_bar.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/services/admin_group_service.dart';
import 'package:corporator_app/services/super_admin_services.dart';
import 'package:flutter/material.dart';

class CreateAdminGroupPage extends StatefulWidget {
  const CreateAdminGroupPage({Key? key}) : super(key: key);

  @override
  State<CreateAdminGroupPage> createState() => _CreateAdminGroupPageState();
}

class _CreateAdminGroupPageState extends State<CreateAdminGroupPage> {
  final AdminGroupService _groupService = AdminGroupService();
  final SuperAdminService _adminService = SuperAdminService();

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isSubmitting = false;

  List<dynamic> _allAdmins = [];
  List<dynamic> _allGroups = [];
  List<int> _selectedAdminIds = [];

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
        _adminService.getAllAdmins(),
        _groupService.getAllGroups(),
      ]);

      if (mounted) {
        setState(() {
          _allAdmins = results[0];
          _allGroups = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomSnackBar.showError(context, "Failed to load data: $e");
        setState(() => _isLoading = false);
      }
    }
  }

  // ── CORE LOGIC: CHECK WARNINGS BEFORE SELECTING AN ADMIN ──
  Future<void> _handleAdminSelection(Map<String, dynamic> admin, bool isSelecting) async {
    final int adminId = admin['adminId'];
    final String adminName = admin['name'] ?? 'This corporator';

    // If deselecting, just remove them instantly
    if (!isSelecting) {
      setState(() => _selectedAdminIds.remove(adminId));
      return;
    }

    // Find if this admin currently belongs to another group
    Map<String, dynamic>? currentGroup;
    for (var group in _allGroups) {
      List<dynamic> memberIds = group['adminIds'] ?? [];
      if (memberIds.contains(adminId)) {
        currentGroup = group;
        break;
      }
    }

    if (currentGroup != null) {
      final String groupName = currentGroup['groupName'];
      final int memberCount = (currentGroup['adminIds'] ?? []).length;
      final bool isLastMember = memberCount == 1;

      final bool proceed = await _showWarningDialog(adminName, groupName, isLastMember);
      
      if (!proceed) return; // User cancelled
    }

    // Add to selection
    setState(() => _selectedAdminIds.add(adminId));
  }

  // ── THEMED WARNING DIALOG ──
  Future<bool> _showWarningDialog(String adminName, String groupName, bool isLastMember) async {
    return await showDialog<bool>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: warmWhite,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: dangerRed.withOpacity(0.4), width: 2),
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
                child: Row(
                  children: [
                    Icon(isLastMember ? Icons.warning_amber_rounded : Icons.info_outline, color: gold, size: 22),
                    const SizedBox(width: 10),
                    Text(isLastMember ? "CRITICAL WARNING" : "REASSIGNMENT NOTICE", style: const TextStyle(color: gold, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontSize: 15, color: darkNavy, fontWeight: FontWeight.w600, height: 1.4),
                        children: [
                          TextSpan(text: "$adminName is currently assigned to "),
                          TextSpan(text: "'$groupName'", style: const TextStyle(color: dangerRed, fontWeight: FontWeight.w900)),
                          const TextSpan(text: ".\n\nAdding them here will instantly remove them from that group."),
                        ],
                      ),
                    ),
                    if (isLastMember) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: dangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: dangerRed.withOpacity(0.3))),
                        child:  Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.delete_forever, color: dangerRed, size: 20),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                "Because this is the LAST admin in that group, the group '$groupName' will be PERMANENTLY DELETED.",
                                style: TextStyle(color: dangerRed, fontWeight: FontWeight.w800, fontSize: 13),
                              ),
                            )
                          ],
                        ),
                      )
                    ]
                  ],
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
                      child: const Text("PROCEED", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ) ?? false;
  }

  Future<void> _submitGroup() async {
    if (_nameCtrl.text.trim().isEmpty) {
      CustomSnackBar.showError(context, "Group name cannot be empty");
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await _groupService.createAdminGroup(
        _nameCtrl.text.trim(),
        _descCtrl.text.trim(),
        _selectedAdminIds,
      );
      if (!mounted) return;
      CustomSnackBar.showSuccess(context, "Admin Group created successfully!");
      Navigator.pop(context, true); // Return true to refresh the list page
    } catch (e) {
      if (!mounted) return;
      CustomSnackBar.showError(context, e.toString().replaceAll("Exception: ", ""));
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Create Admin Group",
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
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── FORM SECTION ──
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: warmWhite, borderRadius: BorderRadius.circular(16)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text("GROUP DETAILS", style: TextStyle(color: groupTeal, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _nameCtrl,
                                  style: const TextStyle(color: darkNavy, fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    labelText: "Group Name *",
                                    labelStyle: TextStyle(color: darkNavy.withOpacity(0.6)),
                                    filled: true, fillColor: const Color(0xFFF7F5EF),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    prefixIcon: const Icon(Icons.group_work, color: groupTeal),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextField(
                                  controller: _descCtrl,
                                  maxLines: 2,
                                  style: const TextStyle(color: darkNavy),
                                  decoration: InputDecoration(
                                    labelText: "Description (Optional)",
                                    labelStyle: TextStyle(color: darkNavy.withOpacity(0.6)),
                                    filled: true, fillColor: const Color(0xFFF7F5EF),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                    prefixIcon: const Icon(Icons.notes, color: groupTeal),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // ── ADMIN SELECTION SECTION ──
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: Text("ASSIGN CORPORATORS", style: TextStyle(color: gold, fontWeight: FontWeight.w900, letterSpacing: 1.5, fontSize: 12)),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            decoration: BoxDecoration(color: warmWhite, borderRadius: BorderRadius.circular(16)),
                            child: _allAdmins.isEmpty 
                                ? const Padding(padding: EdgeInsets.all(20), child: Center(child: Text("No corporators available", style: TextStyle(color: Colors.grey))))
                                : ListView.separated(
                                    shrinkWrap: true,
                                    physics: const NeverScrollableScrollPhysics(),
                                    itemCount: _allAdmins.length,
                                    separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
                                    itemBuilder: (context, index) {
                                      final admin = _allAdmins[index];
                                      final int adminId = admin['adminId'];
                                      final bool isSelected = _selectedAdminIds.contains(adminId);

                                      return CheckboxListTile(
                                        activeColor: groupTeal,
                                        checkColor: Colors.white,
                                        title: Text(admin['name'] ?? 'Unknown', style: const TextStyle(color: darkNavy, fontWeight: FontWeight.bold)),
                                        subtitle: Text(admin['email'] ?? '', style: TextStyle(color: Colors.grey.shade600, fontSize: 11)),
                                        value: isSelected,
                                        onChanged: (val) => _handleAdminSelection(admin, val ?? false),
                                      );
                                    },
                                  ),
                          ),
                          const SizedBox(height: 30),

                          // ── SUBMIT BUTTON ──
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: groupTeal,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 4,
                              ),
                              onPressed: _isSubmitting ? null : _submitGroup,
                              child: _isSubmitting 
                                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                  : const Text("CREATE ADMIN GROUP", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}