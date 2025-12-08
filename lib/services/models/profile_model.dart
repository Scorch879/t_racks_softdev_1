class Profile {
  final String id;
  final String firstName;
  final String? middleName;
  final String lastName;
  final String email;
  final String role;
  final String? profilePictureUrl;

  Profile({
    required this.id,
    required this.firstName,
    this.middleName,
    required this.lastName,
    required this.email,
    required this.role,
    this.profilePictureUrl,
  });

  // A factory constructor for creating a new Profile instance from a map.
  // This is useful when you get data from Supabase.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String??'',
      firstName: json['firstName'] as String? ??'',
      middleName: json['middleName'] as String?,
      lastName: json['lastName'] as String? ??'',
      email : json['email'] as String? ??'',
      role: json['role'] as String? ??'',
      profilePictureUrl: json['profile_picture_url'] as String?,
    );  
  }

  String get fullName => '$firstName $lastName';
}