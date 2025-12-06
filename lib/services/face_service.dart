import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

class FaceMatchResult {
  final String studentId;
  final String fullName;
  final double distance;

  FaceMatchResult({
    required this.studentId,
    required this.fullName,
    required this.distance,
  });
}

class FaceRecognitionService {
  Future<FaceMatchResult?> findMatchingStudent(
    List<double> faceEmbedding,
  ) async {
    try {
      final embeddingString = faceEmbedding.toString();

      // FIX: TIGHTEN THRESHOLD
      // 0.40 is strict enough to reject random people
      const matchThreshold = 0.40;

      final response = await _supabase.rpc(
        'match_face',
        params: {
          'embedding_to_match': embeddingString,
          'match_threshold': matchThreshold,
        },
      );

      if (response == null || (response as List).isEmpty) {
        return null;
      }

      final match = (response as List).first;

      return FaceMatchResult(
        studentId: match['student_id'],
        fullName: match['full_name'],
        distance: (match['distance'] as num).toDouble(),
      );
    } catch (e) {
      print('Error finding matching student: $e');
      return null;
    }
  }
}
