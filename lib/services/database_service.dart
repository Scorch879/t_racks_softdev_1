import 'package:supabase_flutter/supabase_flutter.dart';


///This service handles all database related operations except for onboarding.
///Onboarding related database operations are handled in onboarding_service.dart

class DatabaseService {
  final _supabase = Supabase.instance.client;
}

