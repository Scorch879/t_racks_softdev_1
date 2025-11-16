import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/splash_screen.dart'; // atong import sa screen
import 'package:supabase_flutter/supabase_flutter.dart'; //database 
import 'package:flutter_dotenv/flutter_dotenv.dart'; //ambot murag .env rani

Future<void> main() async {
  await dotenv.load(fileName: ".env");
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'T-racks',
      
      home: const SplashScreen(), // Set SplashScreen as the initial screen
    );
  }
}