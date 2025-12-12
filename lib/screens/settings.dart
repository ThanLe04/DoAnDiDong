import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'login_screen.dart';
import '../audio_manager.dart';

class SettingsScreen extends StatefulWidget {
  final User user;
  const SettingsScreen({super.key, required this.user});

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  double _volume = AudioManager().currentVolume;
  
  // Màu chủ đạo của App
  final Color appPrimaryColor = const Color.fromARGB(255, 101, 165, 233);
  final Color scaffoldBgColor = const Color(0xFFF2F2F7); // Màu nền xám nhạt kiểu iOS

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: const Text(
          'Cài đặt',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: scaffoldBgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.blueAccent),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- SECTION 1: Cài đặt chung ---
            const Padding(
              padding: EdgeInsets.only(left: 10, bottom: 8),
              child: Text(
                "CÀI ĐẶT CHUNG",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  // Mục 1: Âm thanh (Custom Slider)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Icon(Icons.volume_up, color: Colors.white, size: 18),
                            ),
                            const SizedBox(width: 12),
                            const Text("Âm lượng nhạc nền", style: TextStyle(fontSize: 16)),
                            const Spacer(),
                            Text("${(_volume * 100).round()}%", style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                        Slider(
                          value: _volume,
                          activeColor: appPrimaryColor,
                          inactiveColor: appPrimaryColor.withOpacity(0.2),
                          onChanged: (value) {
                            setState(() {
                              _volume = value;
                              AudioManager().setVolume(value);
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- SECTION 2: Khác ---
            const Padding(
              padding: EdgeInsets.only(left: 10, bottom: 8),
              child: Text(
                "KHÁC",
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  _buildSettingsItem(
                    icon: Icons.star_rate_rounded,
                    iconColor: Colors.purple,
                    title: "Đánh giá ứng dụng",
                    onTap: () {},
                  ),
                  const Divider(height: 1, indent: 50),
                  _buildSettingsItem(
                    icon: Icons.help_outline,
                    iconColor: Colors.green,
                    title: "Trợ giúp & Hỗ trợ",
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // --- NÚT ĐĂNG XUẤT ---
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _showLogoutDialog,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Đăng xuất",
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            Center(
              child: Text(
                "Phiên bản 1.0.0",
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget dùng chung cho từng dòng cài đặt (giống iOS)
  Widget _buildSettingsItem({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: iconColor,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
      title: Text(title, style: const TextStyle(fontSize: 16)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
    );
  }

  // Hàm xử lý Đăng xuất
  void _showLogoutDialog() async {
    bool? confirmSignOut = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmSignOut == true) {
      if (!mounted) return;
      await FirebaseAuth.instance.signOut();
      
      // Dùng pushAndRemoveUntil để xóa sạch lịch sử điều hướng, tránh nút Back
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }
}