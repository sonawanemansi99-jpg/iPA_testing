import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SuperadminServices {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;


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
      UserCredential credential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = credential.user!.uid;

      // Save corporator data in Firestore
      await _firestore.collection('users').doc(uid).set({
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
