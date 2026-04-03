/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class CreateZoneDialog extends StatefulWidget {
  const CreateZoneDialog({super.key});

  @override
  State<CreateZoneDialog> createState() => _CreateZoneDialogState();
}

class _CreateZoneDialogState extends State<CreateZoneDialog> {
  final zoneNameController = TextEditingController();
  final wardController = TextEditingController();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> createZone() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final zoneId = const Uuid().v4();

    final zoneData = {
      "zoneId": zoneId,
      "zoneName": zoneNameController.text.trim(),
      "ward": wardController.text.trim(),
      "admin": null,
    };

    await _firestore.collection("users").doc(user.uid).update({
      "zones": FieldValue.arrayUnion([zoneData])
    });

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Zone Created Successfully")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Create Zone"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: zoneNameController,
            decoration: const InputDecoration(labelText: "Zone Name"),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: wardController,
            decoration: const InputDecoration(labelText: "Ward"),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: createZone,
          child: const Text("Create"),
        ),
      ],
    );
  }
}*/