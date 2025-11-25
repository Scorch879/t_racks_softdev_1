import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:t_racks_softdev_1/screens/splash_screen.dart';
import 'package:t_racks_softdev_1/screens/student_home_screen.dart';
import 'package:t_racks_softdev_1/screens/educator/educator_shell.dart';

Future<void> main() async {
  // Ensure Flutter bindings are initialized before any async operations.
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");

  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseAnonKey == null) {
    throw Exception('Supabase URL or Anon Key not found in .env file');
  }

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'T-racks',
      home: const SplashScreen(),
      routes: {
        '/studentHome': (context) => const StudentHomeScreen(),
        '/educatorHome': (context) => const EducatorShell(),
      },
    );
  }
}