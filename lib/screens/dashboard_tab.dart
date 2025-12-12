import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:convert';
import 'game_selection.dart';
import 'game2_selection.dart';
import 'score_screen.dart';
import '../services/avatar_service.dart';
import '../audio_manager.dart';

class DashboardTab extends StatefulWidget {
  final User user;
  const DashboardTab({super.key, required this.user});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  
  @override
  void initState() {
    super.initState();
    AudioManager().startMusic(); 
  }

  @override
  Widget build(BuildContext context) {
    // Màu xanh chủ đạo
    final primaryColor = const Color(0xFF578FCA);

    return Scaffold(
      backgroundColor: Colors.white, // 1. ĐỔI NỀN THÀNH TRẮNG
      
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HEADER (AVATAR, TÊN...) ---
            Padding(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20),
              child: StreamBuilder(
                stream: FirebaseDatabase.instance
                    .ref('users/${widget.user.uid}')
                    .onValue,
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                    final data = Map<String, dynamic>.from(
                        snapshot.data!.snapshot.value as Map);
                    
                    final avatarBase64 = data['avatarBase64'];
                    final String currentUsername = data['name'] ?? 'Người dùng';
                    final int streak = (data['streak'] ?? 0) as int;
                    final int coins = (data['coins'] ?? 0) as int;

                    return Row(
                      children: [
                        // Avatar (Thêm viền xanh để nổi trên nền trắng)
                        GestureDetector(
                          onTap: () async {
                            await pickAndUploadAvatarBase64(widget.user.uid);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(3), 
                            decoration: BoxDecoration(
                              color: primaryColor, // Viền xanh
                              shape: BoxShape.circle,
                            ),
                            child: CircleAvatar(
                              radius: 32,
                              backgroundImage: avatarBase64 != null
                                  ? MemoryImage(base64Decode(avatarBase64))
                                  : const AssetImage('assets/avatar1.png') as ImageProvider,
                            ),
                          ),
                        ),
                        const SizedBox(width: 15),
                        
                        // Thông tin
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentUsername,
                              style: TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold,
                                color: Colors.black87, // 2. ĐỔI MÀU CHỮ THÀNH ĐEN
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Row chứa Streak và Coin
                            Row(
                              children: [
                                // Streak Badge (Nền xanh nhạt, chữ xanh đậm)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1), // Nền xanh nhạt
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.local_fire_department, color: Colors.orangeAccent, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$streak',
                                        style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor), // Chữ xanh
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                
                                // Coin Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withOpacity(0.1), // Nền vàng nhạt
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.monetization_on, color: Colors.amber, size: 20),
                                      const SizedBox(width: 4),
                                      Text(
                                        '$coins',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    );
                  } else {
                    return const Row(
                      children: [
                        CircleAvatar(radius: 32, backgroundColor: Colors.grey),
                        SizedBox(width: 15),
                        Text("Đang tải...", style: TextStyle(color: Colors.black)),
                      ],
                    );
                  }
                },
              ),
            ),

            const SizedBox(height: 40),
            
            // Tên App (Chữ xanh đậm)
            Center(
              child: Text(
                'Academy of Genius',
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Lobster',
                  color: Color.fromARGB(255, 101, 165, 233), // 3. ĐỔI MÀU LOGO THÀNH XANH
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 50),

            // --- CÁC NÚT CHỨC NĂNG ---
            
            // Nút Luyện Tập: Nền Cam, Chữ Trắng
            _buildBigButton(
              context, 
              'LUYỆN TẬP NGAY', 
              Icons.play_circle_fill, 
              Color.fromARGB(255, 101, 165, 233), // Màu Nền
              Colors.white,  // Màu Chữ
              () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => GameSelection(user: widget.user)));
              }
            ),
            const SizedBox(height: 20),

            _buildBigButton(
              context, 
              'CHẾ ĐỘ 2 NGƯỜI', 
              Icons.people_alt, // Icon 2 người
              Color.fromARGB(255, 101, 165, 233),    // Màu cam cho nổi bật
              Colors.white, 
              () {
                // Chuyển sang màn hình chọn game 2 người
                Navigator.push(context, MaterialPageRoute(builder: (context) => Game2Selection(user: widget.user)));
              }
            ),
            const SizedBox(height: 20),

            // Nút Bảng Xếp Hạng: Nền Xanh, Chữ Trắng
            _buildBigButton(
              context, 
              'BẢNG XẾP HẠNG', 
              Icons.emoji_events, 
              Color.fromARGB(255, 101, 165, 233), // Màu Nền
              Colors.white, // Màu Chữ
              () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => ScoreScreen()));
              }
            ),
          ],
        ),
      ),
    );
  }

  // Widget Button tùy chỉnh màu nền và màu chữ
  Widget _buildBigButton(
    BuildContext context, 
    String title, 
    IconData icon, 
    Color backgroundColor, 
    Color contentColor, 
    VoidCallback onTap
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 30),
      height: 75,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor, // 4. ĐỔI MÀU NỀN NÚT
          foregroundColor: contentColor,    // 5. ĐỔI MÀU CHỮ/ICON
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          padding: EdgeInsets.zero,
        ),
        onPressed: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: contentColor),
            const SizedBox(width: 15),
            Text(
              title, 
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: contentColor
              )
            ),
          ],
        ),
      ),
    );
  }
}