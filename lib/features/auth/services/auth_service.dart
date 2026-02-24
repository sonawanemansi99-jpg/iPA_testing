import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // REGISTER
  Future<String?> register({
    required String name,
    required String mobile,
    required String email,
    required String password,
    required String location,
  }) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = credential.user!.uid;

      await _firestore.collection("users").doc(uid).set({
        "name": name,
        "mobile": mobile,
        "email": email,
        "location": location,
        "createdAt": FieldValue.serverTimestamp(),
      });

      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  Future<Map<String, dynamic>?> login({
    required String email,
    required String password,
  }) async {

    try {

      UserCredential credential =
          await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      String uid = credential.user!.uid;

      DocumentSnapshot userDoc =
          await _firestore.collection("users").doc(uid).get();

      return userDoc.data() as Map<String, dynamic>;

    } on FirebaseAuthException catch (e) {

      throw e.message ?? "Login failed";

    }

  }

  // LOGOUT
  Future<void> logout() async {
    await _auth.signOut();
  }
}
