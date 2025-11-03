import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart'; // Import Firebase Realtime Database
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
  // Bỏ biến 'username' và hàm _loadUsername, fetchUsername
  // vì StreamBuilder sẽ xử lý việc này

  @override
  void initState() {
    super.initState();
    // _loadUsername(); // <-- XÓA DÒNG NÀY
    _startMusic();
  }

  void _startMusic() async {
    await AudioManager().startMusic();
  }

  // HÀM fetchUsername VÀ _loadUsername CÓ THỂ XÓA
  // (StreamBuilder đã thay thế chúng)

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
                  // --- CẬP NHẬT TỪ ĐÂY ---
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    final data = Map<String, dynamic>.from(
                        snapshot.data!.snapshot.value as Map);
                    
                    // Đọc dữ liệu từ snapshot
                    final avatarBase64 = data['avatarBase64'];
                    final String currentUsername = data['name'] ?? 'Người dùng';
                    final int streak = (data['streak'] ?? 0) as int; // Lấy streak

                    return Row(
                      children: [
                        // Avatar người dùng
                        GestureDetector(
                          onTap: () async {
                            await pickAndUploadAvatarBase64(widget.user.uid);
                            // setState(() {}); // StreamBuilder tự cập nhật, không cần setState
                          },
                          child: CircleAvatar(
                            radius: 32,
                            backgroundImage: avatarBase64 != null
                                ? MemoryImage(base64Decode(avatarBase64))
                                : const AssetImage('assets/avatar1.png') as ImageProvider,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Cột chứa Tên và Streak
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Tên người dùng (lấy từ snapshot)
                            Text(
                              currentUsername, // Dùng tên live
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4), // Khoảng cách nhỏ
                            
                            // Hàng chứa icon Lửa và số
                            Row(
                              children: [
                                const Icon(
                                  Icons.local_fire_department, // Icon ngọn lửa
                                  color: Colors.orangeAccent, // Màu cam
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '$streak', // Hiển thị số ngày streak
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orangeAccent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    // Giao diện khi đang tải
                    return const Row(
                      children: [
                        CircleAvatar(radius: 32, backgroundColor: Colors.grey),
                        SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Đang tải...',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    );
                  }
                  // --- KẾT THÚC CẬP NHẬT ---
                },
              ),
            ),


            const SizedBox(height: 20),

            // Tên app: Academy of Genius
            const Center(
              child: Text(
                'Academy of Genius',
                style: TextStyle(
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