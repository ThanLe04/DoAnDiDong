import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import 'main_menu.dart'; // Màn hình chính sau khi đăng nhập
import 'package:firebase_database/firebase_database.dart';
import 'onboarding_survey_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 2)); // Thời gian chờ splash
    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // Đã đăng nhập -> KIỂM TRA XEM ĐÃ LÀM KHẢO SÁT CHƯA
      try {
        final snapshot = await FirebaseDatabase.instance
            .ref('users/${user.uid}/hasCompletedOnboarding') // Dùng key mới
            .get();

        final bool hasCompleted = (snapshot.value ?? false) as bool;

        if (hasCompleted) {
          // Đã làm -> Vào Main Menu
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => MainMenu(user: user)),
          );
        } else {
          // CHƯA làm -> Bắt buộc vào Màn hình Khảo sát
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => OnboardingSurveyScreen(user: user)),
          );
        }
      } catch (e) {
        // Nếu có lỗi, cứ cho vào Login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    } else {
      // Chưa đăng nhập → về màn hình đăng nhập
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF578FCA),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.school, size: 80, color: Colors.white),
            SizedBox(height: 20),
            Text(
              "Academy of Genius",
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
