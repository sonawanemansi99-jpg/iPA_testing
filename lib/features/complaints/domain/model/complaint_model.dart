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
  final String actionTaken;
  final Timestamp? createdAt;
  final String zoneName;

  final List<String> citizenImages;
  final List<String> adminImages;

  final String citizenVoiceNote; 
  final String adminVoiceNote; 

  ComplaintModel({
    required this.complaintId,
    required this.email,
    required this.name,
    required this.mobileNo,
    required this.location,
    required this.description,
    required this.status,
    required this.adminId,
    required this.actionTaken,
    required this.zoneName,
    required this.citizenVoiceNote,
    required this.adminVoiceNote, 
    this.createdAt,
    this.citizenImages = const [],
    this.adminImages = const [],
  });

  factory ComplaintModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return ComplaintModel(
      complaintId: data["complaintId"] ?? doc.id,
      name: data["name"] ?? "",
      mobileNo: data["mobileNo"] ?? "",
      location: data["location"] ?? "",
      description: data["description"] ?? "",
      status: data["status"] ?? "pending",
      adminId: data["adminId"] ?? "",
      email: data["email"] ?? "",
      actionTaken: data["actionTaken"] ?? "",
      createdAt: data["createdAt"],
      zoneName: data["zoneName"] ?? "",

      citizenImages: List<String>.from(data["citizenImages"] ?? []),
      adminImages: List<String>.from(data["adminImages"] ?? []),

      citizenVoiceNote: data["citizenVoiceNote"] ?? "", 
      adminVoiceNote: data["adminVoiceNote"] ?? "", 
    );
  }
}