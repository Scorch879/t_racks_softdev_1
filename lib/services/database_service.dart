import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_racks_softdev_1/services/models/educator_model.dart';
import 'package:t_racks_softdev_1/services/models/profile_model.dart';
import 'package:t_racks_softdev_1/services/models/class_model.dart';
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

  ///
  ///
  ///
  ///Fetch functions right here
  ///
  ///
  ///
  Future<Profile?> getProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw 'User is not logged in';
      }
      final data = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

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

      // The email is in the auth session, not the profiles table.
      // We add it to the map before parsing the JSON.
      final userEmail = _supabase.auth.currentUser?.email;
      if (userEmail != null) {
        data['email'] = userEmail;
      }

      return Student.fromJson(data);
    } catch (e) {
      // Handle errors, e.g., user is not a student or data is missing.
      print('Error fetching student data: $e');
      return null;
    }
  }

  /// Fetches the classes for the current student.
  Future<List<StudentClass>> getStudentClasses() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // This query fetches all classes that the current user is enrolled in.
      // It uses the 'Enrollments_Table' as the join table.
      final data = await _supabase
          .from('Classes_Table')
          .select('*, Enrollments_Table!inner(*)')
          .eq('Enrollments_Table.student_id', userId);

      final classes = (data as List)
          .map((item) => StudentClass.fromJson(item))
          .toList();
      return classes;
    } catch (e) {
      print('Error fetching student classes: $e');
      rethrow;
    }
  }

  ///
  ///
  ///
  ///Update functions right here
  ///
  ///
  ///
  /// Updates the data for a student user in the database.
  Future<void> updateStudentData({
    required String firstName,
    required String lastName,
    required String? institution,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // 1. Update the 'profiles' table
      final profileUpdate = {
        'firstName': firstName,
        'lastName': lastName,
      };
      await _supabase.from('profiles').update(profileUpdate).eq('id', userId);

      // 2. Update the 'Student_Table'
      final studentUpdate = {'institution': institution};
      await _supabase
          .from('Student_Table')
          .update(studentUpdate)
          .eq('id', userId);
    } catch (e) {
      // Rethrow the error to be handled by the UI
      print('Error updating student data: $e');
      rethrow;
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

class AccountServices {
  Future<void> deleteProfile() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw 'User is not logged in';
      }

      await _supabase.from('profiles').delete().eq('id', userId);
    } catch (e) {
      throw 'Error deleting profile: $e';
    }
  }
}

class ClassesServices {
  Future<void> createClass() async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      if (userId == null) {
        throw 'User is not logged in';
      }

      // Class creation logic goes here

    } catch (e) {
      throw 'Error creating class: $e';
    }
  }
}