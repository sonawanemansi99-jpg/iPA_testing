import 'package:cloud_firestore/cloud_firestore.dart';

class AdminModel {
  final String uid;
  final String name;
  final String email;
  final String mobileNo;
  final String location;
  final String profile;

  AdminModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.mobileNo,
    required this.location,
    required this.profile,
  });

  factory AdminModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return AdminModel(
      uid: doc.id,
      name: data["name"] ?? "",
      email: data["email"] ?? "",
      mobileNo: data["mobileNo"] ?? "",
      location: data["location"] ?? "",
      profile: data["profile"] ?? "",
    );
  }
}