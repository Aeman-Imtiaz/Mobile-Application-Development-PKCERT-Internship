import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email & password
  Future<String?> signUp(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await credential.user?.updateDisplayName(name);
      return null; // null means success
    } on FirebaseAuthException catch (e) {
      print('SIGNUP ERROR CODE: ${e.code} | MESSAGE: ${e.message}');
      return _friendlyError(e.code);
    } catch (e) {
      print('SIGNUP UNKNOWN ERROR: $e');
      return 'Unexpected error occurred.';
    }
  }

  // Login with email & password
  Future<String?> login(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null;
    } on FirebaseAuthException catch (e) {
      print('LOGIN ERROR CODE: ${e.code} | MESSAGE: ${e.message}');
      return _friendlyError(e.code);
    } catch (e) {
      print('LOGIN UNKNOWN ERROR: $e');
      return 'Unexpected error occurred.';
    }
  }

  // Logout
  Future<void> logout() async {
    await _auth.signOut();
  }

  String _friendlyError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password should be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}