import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'onboarding_survey_screen.dart';
import 'main_screen.dart';
import 'register_screen.dart';
import 'ForgotPasswordScreen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _accountController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String input = _accountController.text.trim();
    String password = _passwordController.text;

    try {
      String? email;

      // Nếu nhập email thì dùng trực tiếp
      if (input.contains('@')) {
        email = input;
      } else {
        // Tìm email tương ứng với username trong Realtime Database
        final snapshot = await FirebaseDatabase.instance
            .ref()
            .child('users')
            .orderByChild('name')
            .equalTo(input)
            .once();

        final data = snapshot.snapshot.value as Map?;
        if (data != null && data.isNotEmpty) {
          final firstUser = data.entries.first.value;
          email = firstUser['email'];
        } else {
          throw FirebaseAuthException(
            code: 'user-not-found',
            message: 'Không tìm thấy người dùng với tên này.',
          );
        }
      }

      // Đăng nhập bằng email và mật khẩu
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email!, password: password);

      User? user = userCredential.user;

      if (user != null && user.emailVerified) {
        final snapshot = await FirebaseDatabase.instance
          .ref('users/${user.uid}/hasCompletedOnboarding')
          .get();
        final bool hasCompleted = (snapshot.value ?? false) as bool;
        // ---------------------------------

        if (mounted) { // Kiểm tra context
          if (hasCompleted) {
            // 1. Đã làm khảo sát -> Vào MainMenu
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => MainScreen(user: user)),
            );
          } else {
            // 2. CHƯA làm khảo sát -> Vào Survey
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => OnboardingSurveyScreen(user: user)),
            );
          }
        } 
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng xác thực email trước khi đăng nhập.')),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.message}')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng nhập')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _accountController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email hoặc tên người dùng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _login,
                          child: const Text('Đăng nhập'),
                        ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RegisterScreen()),
                      );
                    },
                    child: const Text(
                      'Chưa có tài khoản? Đăng ký',
                      style: TextStyle(
                        color: Colors.white,         // 👉 đổi màu chữ
                        fontSize: 16,               // 👉 tăng kích thước chữ
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()),
                      );
                    },
                    child: const Text(
                      'Quên mật khẩu?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
