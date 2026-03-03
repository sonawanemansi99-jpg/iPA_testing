import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/model/complaint_model.dart';

class ComplaintRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ComplaintModel>> getComplaintsForAdmin(String adminId) async {
  try {
    /// 1️⃣ Get admin document
    final adminDoc =
        await _firestore.collection('users').doc(adminId).get();

    if (!adminDoc.exists) {
      throw Exception("Admin not found");
    }

    final adminData = adminDoc.data()!;
    final List<dynamic> zoneIdsDynamic = adminData['zoneIds'] ?? [];

    if (zoneIdsDynamic.isEmpty) {
      return [];
    }

    final List<String> zoneIds =
        zoneIdsDynamic.map((e) => e.toString()).toList();

    List<ComplaintModel> allComplaints = [];

    /// 2️⃣ Fetch complaints zone by zone
    for (String zoneId in zoneIds) {
      final snapshot = await _firestore
          .collection('complaints')
          .where('zoneId', isEqualTo: zoneId)
          .get();

      final complaintsForZone = snapshot.docs
          .map((doc) => ComplaintModel.fromFirestore(doc))
          .toList();

      allComplaints.addAll(complaintsForZone);
    }

    /// 3️⃣ Sort manually by createdAt (latest first)
    allComplaints.sort((a, b) {
      final aTime = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final bTime = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return bTime.compareTo(aTime);
    });

    return allComplaints;
  } catch (e) {
    rethrow;
  }
}
}