import 'package:supabase_flutter/supabase_flutter.dart';

class OnboardingService {
  final _supabase = Supabase.instance.client;

  /// Saves the user's profile data to the 'profiles' table in Supabase.
  ///
  /// The [data] map should contain all the profile information to be saved.
  /// It constructs the data map and includes the user's ID.
  Future<void> saveUserProfile({
    required String fullName,
    required String birthDate,
    required String age,
    required String? gender,
    required String institution,
    required String role,
    String? educationalLevel,
    String? gradeYearLevel,
    String? program,
  }) async {
    try {
      // 1. Fetch User ID from superbase auth
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw 'User is not logged in.';
      }

      // 2. Create the data map from the provided fields.
      final Map<String, dynamic> dataToSave = {
        'id': userId, // Primary key
        'full_name': fullName,
        'birth_date': birthDate,
        'age': int.tryParse(age),
        'gender': gender,
        'institution': institution,
        'role': role,
        'educational_level': educationalLevel,
        'grade_year_level': gradeYearLevel,
        'program': program,
      };

      // 3. Use 'upsert' to save the data.
      //    - If a row with this `id` exists, it will be UPDATED.
      //    - If no row with this `id` exists, it will be INSERTED.
      await _supabase.from('profiles').upsert(dataToSave);

    } catch (e) {
      // 4. If anything goes wrong (network error, database policy violation),
      //    re-throw the error so the UI can catch it and notify the user.
      rethrow;
    }
  }
}
