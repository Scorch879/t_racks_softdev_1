import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_racks_softdev_1/services/models/educator_model.dart';
import 'package:t_racks_softdev_1/services/models/profile_model.dart';
import 'package:t_racks_softdev_1/services/models/student_model.dart';

final _supabase = Supabase.instance.client;

///This service handles all database related operations except for onboarding.
///Onboarding related database operations are handled in onboarding_service.dart

class DatabaseService {
  //Profile Checker Service
  Future<bool> checkProfileExists() async {
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

  Future<Profile?> getProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw 'User is not logged in';
      }
      final data = await _supabase.from('profiles').select().eq('id', userId).single();

      return Profile.fromJson(data);
    } catch (e) {
      // Return null if profile not found or an error occurs
      return null;
    }
  }

  /// Fetches the complete data for a student user.
  Future<Student?> getStudentData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // This query joins 'profiles' with 'Student_Table'.
      // 'student_data:Student_Table(*)' creates a nested object with the alias 'student_data'.
      final data = await _supabase
          .from('profiles')
          .select('*, student_data:Student_Table(*)')
          .eq('id', userId)
          .single();

      return Student.fromJson(data);
    } catch (e) {
      // Handle errors, e.g., user is not a student or data is missing.
      print('Error fetching student data: $e');
      return null;
    }
  }

  /// Fetches the complete data for an educator user.
  Future<Educator?> getEducatorData() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // This query joins 'profiles' with 'Educator_Table'.
      // 'educator_data:Educator_Table(*)' creates a nested object with the alias 'educator_data'.
      final data = await _supabase
          .from('profiles')
          .select('*, educator_data:Educator_Table(*)')
          .eq('id', userId)
          .single();

      return Educator.fromJson(data);
    } catch (e) {
      // Handle errors, e.g., user is not an educator or data is missing.
      print('Error fetching educator data: $e');
      return null;
    }
  }
  
}
