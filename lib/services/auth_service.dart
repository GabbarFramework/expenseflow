import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Google Sign-In
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential = await _auth.signInWithCredential(credential);
      User? user = userCredential.user;

      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection("users").doc(user.uid).get();
        if (!doc.exists) {
          await _firestore.collection("users").doc(user.uid).set({
            "uid": user.uid,
            "fullName": user.displayName ?? "",
            "email": user.email,
            "profilePic": user.photoURL ?? "",
            "createdAt": FieldValue.serverTimestamp(),
          });
          print("Google user document created: ${user.uid}");
        } else {
          print("Google user already exists: ${user.uid}");
        }
      }

      return user;
    } catch (e) {
      print("Google Sign-In Error: $e");
      return null;
    }
  }

    // Sign Up and Save User Data in Firestore
  Future<User?> signUp(String email, String password, String fullName) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      User? user = result.user;

      if (user != null) {
        await _firestore.collection("users").doc(user.uid).set({
          "uid": user.uid,
          "fullName": fullName,
          "email": email,
          "profilePic": "", // Default empty profile pic
          "createdAt": FieldValue.serverTimestamp(),
        });
      }
      return user;
    } catch (e) {
      print("Sign-Up Error: $e");
      return null;
    }
  }

  // Get User Data from Firestore
  Future<DocumentSnapshot> getUserData(String uid) async {
    return await _firestore.collection("users").doc(uid).get();
  }

  // Update User Profile
  Future<void> updateUserProfile(String uid, String fullName, String profilePic) async {
    await _firestore.collection("users").doc(uid).update({
      "fullName": fullName,
      "profilePic": profilePic,
    });
  }

  // Email/Password Sign-In
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print("Sign-In Error: $e");
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  // Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Forgot Password
    Future<void> resetPassword(String email) async {
        try {
            await _auth.sendPasswordResetEmail(email: email);
            print("Password reset email sent!");
        } catch (e) {
        print(e.toString());
        }
    }
}
