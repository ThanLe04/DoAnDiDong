import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'main_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });
  
    try {
      // Kiểm tra xem tên người dùng đã tồn tại chưa
      final username = _nameController.text.trim();
      final usernameSnapshot = await FirebaseDatabase.instance
          .ref()
          .child('usernames')
          .child(username)
          .get();

      if (usernameSnapshot.exists) {
        // Thông báo cho người dùng biết tên đã tồn tại
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tên người dùng đã tồn tại, vui lòng chọn tên khác')),
        );
        setState(() {
          _isLoading = false;
        });
        return;
      }
      // Tạo tài khoản
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      User? user = userCredential.user;

      // Lưu dữ liệu vào Realtime Database
      DatabaseReference usersRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(user!.uid);

      final ByteData bytes = await rootBundle.load('assets/avatars/avatar1.png');
      final Uint8List imageBytes = bytes.buffer.asUint8List();
      final String base64Image = base64Encode(imageBytes);
      await usersRef.set({
        'name': _nameController.text,
        'email': user.email,
        'avatarBase64': base64Image,
        'highScores': {
          'memoryGame': 0,
          'observationGame': 0,
          'logicGame': 0,
          'calculationGame': 0,
        },
        'streak': 0, // Bắt đầu chuỗi = 0
        'lastPlayedDate': '',
        'hasCompletedOnboarding': false, // Đổi tên từ 'hasCompletedPlacementTest'
        'ageGroup': '',                 // Lưu nhóm tuổi (ví dụ: '18-25')
        'preferredCategory': '',
        'coins': 100,
      });

      // Gửi email xác thực
      await user.sendEmailVerification();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng kiểm tra email để xác thực.')),
      );

      // Chờ xác thực
      await _waitForEmailVerification(user);

      if (user.emailVerified) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainScreen(user: user)),
        );
      }

    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi: ${e.message}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _waitForEmailVerification(User user) async {
    while (!user.emailVerified) {
      await Future.delayed(const Duration(seconds: 3));
      await user.reload();
      user = FirebaseAuth.instance.currentUser!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Tên người dùng'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên người dùng';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập email';
                      }
                      if (!value.contains('@')) {
                        return 'Email không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.length < 6) {
                        return 'Mật khẩu phải ít nhất 6 ký tự';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _signUp,
                          child: const Text('Đăng ký'),
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
