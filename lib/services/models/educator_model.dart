import 'package:t_racks_softdev_1/services/models/profile_model.dart';

class Educator {
  final Profile profile;
  final String birthDate;
  final int age;
  final String? gender;
  final String institution;

  Educator({
    required this.profile,
    required this.birthDate,
    required this.age,
    this.gender,
    required this.institution,
  });

  factory Educator.fromJson(Map<String, dynamic> json) {
    // The 'educator_data' key comes from our Supabase query alias
    final educatorData = json['educator_data'] as List?;
    if (educatorData == null || educatorData.isEmpty) {
      throw Exception('Educator data not found in JSON');
    }
    final educatorMap = educatorData.first as Map<String, dynamic>;

    return Educator(
      profile: Profile.fromJson(json),
      birthDate: educatorMap['birthDate'] as String,
      age: educatorMap['age'] as int,
      gender: educatorMap['gender'] as String?,
      institution: educatorMap['institution'] as String,
    );
  }

  String get fullName => '${profile.firstName} ${profile.lastName}';
}