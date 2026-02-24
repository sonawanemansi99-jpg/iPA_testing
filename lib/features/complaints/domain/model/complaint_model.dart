import 'package:cloud_firestore/cloud_firestore.dart';

class ComplaintModel {

  final String complaintId;
  final String name;
  final String mobileNo;
  final String location;
  final String description;
  final String status;
  final String adminId;
  final String email;
  final Timestamp? createdAt;

  ComplaintModel({
    required this.complaintId,
    required this.email,
    required this.name,
    required this.mobileNo,
    required this.location,
    required this.description,
    required this.status,
    required this.adminId,
    this.createdAt,
  });

  factory ComplaintModel.fromFirestore(
      DocumentSnapshot doc) {

    final data =
        doc.data() as Map<String, dynamic>;

    return ComplaintModel(
      complaintId:
          data["complaintId"] ?? "",

      name:
          data["name"] ?? "",

      mobileNo:
          data["mobileNo"] ?? "",

      location:
          data["location"] ?? "",

      description:
          data["description"] ?? "",

      status:
          data["status"] ?? "pending",

      adminId:
          data["adminId"] ?? "",
          
      email:
          data["email"] ?? "",

      createdAt:
          data["createdAt"],
    );
  }

}