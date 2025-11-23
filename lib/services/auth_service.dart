import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:t_racks_softdev_1/services/database_service.dart';

enum AuthNavigationState {
  login,
  onboarding,
  studentHome,
  educatorHome,
}

class AuthService {


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
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
        emailRedirectTo: _deepLink,
        data: {'phone_number': phone, 'role': role},
      );
      if (authResponse.user != null && authResponse.user!.identities!.isEmpty) {
        // 3. Throw the error you wanted
        throw const AuthException('Email already in use.');
      }
    } on AuthException catch (e) {
      // Handle specific auth errors
      if (e.message.toLowerCase() == 'user already registered') {
        throw const AuthException('This email has already been used.');
      }
      // Re-throw other auth errors to be caught by the UI
      rethrow;
    } catch (e) {
      // Re-throw any other errors to be caught by the UI
      rethrow;
    }
  }

  Future<String> logIn({
    required String email,
    required String password,
  }) async {
    try {
      await _supabase.auth.signInWithPassword(email: email, password: password);

      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw AuthException('Login failed, user not found.');
      }
      final role = user.userMetadata?['role'];
      if (role == null) {
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

  //Sign Out Service
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<void> forgotPassword({
    required String email,
  }) async {
    try {
      await _supabase.auth.resetPasswordForEmail(
        email,
        redirectTo: _deepLink,
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Verifies the password reset OTP code sent to the user's email.
  Future<void> verifyPasswordResetOtp({
    required String email,
    required String token,
  }) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        type: OtpType.recovery,
        token: token,
        email: email,
      );
      // If there's no error, the user is temporarily authenticated
      // and can now update their password.
    } catch (e) {
      rethrow;
    }
  }

  /// Updates the user's password after a successful OTP verification.
  Future<void> updateUserPassword({required String newPassword}) async {
    try {
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<AuthNavigationState> determineInitialPath() async {
    try {
      // Check "Remember Me"
      final prefs = await SharedPreferences.getInstance();
      final bool rememberMe = prefs.getBool('remember_me') ?? false;

      final session = _supabase.auth.currentSession;

      // Logic: If session exists but user didn't want to be remembered
      if (session != null && !rememberMe) {
        await _supabase.auth.signOut();
        return AuthNavigationState.login;
      }

      // Logic: No session at all
      if (session == null) {
        return AuthNavigationState.login;
      }

      // Logic: User is logged in. Check Profile & Role.
      final bool didOnboarding = await DatabaseService().checkProfileExists();
      
      if (!didOnboarding) {
        return AuthNavigationState.onboarding;
      }

      // Check Role for Routing
      final user = session.user;
      final role = user.userMetadata?['role'] as String?;

      if (role == 'student') return AuthNavigationState.studentHome;
      if (role == 'educator') return AuthNavigationState.educatorHome;

      // Fallback for unknown roles
      await _supabase.auth.signOut();
      return AuthNavigationState.login;

    } catch (e) {
      // Safety net: if anything crashes, go to login
      return AuthNavigationState.login;
    }
  }
  
  // Helper to get current role (useful for passing to Onboarding screen)
  String? getCurrentUserRole() {
    return _supabase.auth.currentUser?.userMetadata?['role'];
  }
}
}
