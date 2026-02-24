import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../../domain/model/complaint_model.dart';

class ComplaintRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<ComplaintModel>> getComplaintsForAdmin(String adminId) async {
    final snapshot = await _firestore
        .collection("complaints")
        .where("adminId", isEqualTo: adminId)
        .orderBy("createdAt", descending: true)
        .get();
    debugPrint(
      "-----------------------Complaints found: ${snapshot.docs.length}",
    );
    debugPrint(FirebaseAuth.instance.currentUser!.uid);
    return snapshot.docs
        .map((doc) => ComplaintModel.fromFirestore(doc))
        .toList();
  }
}

// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../../domain/model/complaint_model.dart';

// class ComplaintRepository {

//   final FirebaseFirestore firestore =
//       FirebaseFirestore.instance;

//   Future<List<ComplaintModel>>
//       getComplaintsForAdmin(String adminId) async {

//     final snapshot =
//         await firestore
//             .collection("complaints")
//             .where("adminId", isEqualTo: adminId)
//             .orderBy("createdAt", descending: true)
//             .get();

//     return snapshot.docs
//         .map((doc) =>
//             ComplaintModel.fromFirestore(doc))
//         .toList();

//   }

// }
