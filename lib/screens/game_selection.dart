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
      appBar: AppBar(title: const Text('Chọn Trò Chơi')),
      body: ListView(
        children: [
          _buildGameCategory(context, 'Quan sát', [
            _buildGameItem(context, 'Mùa màng bội thu',  O1(user: user)),
            _buildGameItem(context, 'Game 2',  M1(user: user)),
          ]),
          _buildGameCategory(context, 'Trí nhớ', [
            _buildGameItem(context, 'Sắc màu hồi tưởng',  M1(user: user)),
            _buildGameItem(context, 'Game 2',  M1(user: user)),
          ]),
          _buildGameCategory(context, 'Logic', [
            _buildGameItem(context, 'Màu sắc hỗn loạn',  L1(user: user)),
            _buildGameItem(context, 'Game 2',  M1(user: user)),
          ]),
          _buildGameCategory(context, 'Tính toán', [
            _buildGameItem(context, 'Thần đồng tính toán',  C1(user: user)),
            _buildGameItem(context, 'Game 2',  M1(user: user)),
          ]),
        ],
      ),
    );
  }

  Widget _buildGameCategory(BuildContext context, String category, List<Widget> games) {
  return Align(
    alignment: Alignment.center, // Căn giữa theo chiều ngang
    child: Container(
      width: MediaQuery.of(context).size.width * 0.8, // Chiếm 80% chiều rộng màn hình
      margin: const EdgeInsets.symmetric(vertical: 8), // Khoảng cách giữa các thể loại
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 182, 208, 232), // Nền trắng
        borderRadius: BorderRadius.circular(12), // Bo góc 12px
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 119, 173, 223), // Đổ bóng nhẹ
            blurRadius: 5,
            offset: const Offset(0, 3), 
          ),
        ],
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        title: Text(
          category, // Tiêu đề thể loại (Ví dụ: "Quan sát", "Trí nhớ")
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        children: games, // Các trò chơi thuộc thể loại này
      ),
    ),
  );
}

  Widget _buildGameItem(BuildContext context, String title, Widget gameScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, // Màu nền trắng
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(title, style: const TextStyle(fontSize: 16)),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => gameScreen),
          );
        },
      ),
    );
  }
}
