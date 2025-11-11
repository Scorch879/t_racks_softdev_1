import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingService {
  final _superbase = Supabase.instance.client;


  ///Saves Student Data across profile and Student Table
  Future<void> saveStudentProfile({
    //for profiles table
    required String firstname,
    required String middlename,
    required String lastname,
    required String role,

    //student user's table
    required String birthDate,
    required int age,
    required String? gender,
    required String institution,
    required String? program,
    required String? educationalLevel,
    required String? gradeYearLevel,
  }) async {
    try {
      final userId = _superbase.auth.currentUser?.id;
      if(userId == null){
        throw 'User is not logged in';
      } 

      //Profile data prep

      final profileData  = {
        'id': userId,
        'firstname': firstname,
        'middlename': middlename,
        'lastname': lastname,
        'role': role,
        //ambot sa phone num
        };

      final studentData = {
        'id' : userId,
        'birth_data': birthDate,
        'age': age,
        'gender': gender,
        'institution': institution,
        'program': program,
        'educational_level': educationalLevel,
        'grade_year_level': gradeYearLevel,
      };

      ///RPC METHOD IN SUPABASE
      /*suggestion for safer method custom rpc method command need to be coded in supabase 
      await _supabase.rpc('save_student_profile', params: {
        'profile_data': profileData,
        'student_data': studentData,
      });
      
      */

      //Simple method for now
      await _superbase.from('profiles').upsert(profileData);
      await _superbase.from('student_users').upsert(studentData);

    } catch (e) {
        rethrow;
    }
  }

  ///Saves Educator Data across profile and Educator's Table
  Future<void> saveEducatorProfile({
    //for profiles table
    required String firstname,
    required String middlename,
    required String lastname,
    required String role,

    //educator user's table
    required String birthDate,
    required int age,
    required String? gender,
    required String institution
  }) async {
    try {
      final userId = _superbase.auth.currentUser?.id;
      if(userId == null){
        throw 'User is not logged in';
      } 

      //Profile data prep

      final profileData  = {
        'id': userId,
        'firstname': firstname,
        'middlename': middlename,
        'lastname': lastname,
        'role': role,
        //ambot sa phone num
        };

      final educatorData = {
        'id' : userId,
        'birthDate': birthDate,
        'age': age,
        'gender': gender,
        'institution': institution,
      };
      
      //Simple method for now
      await _superbase.from('profiles').upsert(profileData);
      await _superbase.from('educator_users').upsert(educatorData);

    } catch (e) {
        rethrow;
    }
  }
}
