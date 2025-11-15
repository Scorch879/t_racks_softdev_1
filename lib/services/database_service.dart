import 'package:supabase_flutter/supabase_flutter.dart';
final _supabase = Supabase.instance.client;

///This service handles all database related operations except for onboarding.
///Onboarding related database operations are handled in onboarding_service.dart

class DatabaseService {
  

  //Profile Checker Service
  Future<bool> checkIfUserExists() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw 'User is not logged in';
      }

      await _supabase.from('profiles').select('id').eq('id', userId).single();

      //if single() returns with no random ahh errors. Naay profile woohoo
      return true;
    } catch (e) {
      return false;
    }
  }
}class AuthService {
  
  }