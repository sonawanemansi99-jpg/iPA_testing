import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<Map<String, dynamic>>> fetchAdmins() async {
    try {
      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      return querySnapshot.docs
          .map((doc) => doc.data())
          .toList();
    } catch (e) {
      debugPrint("Error fetching admins: $e");
      return [];
    }
  }
}