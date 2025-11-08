import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Get a shorthand for the Supabase client
  final _supabase = Supabase.instance.client;

  // This is the deep link you set up in AndroidManifest.xml
  final String _deepLink = 'com.t-racks-softdev-1://auth/callback';

  // This is the function you'll call from your register screen
  Future<void> register({
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    // This 'async' function will now do the try/catch
    // It will throw an AuthException if Supabase fails
    try {
      await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _deepLink,
        data: {
          'phone_number': phone,
          'role': role,
        },
      );
    } catch (e) {
      // Re-throw the error to be caught by the UI
      rethrow;
    }
  }

Future<String> logIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw AuthException('Login failed, user not found.');
      }
      final role= user.userMetadata?['role'];
      if(role == null){
        throw AuthException('User role not found.');
      }
      return role as String;

    } catch (e) {
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        // This tells Google where to redirect the user
        // back to after they sign in on the Google website.
        redirectTo: _deepLink,
      );
    } catch (e) {
      // Handle or rethrow the error
      rethrow;
    }
  }
}