import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'chart_screen.dart';
import 'settings.dart';
import 'login_screen.dart';

class ProfileTab extends StatelessWidget {
  final User user;
  const ProfileTab({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    // Màu chủ đạo
    const Color appPrimaryColor = Color(0xFF578FCA);
    const Color scaffoldBgColor = Color(0xFFF5F7FA); // Xám rất nhạt

    return Scaffold(
      backgroundColor: scaffoldBgColor,
      appBar: AppBar(
        title: const Text(
          'Hồ sơ cá nhân',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.black87),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => SettingsScreen(user: user)));
            },
          )
        ],
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('users/${user.uid}').onValue,
        builder: (context, snapshot) {
          // Xử lý dữ liệu
          String name = "Người dùng";
          String? avatarBase64;
          int streak = 0;
          int coins = 0;
          String email = user.email ?? "";

          if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
            final data = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
            name = data['name'] ?? "Người dùng";
            avatarBase64 = data['avatarBase64'];
            streak = (data['streak'] ?? 0) as int;
            coins = (data['coins'] ?? 0) as int;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // --- 1. HEADER PROFILE ---
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar to
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: appPrimaryColor.withOpacity(0.2), width: 2),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundImage: avatarBase64 != null
                              ? MemoryImage(base64Decode(avatarBase64))
                              : const AssetImage('assets/avatar1.png') as ImageProvider,
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Tên
                      Text(
                        name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      // Email
                      Text(
                        email,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 20),
                      
                      // --- STATS ROW (Streak & Coin) ---
                      Row(
                        children: [
                          _buildStatCard("Chuỗi ngày", "$streak", Icons.local_fire_department, Colors.orange),
                          const SizedBox(width: 15),
                          _buildStatCard("Đồng vàng", "$coins", Icons.monetization_on, Colors.amber),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // --- 2. THẺ BIỂU ĐỒ NĂNG LỰC (Highlight) ---
                GestureDetector(
                  onTap: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => ChartScreen(user: user)));
                  },
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF578FCA), Color(0xFF7CB9F2)], // Gradient xanh
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: appPrimaryColor.withOpacity(0.4), blurRadius: 10, offset: const Offset(0, 5))
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.pie_chart, color: Colors.white, size: 30),
                        ),
                        const SizedBox(width: 15),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Biểu đồ Năng lực",
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Xem phân tích chi tiết não bộ",
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // --- 3. MENU LIST ---
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: Icons.history, 
                        color: Colors.blueAccent, 
                        title: "Lịch sử đấu", 
                        onTap: () {
                          // TODO: Navigate to History
                        }
                      ),
                      const Divider(height: 1, indent: 60, endIndent: 20),
                      _buildMenuItem(
                        icon: Icons.emoji_events, 
                        color: Colors.purple, 
                        title: "Thành tựu & Huy hiệu", 
                        onTap: () {
                          // TODO: Navigate to Achievements
                        }
                      ),
                      const Divider(height: 1, indent: 60, endIndent: 20),
                      _buildMenuItem(
                        icon: Icons.logout, 
                        color: Colors.redAccent, 
                        title: "Đăng xuất", 
                        isDestructive: true,
                        onTap: () async {
                          _showLogoutDialog(context);
                        }
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  // Widget con: Thẻ thống kê nhỏ (Streak/Coin)
  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // Widget con: Dòng Menu
  Widget _buildMenuItem({
    required IconData icon, 
    required Color color, 
    required String title, 
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isDestructive ? Colors.red : Colors.black87,
          fontWeight: isDestructive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }

  // Hàm xử lý Đăng xuất
  void _showLogoutDialog(BuildContext context) async {
    bool? confirmSignOut = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn thoát?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmSignOut == true) {
      await FirebaseAuth.instance.signOut();
      // Xóa stack điều hướng về Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }
}