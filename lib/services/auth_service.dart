import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  // Get a shorthand for the Supabase client
  final _supabase = Supabase.instance.client;

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

}