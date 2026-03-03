import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> registerAdmin({
  required String name,
  required String mobile,
  required String email,
  required String password,
  required String location,
  required String corporatorId,
}) async {
  try {
    // 🔥 Create secondary Firebase app
    FirebaseApp secondaryApp = await Firebase.initializeApp(
      name: 'Secondary',
      options: Firebase.app().options,
    );

    FirebaseAuth secondaryAuth =
        FirebaseAuth.instanceFor(app: secondaryApp);

    // Create admin without affecting main session
    UserCredential credential =
        await secondaryAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final adminId = credential.user!.uid;

    // Save admin in Firestore (use main app firestore)
    await _firestore.collection("users").doc(adminId).set({
      "uid": adminId,
      "name": name,
      "mobile": mobile,
      "email": email,
      "location": location,
      "role": "admin",
      "corporatorId": corporatorId,
      "zoneIds": [],
      "createdAt": FieldValue.serverTimestamp(),
    });

    // Sign out from secondary app
    await secondaryAuth.signOut();
    await secondaryApp.delete();

    return adminId;
  } catch (e) {
    return e.toString();
  }
}

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {
    try {
      //  Authenticate
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return null;

      final uid = user.uid;

      // 2️⃣ Check SUPERADMIN collection
      final superAdminDoc = await _firestore
          .collection('superadmin')
          .doc(uid)
          .get();

      if (superAdminDoc.exists) {
        return {"uid": uid, "role": "SUPERADMIN", ...superAdminDoc.data()!};
      }

      // 3️⃣ Check CORPORATOR collection
      final corporatorDoc = await _firestore
          .collection('corporator')
          .doc(uid)
          .get();

      if (corporatorDoc.exists) {
        return {"uid": uid, "role": "CORPORATOR", ...corporatorDoc.data()!};
      }

      // 4️⃣ Check ADMIN collection
      final adminDoc = await _firestore.collection('users').doc(uid).get();

      if (adminDoc.exists) {
        return {"uid": uid, "role": "ADMIN", ...adminDoc.data()!};
      }

      // If not found anywhere
      throw Exception("User role not found in database");
    } catch (e) {
      throw Exception("Login Failed: $e");
    }
  }

  Future<void> sendPasswordResetEmail({required String email}) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }

  /// Create Corporator Account (Super Admin Only)
  Future<void> registerCorporator({
    required String name,
    required String email,
    required String password,
    required String mobileNo,
    required String ward,
    required String zone,
  }) async {
    try {
      // Create user in Firebase Auth
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = credential.user!.uid;

      // Save corporator data in Firestore
      await _firestore.collection('corporator').doc(uid).set({
        'uid': uid,
        'name': name,
        'email': email,
        'mobileNo': mobileNo,
        'ward': ward,
        'zone': zone,
        'role': 'CORPORATOR',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Corporator Registration Failed: $e");
    }
  }
}
