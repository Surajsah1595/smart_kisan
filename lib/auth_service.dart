import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'notification_service.dart';
import 'localization_service.dart';

/// [AuthService] is a singleton class responsible for managing user authentication.
/// It provides methods for signing up, signing in (via Email or Google), password resets,
/// and signing out. It interacts closely with [FirebaseAuth] and [FirebaseFirestore].
class AuthService {
  // Private constructor to enforce the Singleton pattern.
  AuthService._();
  
  // The single, globally accessible instance of this service.
  static final AuthService instance = AuthService._();

  // Reference to the core Firebase Authentication instance used for all auth operations.
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Reference to the Firestore database used to store extra user profile metadata.
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Purpose: Creates a new user account using an email and password.
  /// Inputs: [email], [password], [firstName], [lastName], [phone].
  /// Outputs: A Future containing the newly created [User] object, or null on failure.
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    // 1. Pass the raw email and password to Firebase to create the underlying auth account.
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Extract the generated user object from the credential payload.
    final user = cred.user;
    if (user == null) return null; // Failsafe if user creation silently fails.

    // 2. Concatenate first and last name and attach it to the core Auth profile's display name.
    await user.updateDisplayName('$firstName $lastName'.trim());

    // 3. Initialize the user's document in the 'users' Firestore collection to hold custom data (like phone).
    await _db.collection('users').doc(user.uid).set({
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      // Use server time to prevent local clock spoofing for account creation timestamps.
      'createdAt': FieldValue.serverTimestamp(), 
    });

    // 4. Register the user's device token with the NotificationService for push alerts.
    await NotificationService().saveFcmToken(user.uid);

    return user;
  }

  /// Purpose: Authenticates a user using their Google account via the OAuth flow.
  /// Inputs: None. (Relies on a system popup).
  /// Outputs: A Future containing the authenticated [User], or null if canceled/failed.
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the native Google Sign-In popup flow.
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      
      // If the user taps outside the popup or cancels, googleUser will be null.
      if (googleUser == null) return null; 

      // 2. Retrieve the underlying OAuth tokens (access and ID tokens) from the Google payload.
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // 3. Package the Google OAuth tokens into a credential object that Firebase Auth understands.
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Pass the credential to Firebase to officially sign the user into the app's backend.
      final UserCredential userCredential = 
          await _auth.signInWithCredential(credential);
      
      // 5. If successful, ensure the device is registered for notifications.
      if (userCredential.user != null) {
        await NotificationService().saveFcmToken(userCredential.user!.uid);
      }
      return userCredential.user;

    } catch (e) {
      // Catch and log specific OAuth errors (e.g., network loss during popup).
      print('Google Sign-In Error: $e');
      return null;
    }
  }

  /// Purpose: Authenticates an existing user using their email and password.
  /// Inputs: [email], [password].
  /// Outputs: A Future containing the authenticated [User], or throws an error on failure.
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    // Send credentials to Firebase for verification against the backend.
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    
    // Ensure the device's FCM token is up-to-date in Firestore upon successful login.
    if (cred.user != null) {
      await NotificationService().saveFcmToken(cred.user!.uid);
    }
    return cred.user;
  }

  /// Purpose: Triggers a standard Firebase password reset email.
  /// Inputs: [email] - The address to send the reset link to.
  /// Outputs: A Future completing when the email request is dispatched.
  Future<void> sendPasswordResetEmail(String email) async {
    // Invokes the built-in Firebase method which handles template generation and SMTP delivery.
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Purpose: Ends the current user's session and clears local auth state.
  /// Inputs: None.
  /// Outputs: A Future completing when the sign-out is processed.
  Future<void> signOut() async {
    // Purges the user's session token from local storage.
    await _auth.signOut();
  }
}