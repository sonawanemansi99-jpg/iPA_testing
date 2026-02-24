

import 'package:corporator_app/core/widgets/app_text_input_field.dart';
import 'package:corporator_app/core/widgets/main_scaffold.dart';
import 'package:corporator_app/features/complaints/domain/model/complaint_model.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/action_image_selector.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/item.dart';
import 'package:corporator_app/features/complaints/presentation/widgets/status_badge.dart';
import 'package:flutter/material.dart';

class EditComplaintStatus extends StatefulWidget {
  final ComplaintModel complaint;

  const EditComplaintStatus({
    super.key,
    required this.complaint,
  });

  @override
  State<EditComplaintStatus> createState() =>
      _EditComplaintStatusState();
}

class _EditComplaintStatusState
    extends State<EditComplaintStatus> {

  late String selectedStatus;

  final actionDescriptionController =
      TextEditingController();

  final formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    selectedStatus = widget.complaint.status;
  }

  @override
  void dispose() {
    actionDescriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainScaffold(
      title: "Update Complaint Status",
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          margin: const EdgeInsets.all(10),
          elevation: 6,
          surfaceTintColor: Colors.grey,
          shadowColor:
              Colors.black.withOpacity(0.15),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    TextButton.icon(
                      onPressed: () =>
                          Navigator.pop(context),
                      icon:
                          const Icon(Icons.arrow_back),
                      label: const Text("Back"),
                    ),

                    const SizedBox(height: 10),

                    item("Complaint ID",
                        widget.complaint.complaintId),
                    item("Name",
                        widget.complaint.name),
                    item("Mobile No.",
                        widget.complaint.mobileNo),
                    item(
                        "Email",
                        widget.complaint.email ??
                            "Not Provided"),
                    item(
                      "Description",
                      widget.complaint.description ??
                          "No description available",
                    ),
                    item("Location",
                        widget.complaint.location),

                    const SizedBox(height: 20),

                    Row(
                      children: [
                        const Text(
                          "Current Status : ",
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.bold),
                        ),
                        SizedBox(width: 10,),
                        statusBadge(selectedStatus),
                      ],
                    ),

                    const SizedBox(height: 20),


                    DropdownButtonFormField<String>(
                      initialValue: selectedStatus,
                      decoration:
                          const InputDecoration(
                        labelText: "Update Status",
                        border:
                            OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: "pending",
                            child: Text("Pending")),
                        DropdownMenuItem(
                            value: "in progress",
                            child:
                                Text("In Progress")),
                        DropdownMenuItem(
                            value: "complete",
                            child:
                                Text("Complete")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          selectedStatus = value!;
                        });
                      },
                    ),

                    const SizedBox(height: 20),

                    const Text(
                          "Actions taken :",
                          style: TextStyle(
                              fontWeight:
                                  FontWeight.bold),
                        ),
          
                    AppTextField(
                      label: "Describe the actions taken to resolve the complaint",
                      controller:
                          actionDescriptionController,
                      maxLines: 3,
                      validator: (value) {
                        if (value == null ||
                            value.isEmpty) {
                          return "Please describe action taken";
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),
                    const Text("Upload Evidence Photos"),
                    const SizedBox(height: 10),
                    const ComplaintImageSection(),
                    const SizedBox(height: 20),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shadowColor: Colors.black87,
                          elevation: 10,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          backgroundColor: Colors.red,                        
                        ),
                        onPressed: (){
                          if (formKey.currentState!
                              .validate()) {
                            print(
                                "Updated Status: $selectedStatus");
                            print(
                                "Action: ${actionDescriptionController.text}");

                            Navigator.pop(
                              context,
                              selectedStatus,
                            );
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: EdgeInsetsGeometry.all(10),
                          child:
                             Center(
                               child: const Text("Submit",
                               style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight(16),
                                color: Colors.white,
                               ),
                               ),
                             )
                        
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