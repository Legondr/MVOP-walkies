import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  // Instance for auth
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Google sign in
  singInWithGoogle() async {
    try {
      // Begin interactive sign in process
      final GoogleSignInAccount? gUser = await GoogleSignIn().signIn();

      // Obtain auth details from requset
      final GoogleSignInAuthentication gAuth = await gUser!.authentication;

      // Create a new credential for user
      final credential = GoogleAuthProvider.credential(
        accessToken: gAuth.accessToken,
        idToken: gAuth.idToken,
      );
      // Sign in
      return await _firebaseAuth.signInWithCredential(credential);
    } catch (e) {
      print(e);
    }
  }

  signInWithApple() async {}
}
