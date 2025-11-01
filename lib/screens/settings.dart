import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';// Đảm bảo import dịch vụ đăng nhập/đăng xuất
import 'login_screen.dart';
import '../audio_manager.dart';


class SettingsScreen extends StatefulWidget {
  final User user;
  const SettingsScreen({super.key, required this.user});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _volume = AudioManager().currentVolume; // Lấy âm lượng hiện tại từ AudioManager
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(fontSize: 24),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 20),
                    const Text(
                      'Âm lượng nhạc nền',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Color.fromARGB(255, 5, 6, 116),       // Màu phần đã chọn
                        inactiveTrackColor: Colors.blue[100], // Màu phần chưa chọn
                        thumbColor: const Color.fromARGB(255, 81, 161, 241),       // Màu nút tròn
                        overlayColor: Colors.blue.withAlpha(32), // Hiệu ứng khi kéo
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20.0),
                      ),
                      child: Slider(
                        value: _volume,
                        min: 0.0,
                        max: 1.0,
                        divisions: 10,
                        label: '${(_volume * 100).round()}%',
                        onChanged: (value) {
                          setState(() {
                            _volume = value;
                            AudioManager().setVolume(value); // Cập nhật âm lượng
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 30),
                    _buildMenuButton(
                      context,
                      'Đăng xuất',
                      Icons.exit_to_app,
                      () async {
                        bool? confirmSignOut = await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Xác nhận'),
                            content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(true),
                                child: const Text('Đăng xuất'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(false),
                                child: const Text('Không'),
                              ),
                            ],
                          ),
                        );
                        if (confirmSignOut == true) {
                          Navigator.pop(context); // Đóng Settings
                          await FirebaseAuth.instance.signOut();
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LoginScreen()),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 20),
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
      width: 250,
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
