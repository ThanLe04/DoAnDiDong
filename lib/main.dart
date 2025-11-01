import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Academy of Genius',
      theme: ThemeData(
        primaryColor: const Color(0xFF578FCA), // Màu chính
        scaffoldBackgroundColor: const Color(0xFF578FCA), // Nền xanh
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF578FCA),
          foregroundColor: Colors.white, // Màu chữ tiêu đề app bar
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF578FCA),
          ),
        ),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
          fillColor: Colors.white, // Nền ô nhập trắng
          border: OutlineInputBorder(),
        ),
      ),
      home: const SplashScreen(), // Màn hình đầu tiên
    );
  }
}
