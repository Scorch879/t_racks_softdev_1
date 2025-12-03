import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import 'dart:convert'; // Import for jsonEncode

 final _supabase = Supabase.instance.client;
class OnboardingService {
 
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
      final userId = _supabase.auth.currentUser?.id;
      final phoneNum = _supabase.auth.currentUser?.phone;
      if(userId == null){
        throw 'User is not logged in';
      } 

      //Profile data prep

      final profileData  = {
        'id': userId,
        'firstName': firstname,
        'middleName': middlename,
        'lastName': lastname,
        'role': role,
        //ambot sa phone num
        };

      final studentData = {
        'id' : userId,
        'birthDate': birthDate, // Corrected from 'birthData' in previous context if it was reverted
        'age': age,
        'gender': gender,
        'institution': institution,
        'program': program,
        'educationalLevel': educationalLevel,
        'gradeYearLevel': gradeYearLevel,
      };

      ///RPC METHOD IN SUPABASE
      /*suggestion for safer method custom rpc method command need to be coded in supabase 
      await _supabase.rpc('save_student_profile', params: {
        'profile_data': profileData,
        'student_data': studentData,
      });
      
      */

      //Simple method for now
      await _supabase.from('profiles').upsert(profileData);
      await _supabase.from('Student_Table').upsert(studentData);

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
      final userId = _supabase.auth.currentUser?.id;
      if(userId == null){
        throw 'User is not logged in';
      } 

      //Profile data prep

      final profileData  = {
        'id': userId,
        'firstName': firstname,
        'middleName': middlename,
        'lastName': lastname,
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
      await _supabase.from('profiles').upsert(profileData);
      await _supabase.from('Educator_Table').upsert(educatorData);

    } catch (e) {
        rethrow;
    }
  }

}

class AiServices {
  /// Saves the user's face image to storage and the vector to the database.
  ///
  /// [imageFile]: The captured image file from the camera.
  /// [faceVector]: The List<double> representing the face embedding.
  Future<void> saveFaceData({
    required File imageFile,
    required List<double> faceVector,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw 'User not logged in';

      // 1. Upload the face image to Supabase Storage.
      // You must create a bucket named 'face_images' in your Supabase dashboard
      // with public access turned OFF for security.
      final imagePath = '$userId/face.jpg';
      await _supabase.storage.from('face_images').upload(
            imagePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600', // Optional: cache for 1 hour
              upsert: true, // Overwrite if the user re-registers their face
            ),
          );

      // 2. Save the face vector to the 'Face_Table'.
      // Using upsert is a good practice here to handle cases where the user
      // might re-register their face. For pgvector, we convert the List to a string.
      await _supabase
          .from('Face_Table')
          .upsert({'student_id': userId, 'face_id': faceVector.toString()});
    } catch (e) {
      print('Error saving face data: $e');
      rethrow;
    }
  }
}
