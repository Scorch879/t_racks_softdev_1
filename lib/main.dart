import 'package:flutter/material.dart';
import 'package:t_racks_softdev_1/screens/onBoarding_screen/onBoarding_screen.dart';
import 'package:t_racks_softdev_1/screens/splash_screen.dart'; // atong import sa screen
import 'package:supabase_flutter/supabase_flutter.dart'; //database 
import 'package:flutter_dotenv/flutter_dotenv.dart'; //ambot murag .env rani
import 'package:t_racks_softdev_1/screens/onBoarding_screen/onBoarding_screen.dart';
import 'package:t_racks_softdev_1/screens/student_home_screen.dart';
Future<void> main() async {
  //mag load og variables from the env file
  await dotenv.load(fileName: ".env");

  //makes sure fluttter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // load in with variables gikan sa env
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
      
      debugShowCheckedModeBanner: false, // This removes the "Debug" banner in the corner
      title: 'T-racks',
      
      home: const SplashScreen(), // Set SplashScreen as the initial screen
    );
  }
}