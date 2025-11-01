import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database
import 'package:my_app/games/caro/screens/HomeScreen.dart';
import 'game_selection.dart'; // Import màn hình Selection Mode
import 'settings.dart';
import 'score_screen.dart';
import '../audio_manager.dart';
import '../services/avatar_service.dart';


class MainMenu extends StatefulWidget {
  final User user;
  const MainMenu({super.key, required this.user});

  @override
  _MainMenuState createState() => _MainMenuState();
}
class _MainMenuState extends State<MainMenu> {
  String username = 'Người dùng';

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _startMusic();

  }

  void _startMusic() async {
    await AudioManager().startMusic(); // ← Đây là nơi chạy nhạc nền
  }

  Future<String> fetchUsername(User user) async {
    try {
      final ref = FirebaseDatabase.instance.ref('users/${user.uid}');
      final snapshot = await ref.get();

      if (snapshot.exists) {
        final data = snapshot.value as Map;
        return data['name'] ?? 'Người dùng';
      } else {
        return 'Người dùng';
      }
    } catch (e) {
      print('Lỗi khi lấy tên: $e');
      return 'Người dùng';
    }
  }
  void _loadUsername() async {
    String name = await fetchUsername(widget.user);
    setState(() {
      username = name;
    });
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Góc trên bên trái: chào người dùng
          Padding(
            padding: const EdgeInsets.only(top: 30, left: 20),
            child: StreamBuilder(
              stream: FirebaseDatabase.instance
                  .ref('users/${widget.user.uid}')
                  .onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  final data = Map<String, dynamic>.from(
                      snapshot.data!.snapshot.value as Map);
                  final avatarBase64 = data['avatarBase64'];

                  return Row(
                    children: [
                      // Avatar người dùng
                      GestureDetector(
                        onTap: () async {
                          await pickAndUploadAvatarBase64(widget.user.uid);
                          setState(() {}); // Cập nhật lại giao diện
                        },
                        child: CircleAvatar(
                          radius: 32,
                          backgroundImage: avatarBase64 != null
                          ? MemoryImage(base64Decode(avatarBase64))
                          : AssetImage('assets/avatar1.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Chữ "Xin chào"
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            username,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  );
                } else {
                  return Row(
                    children: [
                      CircleAvatar(radius: 32, backgroundColor: Colors.grey),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(username,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  );
                }
              },
            ),
          ),


          const SizedBox(height: 20),

          // Tên app: Academy of Genius
          Center(
            child: Text(
              'Academy of Genius',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                fontFamily: 'Lobster',
                color: Colors.white, // Hoặc màu tuỳ chỉnh
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 40),

          // Các nút menu
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 15),
                  _buildMenuButton(context, 'Caro X/O', Icons.videogame_asset, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => HomeScreen()),
                    );
                  }),
                  const SizedBox(height: 15),
                  _buildMenuButton(context, 'Chọn Trò Chơi', Icons.videogame_asset, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => GameSelection(user: widget.user)),
                    );
                  }),
                  const SizedBox(height: 15),
                  _buildMenuButton(context, 'Bảng xếp hạng', Icons.bar_chart, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => ScoreScreen()),
                    );
                  }),
                  const SizedBox(height: 15),
                  _buildMenuButton(context, 'Cài đặt', Icons.settings, () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => SettingsScreen(user: widget.user)),
                    );
                  }),
                  const SizedBox(height: 15),
                  _buildMenuButton(context, 'Thoát', Icons.exit_to_app, () async {
                    bool? confirmExit = await showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Xác nhận'),
                        content: const Text('Bạn có chắc muốn thoát ứng dụng không?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Có'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Không'),
                          ),
                        ],
                      ),
                    );
                    if (confirmExit == true) {
                      SystemNavigator.pop();
                    }
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


Widget _buildMenuButton(BuildContext context, String title, IconData icon, VoidCallback onPressed) {
  return SizedBox(
    width: 250, // Kích thước vừa phải
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24),
          const SizedBox(width: 10),
          Text(title, style: const TextStyle(fontSize: 18)),
        ],
      ),
    ),
  );
}
}
