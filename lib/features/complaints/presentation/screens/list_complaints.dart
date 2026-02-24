

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
  const ListComplaints({super.key});

  @override
  State<ListComplaints> createState() => _ListComplaintsState();
}

class _ListComplaintsState extends State<ListComplaints> {
  final repository = ComplaintRepository();

  late List<ComplaintModel> allComplaints;
  List<ComplaintModel> filteredComplaints = [];

  String selectedStatus = "all";

  @override
  void initState() {
    super.initState();
    allComplaints = repository.getComplaints();
    filteredComplaints = allComplaints;
  }

  void applyFilter(String status) {
    setState(() {
      selectedStatus = status;

      if (status == "all") {
        filteredComplaints = allComplaints;
      } else {
        filteredComplaints = allComplaints
            .where((c) =>
                c.status.toLowerCase() == status.toLowerCase())
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Complaints",
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                filterButton('all',
                    onTap: () => applyFilter('all')),
                filterButton('pending',
                    onTap: () => applyFilter('pending')),
                filterButton('in progress',
                    onTap: () => applyFilter('in progress')),
                filterButton('complete',
                    onTap: () => applyFilter('complete')),

                const SizedBox(width: 10),


                IconButton(
                  onPressed: () => applyFilter("all"),
                  icon: const Icon(Icons.filter_list_alt),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: filteredComplaints.length,
              itemBuilder: (context, index) {
                final complaint = filteredComplaints[index];

                return Padding(
                  padding:
                      const EdgeInsets.only(bottom: 16),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ComplainDetails(
                              complaint: complaint),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 6,
                      surfaceTintColor: Colors.grey,
                      shadowColor:
                          Colors.black.withOpacity(0.15),
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(18),
                      ),
                      child: Padding(
                        padding:
                            const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                IconButton(
                                  onPressed: (){
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => EditComplaintStatus(complaint:complaint))
                                    );
                                  }, 
                                  icon: Icon(Icons.edit,
                                  color: Colors.grey,
                                  )),
                                statusBadge(
                                    complaint.status),
                              ],
                            ),

                            const SizedBox(height: 8),

                            ComplaintListItem(
                                "Complaint ID",
                                complaint.complaintId),
                            ComplaintListItem(
                                "Name",
                                complaint.name),
                            ComplaintListItem(
                                "Mobile No.",
                                complaint.mobileNo),
                            ComplaintListItem(
                                "Location",
                                complaint.location),
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
