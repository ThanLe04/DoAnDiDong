import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../games/memory/m1.dart';
import '../games/observation/o1.dart';
import '../games/calculation/c1.dart';
import '../games/logic/l1.dart';

class GameSelection extends StatelessWidget {
  final User user;
  const GameSelection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám nhạt hiện đại
      appBar: AppBar(
        title: const Text(
          'Thư Viện Trò Chơi',
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
          // --- 1. QUAN SÁT (Màu Tím) ---
          _buildCategorySection(
            context, // <--- SỬA LỖI: Truyền context ở vị trí đầu tiên
            title: 'Quan sát',
            color: Colors.purpleAccent,
            icon: Icons.visibility,
            games: [
              _buildGameCard(
                context,
                title: 'Mùa màng bội thu',
                subtitle: 'Quan sát loại trái cây nhiều nhất',
                icon: Icons.nature_people,
                color: Colors.purpleAccent,
                destination: O1(user: user), // (Lưu ý: Bạn đang dùng tạm M1)
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- 2. TRÍ NHỚ (Màu Cam) ---
          _buildCategorySection(
            context,
            title: 'Trí nhớ',
            color: Colors.orange,
            icon: Icons.psychology,
            games: [
              _buildGameCard(
                context,
                title: 'Sắc màu hồi tưởng',
                subtitle: 'Ghi nhớ chuỗi màu sắc',
                icon: Icons.palette,
                color: Colors.orange,
                destination: M1(user: user),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- 3. LOGIC (Màu Xanh Dương) ---
          _buildCategorySection(
            context,
            title: 'Logic',
            color: Colors.blueAccent,
            icon: Icons.lightbulb,
            games: [
              _buildGameCard(
                context,
                title: 'Màu sắc hỗn loạn',
                subtitle: 'Chọn màu sắc theo yêu cầu',
                icon: Icons.shuffle,
                color: Colors.blueAccent,
                destination: L1(user: user),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- 4. TÍNH TOÁN (Màu Xanh Lá) ---
          _buildCategorySection(
            context,
            title: 'Tính toán',
            color: Colors.green,
            icon: Icons.calculate,
            games: [
              _buildGameCard(
                context,
                title: 'Thần đồng tính toán',
                subtitle: 'Tính toán thật nhanh và chính xác',
                icon: Icons.timer,
                color: Colors.green,
                destination: C1(user: user),
              ),
            ],
          ),
          
          const SizedBox(height: 40), // Khoảng trống dưới cùng
        ],
      ),
    );
  }

  // --- SỬA LỖI Ở PHẦN ĐỊNH NGHĨA HÀM ---
  // Chuyển BuildContext ra ngoài dấu {} để làm tham số bắt buộc đầu tiên

  Widget _buildCategorySection(
    BuildContext context, { // <--- Context nằm ở đây
    required String title,
    required Color color,
    required IconData icon,
    required List<Widget> games,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header của danh mục
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
        // Danh sách các game bên trong
        ...games,
      ],
    );
  }

  // Widget xây dựng Thẻ Game (Card)
  Widget _buildGameCard(
    BuildContext context, { // <--- Context nằm ở đây
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Widget destination,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 2,
            blurRadius: 10,
            offset: const Offset(0, 4), // Bóng đổ nhẹ xuống dưới
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => destination),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                // Icon game lớn bên trái
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 28),
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
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),

                // Nút Play nhỏ
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "Chơi",
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}