import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:corporator_app/super_admin/data/admin_details.dart';


class AdminRepository {

  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Future<List<AdminModel>> getAdmins() async {

    final snapshot = await _firestore
        .collection("users")
        .where("role", isEqualTo: "admin")
        .get();

    return snapshot.docs
        .map((e) => AdminModel.fromFirestore(e))
        .toList();
  }

  Future<void> updateAdmin(
      String uid,
      Map<String, dynamic> data) async {

    await _firestore
        .collection("users")
        .doc(uid)
        .update(data);
  }
}