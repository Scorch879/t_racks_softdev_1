import 'package:supabase_flutter/supabase_flutter.dart';

final _supabase = Supabase.instance.client;

/// A data class to hold the result of a face match.
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
  /// Finds the closest matching student for a given face embedding.
  ///
  /// [faceEmbedding]: The vector generated from the live camera feed.
  /// Returns a [FaceMatchResult] if a match is found within the threshold, otherwise null.
  Future<FaceMatchResult?> findMatchingStudent(
      List<double> faceEmbedding) async {
    try {
      // The vector needs to be passed as a string in the format '[1.2, 3.4, ...]'
      final embeddingString = faceEmbedding.toString();

      // This is the cosine distance threshold. A lower value means a stricter match.
      // You will need to tune this value. Start with 0.5 and adjust.
      const matchThreshold = 0.7; // Increased for more tolerance

      final response = await _supabase.rpc('match_face', params: {
        'embedding_to_match': embeddingString,
        'match_threshold': matchThreshold,
      });

      // If the RPC returns an empty list, no match was found.
      if (response == null || (response as List).isEmpty) {
        return null;
      }

      final match = (response as List).first;

      // For debugging: print the distance of the found match.
      print('Found a match for ${match['full_name']} with distance: ${match['distance']}');

      return FaceMatchResult(
          studentId: match['student_id'],
          fullName: match['full_name'],
          distance: (match['distance'] as num).toDouble());
    } catch (e) {
      print('Error finding matching student: $e');
      return null;
    }
  }
}