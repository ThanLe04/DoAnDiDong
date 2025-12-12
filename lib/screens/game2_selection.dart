import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../games/multiplayer/math_duel.dart';
import '../games/multiplayer/tap_war.dart';

class Game2Selection extends StatelessWidget {
  final User user;
  const Game2Selection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám nhạt
      appBar: AppBar(
        title: const Text(
          'Chế độ 2 Người',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Banner giới thiệu
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 30),
            decoration: BoxDecoration(
              color: Colors.orange.shade100,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: Colors.orange.shade300),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.orange),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "Thách đấu bạn bè trên cùng một thiết bị! Xem ai thông minh hơn nào.",
                    style: TextStyle(fontSize: 16, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          // --- DANH SÁCH GAME 2 NGƯỜI ---
          
          _buildCategorySection(
            context,
            title: 'Đối kháng',
            color: Colors.redAccent,
            icon: Icons.compare_arrows,
            games: [
              _buildGameCard(
                context,
                title: 'Đấu trường Toán học',
                subtitle: 'Đúng +1 điểm, sai -1 điểm',
                icon: Icons.calculate,
                color: Colors.redAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MathDuel()),
                  );
                },
              ),
              const SizedBox(height: 15), // Khoảng cách

              _buildGameCard(
                context,
                title: 'Đại chiến Ngón tay',
                subtitle: 'Ai bấm nhanh hơn người đó thắng!',
                icon: Icons.touch_app, // Icon ngón tay bấm
                color: Colors.purpleAccent, // Màu tím cho khác biệt
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TapWar()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Widget xây dựng Tiêu đề danh mục
  Widget _buildCategorySection(
    BuildContext context, {
    required String title,
    required Color color,
    required IconData icon,
    required List<Widget> games,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 10),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey.shade800,
                ),
              ),
            ],
          ),
        ),
        ...games,
      ],
    );
  }

  // Widget xây dựng Thẻ Game (Card)
  Widget _buildGameCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon game lớn
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 32),
                ),
                const SizedBox(width: 16),
                
                // Tên và mô tả
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Icon play
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}