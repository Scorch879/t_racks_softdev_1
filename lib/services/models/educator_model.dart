import 'package:t_racks_softdev_1/services/models/profile_model.dart';

class Educator {
  final Profile profile;
  final String birthDate;
  final int age;
  final String? gender;
  final String institution;
  final String bio;

  Educator({
    required this.profile,
    required this.birthDate,
    required this.age,
    this.gender,
    required this.institution,
    required this.bio,
  });

  factory Educator.fromJson(Map<String, dynamic> json) {
    // 1. Read as 'dynamic' first to prevent immediate crash
    final dynamic rawData = json['educator_data'];
    
    Map<String, dynamic> educatorMap;

    // 2. Check the type safely
    if (rawData is List) {
      if (rawData.isEmpty) {
        educatorMap = {}; 
      } else {
        educatorMap = rawData.first as Map<String, dynamic>;
      }
    } else if (rawData is Map) {
      // It is a single object (Map), so just use it
      educatorMap = rawData as Map<String, dynamic>;
    } else {
      // It is null or unknown
      educatorMap = {};
    }

    return Educator(
      profile: Profile.fromJson(json),
      birthDate: educatorMap['birthDate']?.toString() ?? '',
      // Use 'num' to safely handle both int and double from DB
      age: (educatorMap['age'] as num?)?.toInt() ?? 0, 
      gender: educatorMap['gender'] as String?,
      institution: educatorMap['institution'] as String? ?? '',
      bio: educatorMap['bio'] as String? ?? '',
    );
  }

  String get fullName => '${profile.firstName} ${profile.lastName}';
}