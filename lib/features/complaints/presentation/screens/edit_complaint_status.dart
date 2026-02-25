import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corporator_app/core/widgets/app_text_input_field.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/features/complaints/domain/model/complaint_model.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/action_image_selector.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/item.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class EditComplaintStatus extends StatefulWidget {
  final ComplaintModel complaint;

  const EditComplaintStatus({super.key, required this.complaint});

  @override
  State<EditComplaintStatus> createState() => _EditComplaintStatusState();
}

class _EditComplaintStatusState extends State<EditComplaintStatus> {
  late String selectedStatus;
  final actionDescriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool isSubmitting = false;

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.complaint.status;

    // Pre-fill controller if complaint is already complete
    if (widget.complaint.status == "complete") {
      actionDescriptionController.text = widget.complaint.actionTaken!;
    }
  }

  @override
  void dispose() {
    actionDescriptionController.dispose();
    super.dispose();
  }

  bool get isCompleted => widget.complaint.status == "complete";

  List<DropdownMenuItem<String>> getStatusOptions() {
    if (widget.complaint.status == "pending") {
      return const [
        DropdownMenuItem(value: "pending", child: Text("Pending")),
        DropdownMenuItem(value: "in progress", child: Text("In Progress")),
      ];
    }
    if (widget.complaint.status == "in progress") {
      return const [
        DropdownMenuItem(value: "in progress", child: Text("In Progress")),
        DropdownMenuItem(value: "complete", child: Text("Complete")),
      ];
    }
    return const [];
  }

  Future<void> updateComplaint() async {
    // Validate if status is complete and action description is required
    if (selectedStatus == "complete") {
      if (!formKey.currentState!.validate()) return;
    }

    try {
      setState(() => isSubmitting = true);

      // Find document by complaintId
      final query = await firestore
          .collection("complaints")
          .where("complaintId", isEqualTo: widget.complaint.complaintId)
          .limit(1)
          .get();

      if (query.docs.isEmpty) throw Exception("Complaint not found");
      final docId = query.docs.first.id;

      // Update the document
      await firestore.collection("complaints").doc(docId).update({
        "status": selectedStatus,
        if (selectedStatus == "complete")
          "actionTaken": actionDescriptionController.text,
        if (selectedStatus == "complete")
          "actionTakenAt": FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Complaint updated successfully")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Edit Complaint",
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text("Back"),
                    ),
                    const SizedBox(height: 10),
                    item("Complaint ID", widget.complaint.complaintId),
                    item("Name", widget.complaint.name),
                    item("Mobile No.", widget.complaint.mobileNo),
                    item("Email", widget.complaint.email ?? "Not Provided"),
                    item(
                      "Description",
                      widget.complaint.description ?? "No description available",
                    ),
                    item("Location", widget.complaint.location),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          "Current Status : ",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        statusBadge(widget.complaint.status),
                      ],
                    ),
                    const SizedBox(height: 20),
                    if (!isCompleted)
                      DropdownButtonFormField<String>(
                        value: selectedStatus,
                        decoration: const InputDecoration(
                          labelText: "Update Status",
                          border: OutlineInputBorder(),
                        ),
                        items: getStatusOptions(),
                        onChanged: (value) {
                          setState(() {
                            selectedStatus = value!;
                          });
                        },
                      ),
                    if (selectedStatus == "complete") ...[
                      const SizedBox(height: 20),
                      const Text(
                        "Actions taken:",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      // Show text field only if complaint is not already complete
                      if (!isCompleted)
                        AppTextField(
                          label: "Describe the actions taken",
                          controller: actionDescriptionController,
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) return "Required";
                            return null;
                          },
                        ),
                      // If already completed, show the previous description
                      if (isCompleted)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.complaint.actionTaken ?? "No action description",
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      const SizedBox(height: 20),
                      const Text("Upload Evidence Photos"),
                      const SizedBox(height: 10),
                      const ComplaintImageSection(),
                    ],
                    const SizedBox(height: 30),
                    if (!isCompleted)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.all(14),
                          ),
                          onPressed: isSubmitting ? null : updateComplaint,
                          child: isSubmitting
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Submit",
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    if (isCompleted)
                      const Center(
                        child: Text(
                          "This complaint is already completed and cannot be edited.",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}