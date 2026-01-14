import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // SIGN UP with email/password
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = cred.user;
    if (user == null) return null;

    // Set display name
    await user.updateDisplayName('$firstName $lastName'.trim());

    //Save user data in Firestore (optional but useful)
    await _db.collection('users').doc(user.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return user;
  }

  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the Google Authentication flow
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null; // User canceled the popup

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Create a new credential
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Sign in to Firebase with the credential
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      return userCredential.user;

    } catch (e) {
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  // SIGN IN with email/password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return cred.user;
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }


  // Sign out (email/Google/Facebook later)
  Future<void> signOut() async {
    await _auth.signOut();
  }
}