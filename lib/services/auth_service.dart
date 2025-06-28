import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 🔹 Get current user
  User? get currentUser => _auth.currentUser;

  // 🔐 Register new user
  Future<String?> registerUser(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(email: email, password: password);
      return null; // Registration successful
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  // 🔐 Login user
  Future<String?> loginUser(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // Login successful
    } catch (e) {
      return e.toString(); // Return error message
    }
  }

  // 🚪 Logout user
  Future<void> logoutUser() async {
    await _auth.signOut();
  }

  // 🔄 Check if user is logged in
  Stream<User?> authStateChanges() {
    return _auth.authStateChanges();
  }

  // 🔑 Reset password
  Future<String?> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null; // Reset email sent
    } catch (e) {
      return e.toString(); // Return error message
    }
  }
}
