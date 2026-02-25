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
  const ListComplaints({super.key,required this.adminId});

  @override
  State<ListComplaints> createState() => _ListComplaintsState();
}

class _ListComplaintsState extends State<ListComplaints> {
  final repository = ComplaintRepository();

  List<ComplaintModel> allComplaints = [];

  List<ComplaintModel> filteredComplaints = [];

  String selectedStatus = "all";

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadComplaints();
  }

  Future<void> loadComplaints() async {
    try {
      setState(() {
        isLoading = true;
      });

      final complaints = await repository.getComplaintsForAdmin(widget.adminId);

      setState(() {
        allComplaints = complaints;

        /// re-apply existing filter
        if (selectedStatus == "all") {
          filteredComplaints = complaints;
        } else {
          filteredComplaints = complaints
              .where(
                (c) => c.status.toLowerCase() == selectedStatus.toLowerCase(),
              )
              .toList();
        }

        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Complaints refreshed"),
          duration: Duration(seconds: 1),
        ),
      );
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  void applyFilter(String status) {
    setState(() {
      selectedStatus = status;

      if (status == "all") {
        filteredComplaints = allComplaints;
      } else {
        filteredComplaints = allComplaints
            .where((c) => c.status.toLowerCase() == status.toLowerCase())
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Complaints",

      /// FLOATING REFRESH BUTTON
      floatingActionButton: FloatingActionButton(
        onPressed: loadComplaints,

        backgroundColor: Colors.red,

        child: isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : const Icon(Icons.refresh, color: Colors.white),
      ),

      body: Column(
        children: [
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

                                  ComplaintListItem(
                                    "Location",
                                    complaint.location,
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
