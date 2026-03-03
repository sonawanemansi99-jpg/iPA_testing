import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/features/complaints/data/repository/complaint_repository.dart';
import 'package:corporator_app/features/complaints/domain/model/complaint_model.dart';
import 'package:corporator_app/features/complaints/presentation/screens/complain_details.dart';
import 'package:corporator_app/features/complaints/presentation/screens/edit_complaint_status.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/compliant_list_item.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/filter_buttons.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class ListComplaints extends StatefulWidget {
  final String adminId;
  const ListComplaints({super.key, required this.adminId});

  @override
  State<ListComplaints> createState() => _ListComplaintsState();
}

class _ListComplaintsState extends State<ListComplaints> {
  final repository = ComplaintRepository();

  String? adminName;
  bool isAdminLoading = true;

  List<ComplaintModel> allComplaints = [];
  List<ComplaintModel> filteredComplaints = [];

  String selectedStatus = "all";
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadAdminData();
    loadComplaints();
  }

  /// Load admin name
  Future<void> loadAdminData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(widget.adminId)
          .get();

      if (doc.exists) {
        final data = doc.data();
        setState(() {
          adminName = data?["name"]?.toString() ?? "Unknown Admin";
          isAdminLoading = false;
        });
      } else {
        setState(() {
          adminName = "Admin Not Found";
          isAdminLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        adminName = "Error Loading Admin";
        isAdminLoading = false;
      });
    }
  }

  Future<void> loadComplaints() async {
    try {
      setState(() => isLoading = true);

      final complaints = await repository.getComplaintsForAdmin(widget.adminId);

      setState(() {
        allComplaints = complaints;
        filteredComplaints = selectedStatus == "all"
            ? complaints
            : complaints
                  .where(
                    (c) =>
                        c.status.toLowerCase() == selectedStatus.toLowerCase(),
                  )
                  .toList();
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void applyFilter(String status) {
    setState(() {
      selectedStatus = status;
      filteredComplaints = status == "all"
          ? allComplaints
          : allComplaints
                .where((c) => c.status.toLowerCase() == status.toLowerCase())
                .toList();
    });
  }

  /// Show images full screen with pinch-to-zoom
  void displayFullImage(BuildContext context, String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0),
          body: Center(
            child: InteractiveViewer(
              panEnabled: true,
              minScale: 1,
              maxScale: 5,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.broken_image,
                  color: Colors.white,
                  size: 50,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Widget to show single image with tap-to-zoom
  Widget imageTile(String url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () => displayFullImage(context, url),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            url,
            fit: BoxFit.cover,
            height: 150,
            width: double.infinity,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(
                    value: progress.expectedTotalBytes != null
                        ? progress.cumulativeBytesLoaded /
                              progress.expectedTotalBytes!
                        : null,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Show both Citizen and Admin Images
  void showImagesDialog(
    BuildContext context,
    List<String> citizenImages,
    List<String> adminImages,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (citizenImages.isNotEmpty) ...[
                  const Text(
                    "Citizen Uploaded Images",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...citizenImages.map((url) => imageTile(url)),
                  const SizedBox(height: 20),
                ],
                if (adminImages.isNotEmpty) ...[
                  const Text(
                    "Admin Uploaded Images",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ...adminImages.map((url) => imageTile(url)),
                  const SizedBox(height: 20),
                ],
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Back"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Complaints",
      floatingActionButton: FloatingActionButton(
        onPressed: loadComplaints,
        backgroundColor: Colors.red,
        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.refresh, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Admin Name
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              adminName ?? "Loading admin...",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          // Filter buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  filterButton('all', onTap: () => applyFilter('all')),
                  const SizedBox(width: 8),
                  filterButton('pending', onTap: () => applyFilter('pending')),
                  const SizedBox(width: 8),
                  filterButton(
                    'in progress',
                    onTap: () => applyFilter('in progress'),
                  ),
                  const SizedBox(width: 8),
                  filterButton(
                    'complete',
                    onTap: () => applyFilter('complete'),
                  ),
                ],
              ),
            ),
          ),
          // Complaint List
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredComplaints.isEmpty
                ? const Center(
                    child: Text(
                      "No complaints found",
                      style: TextStyle(fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredComplaints.length,
                    itemBuilder: (context, index) {
                      final complaint = filteredComplaints[index];

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    ComplainDetails(complaint: complaint),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 6,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(18),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      IconButton(
                                        onPressed: () {
                                          Navigator.of(context)
                                              .push(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      EditComplaintStatus(
                                                        complaint: complaint,
                                                      ),
                                                ),
                                              )
                                              .then((_) => loadComplaints());
                                        },
                                        icon: const Icon(Icons.edit),
                                      ),
                                      statusBadge(complaint.status),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  ComplaintListItem(
                                    "Complaint ID",
                                    complaint.complaintId,
                                  ),
                                  ComplaintListItem("Name", complaint.name),
                                  ComplaintListItem(
                                    "Mobile No.",
                                    complaint.mobileNo,
                                  ),
                                  ComplaintListItem("Zone", complaint.zoneName),
                                  const SizedBox(height: 10),
                                  if (complaint.citizenImages.isNotEmpty ||
                                      complaint.adminImages.isNotEmpty)
                                    TextButton.icon(
                                      onPressed: () => showImagesDialog(
                                        context,
                                        complaint.citizenImages,
                                        complaint.adminImages,
                                      ),
                                      icon: const Icon(Icons.image),
                                      label: const Text("View Images"),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
