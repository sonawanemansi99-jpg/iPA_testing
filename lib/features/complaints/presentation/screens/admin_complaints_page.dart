// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:corporator_app/core/widgets/main_scaffold.dart';
// import 'package:corporator_app/features/complaints/domain/model/complaint_model.dart';
// import 'package:corporator_app/features/complaints/data/repository/complaint_repository.dart';
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:intl/intl.dart';

// class AdminComplaintsPage extends StatefulWidget {
//   const AdminComplaintsPage({super.key});

//   @override
//   State<AdminComplaintsPage> createState() => _AdminComplaintsPageState();
// }

// class _AdminComplaintsPageState extends State<AdminComplaintsPage> {
//   final ComplaintRepository repository = ComplaintRepository();
//   List<ComplaintModel> complaints = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     loadComplaints();
//   }

//   Future<void> loadComplaints() async {
//     setState(() => isLoading = true);
//     try {
//       final uid = FirebaseAuth.instance.currentUser!.uid;
//       final fetched = await repository.getComplaintsForAdmin(uid);
//       setState(() {
//         complaints = fetched;
//         isLoading = false;
//       });
//     } catch (e) {
//       setState(() => isLoading = false);
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text("Error loading complaints: $e")),
//       );
//     }
//   }

//   Widget buildStatusTimeline(ComplaintModel complaint) {
//     final history = List<Map<String, dynamic>>.from(complaint.statusHistory);
//     if (history.isEmpty) {
//       return const Text("No history available");
//     }
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: history.map((h) {
//         final status = h["status"] ?? "";
//         final ts = (h["timestamp"] as Timestamp?)?.toDate();
//         final updatedBy = h["updatedBy"] ?? "Admin";
//         final formattedTime = ts != null ? DateFormat("dd MMM yyyy, hh:mm a").format(ts) : "Unknown";
//         return Padding(
//           padding: const EdgeInsets.symmetric(vertical: 2),
//           child: Text("• $status at $formattedTime by $updatedBy"),
//         );
//       }).toList(),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return MainScaffold(
//       title: "Admin Complaints",
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : complaints.isEmpty
//               ? const Center(child: Text("No complaints found"))
//               : RefreshIndicator(
//                   onRefresh: loadComplaints,
//                   child: ListView.builder(
//                     padding: const EdgeInsets.all(16),
//                     itemCount: complaints.length,
//                     itemBuilder: (context, index) {
//                       final complaint = complaints[index];
//                       return Card(
//                         margin: const EdgeInsets.only(bottom: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(16),
//                         ),
//                         elevation: 4,
//                         child: Padding(
//                           padding: const EdgeInsets.all(16),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 "Complaint ID: ${complaint.complaintId}",
//                                 style: const TextStyle(fontWeight: FontWeight.bold),
//                               ),
//                               Text("Name: ${complaint.name}"),
//                               Text("Mobile: ${complaint.mobileNo}"),
//                               Text("Location: ${complaint.location}"),
//                               const SizedBox(height: 8),
//                               Text("Current Status: ${complaint.status}"),
//                               const SizedBox(height: 8),
//                               const Text("Status Timeline:"),
//                               buildStatusTimeline(complaint),
//                             ],
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 ),
//     );
//   }
// }