import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CorporatorService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> allocateZonesToAdmin({
    required String adminId,
    required String corporatorId,
    required List<String> zoneNames,
  }) async {
    final adminZoneIds = <String>[];

    for (String rawZoneName in zoneNames) {
      // 🔥 Standardize zone name
      final standardizedZoneName = rawZoneName.trim().toUpperCase();

      if (standardizedZoneName.isEmpty) continue;

      final query = await _firestore
          .collection("zones")
          .where("zoneName", isEqualTo: standardizedZoneName)
          .where("corporatorId", isEqualTo: corporatorId)
          .get();

      if (query.docs.isNotEmpty) {
        // Zone already exists
        final zoneDoc = query.docs.first;
        final zoneId = zoneDoc.id;

        await _firestore.collection("zones").doc(zoneId).update({
          "adminIds": FieldValue.arrayUnion([adminId]),
        });

        adminZoneIds.add(zoneId);
      } else {
        // Create new zone
        final newZone = await _firestore.collection("zones").add({
          "zoneName": standardizedZoneName, // 🔥 stored in CAPS
          "corporatorId": corporatorId,
          "adminIds": [adminId],
          "createdAt": FieldValue.serverTimestamp(),
        });

        adminZoneIds.add(newZone.id);
      }
    }

    // Update admin document with zoneIds
    await _firestore.collection("users").doc(adminId).update({
      "zoneIds": adminZoneIds,
    });
  }

  Future<List<Map<String, dynamic>>> fetchMyAdmins() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .where('corporatorId', isEqualTo: currentUser.uid)
          .get();

      return querySnapshot.docs
          .map((doc) => {...doc.data(), "uid": doc.id})
          .toList();
    } catch (e) {
      debugPrint("Error fetching admins: $e");
      return [];
    }
  }

  Future<void> updateAdminZones({
    required String adminId,
    required String corporatorId,
    required List<String> newZoneNames,
  }) async {
    final standardizedZones = newZoneNames
        .map((z) => z.trim().toUpperCase())
        .toList();

    // 🔥 Remove admin from all old zones
    final oldZones = await _firestore
        .collection("zones")
        .where("adminIds", arrayContains: adminId)
        .get();

    for (var doc in oldZones.docs) {
      await doc.reference.update({
        "adminIds": FieldValue.arrayRemove([adminId]),
      });
    }

    final newZoneIds = <String>[];

    for (String zoneName in standardizedZones) {
      final query = await _firestore
          .collection("zones")
          .where("zoneName", isEqualTo: zoneName)
          .where("corporatorId", isEqualTo: corporatorId)
          .get();

      if (query.docs.isNotEmpty) {
        final zoneDoc = query.docs.first;
        await zoneDoc.reference.update({
          "adminIds": FieldValue.arrayUnion([adminId]),
        });
        newZoneIds.add(zoneDoc.id);
      } else {
        final newZone = await _firestore.collection("zones").add({
          "zoneName": zoneName,
          "corporatorId": corporatorId,
          "adminIds": [adminId],
          "createdAt": FieldValue.serverTimestamp(),
        });

        newZoneIds.add(newZone.id);
      }
    }

    await _firestore.collection("users").doc(adminId).update({
      "zoneIds": newZoneIds,
    });
  }

  Future<List<Map<String, dynamic>>> fetchUnallocatedZones(
    String corporatorId,
  ) async {
    final doc = await _firestore.collection('users').doc(corporatorId).get();

    if (!doc.exists || doc.data() == null) return [];

    final data = doc.data()!;
    if (data['zones'] == null) return [];

    final zones = List<Map<String, dynamic>>.from(data['zones']);

    return zones.where((z) => z['adminId'] == null).toList();
  }

  Future<void> assignAdminToZone({
    required String corporatorId,
    required String zoneId,
    required String adminId,
  }) async {
    final docRef = _firestore.collection('users').doc(corporatorId);

    final doc = await docRef.get();
    final zones = List<Map<String, dynamic>>.from(doc['zones']);

    for (var zone in zones) {
      if (zone['zoneId'] == zoneId) {
        zone['adminId'] = adminId;
      }
    }

    await docRef.update({"zones": zones});
  }
  Future<List<String>> getZoneNamesFromIds(List<String> zoneIds) async {
    List<String> zoneNames = [];

    for (String id in zoneIds) {
      final doc = await _firestore.collection('zones').doc(id).get();

      if (doc.exists) {
        zoneNames.add(doc['zoneName']);
      }
    }

    return zoneNames;
  }
}
