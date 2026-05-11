import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  // ── Current user ────────────────────────────────────────────────────────────
  static User? get currentUser => _auth.currentUser;
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  // ── Register with phone + password ──────────────────────────────────────────
  // Note: Firebase doesn't support phone+password directly.
  // We use email format: phone@hopedrop.app as a workaround.
  static Future<UserCredential?> registerWithPhone({
    required String phone,
    required String password,
    required String name,
    required String bloodType,
    required String role, // 'donor' or 'recipient'
  }) async {
    try {
      final email = '${phone.replaceAll(RegExp(r'[^0-9]'), '')}@hopedrop.app';

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update display name
      await credential.user?.updateDisplayName(name);

      // Save user data to Firestore
      if (credential.user != null) {
        await _db.collection('users').doc(credential.user!.uid).set({
          'uid': credential.user!.uid,
          'name': name,
          'phone': phone,
          'email': email,
          'bloodType': bloodType,
          'role': role,
          'isAvailable': role == 'donor' ? true : false,
          'totalDonations': 0,
          'location': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ── Login with phone + password ──────────────────────────────────────────────
  static Future<UserCredential?> loginWithPhone({
    required String phone,
    required String password,
  }) async {
    try {
      final email = '${phone.replaceAll(RegExp(r'[^0-9]'), '')}@hopedrop.app';

      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthError(e);
    }
  }

  // ── Google Sign In ───────────────────────────────────────────────────────────
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);

      // Save/update user in Firestore if new
      final userDoc = await _db
          .collection('users')
          .doc(userCredential.user!.uid)
          .get();

      if (!userDoc.exists) {
        await _db
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
          'uid': userCredential.user!.uid,
          'name': userCredential.user!.displayName ?? '',
          'email': userCredential.user!.email ?? '',
          'phone': '',
          'bloodType': '',
          'role': 'donor',
          'isAvailable': true,
          'totalDonations': 0,
          'location': '',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      return userCredential;
    } catch (e) {
      throw 'Google sign in failed. Please try again.';
    }
  }

  // ── Sign Out ─────────────────────────────────────────────────────────────────
  static Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ── Get user profile from Firestore ─────────────────────────────────────────
  static Future<Map<String, dynamic>?> getUserProfile(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      return doc.data();
    } catch (e) {
      return null;
    }
  }

  // ── Update user profile ──────────────────────────────────────────────────────
  static Future<void> updateUserProfile(
      String uid, Map<String, dynamic> data) async {
    await _db.collection('users').doc(uid).update(data);
  }

  // ── Reset password ───────────────────────────────────────────────────────────
  static Future<void> resetPassword(String phone) async {
    final email =
        '${phone.replaceAll(RegExp(r'[^0-9]'), '')}@hopedrop.app';
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ── Error handler ────────────────────────────────────────────────────────────
  static String _handleAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No account found with this phone number.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'email-already-in-use':
        return 'An account already exists with this phone number.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'invalid-credential':
        return 'Invalid phone number or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}