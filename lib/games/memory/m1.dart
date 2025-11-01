import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart'; // Import UserService
import 'dart:math';

class M1 extends StatefulWidget {
  final User user;
  const M1({super.key, required this.user});

  @override
  State<M1> createState() => _M1State();
}

class _M1State extends State<M1> {
  final List<Color> colors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.orange,
    Colors.purple,
  ];

  final UserService _userService = UserService();

  List<Color> sequence = [];
  List<Color> userInput = [];
  bool isDisplaying = false;
  Color? currentColor;
  int score = 0;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    setState(() {
      sequence.clear();
      userInput.clear();
      score = 0;
      _generateNewSequence();
    });
  }

  void _generateNewSequence() {
    setState(() {
      // Tăng độ dài chuỗi theo số điểm
      int nextLength = score + 1;

      // Tạo chuỗi mới với màu random
      sequence = List.generate(nextLength, (_) => colors[Random().nextInt(colors.length)]);

      userInput.clear();
      isDisplaying = true;
      _displaySequence();
    });
  }

  Future<void> _displaySequence() async {
    for (var color in sequence) {
      setState(() {
        currentColor = color;
      });
      await Future.delayed(const Duration(milliseconds: 1500));
      setState(() {
        currentColor = Colors.white;
      });
      await Future.delayed(const Duration(milliseconds: 500));
    }
    setState(() {
      isDisplaying = false;
    });
  }

  void _onColorPressed(Color color) {
    if (isDisplaying) return;
    setState(() {
      userInput.add(color);
    });
    if (userInput.length == sequence.length) {
      if (_checkSequence()) {
        setState(() {
          score++;
        });
        _generateNewSequence();
      } else {
        _showGameOverDialog();
      }
    }
  }

  bool _checkSequence() {
    for (int i = 0; i < sequence.length; i++) {
      if (sequence[i] != userInput[i]) {
        return false;
      }
    }
    return true;
  }

  void _showGameOverDialog() {
    _userService.updateGameScoreIfHigher(widget.user.uid, 'memoryGame', score);
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho tắt dialog khi nhấn ra ngoài
      builder: (context) => PopScope(
        canPop: false, // Ngăn không cho đóng bằng nút Back
        child: AlertDialog(
          title: const Text('Game Over!'),
          content: Text('Bạn đã đạt được $score điểm. Chơi lại?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
                _startGame(); // Gọi lại hộp thoại khởi động trò chơi
              },
              child: const Text('Chơi lại'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Đóng dialog
                Navigator.of(context).pop(); // Quay lại màn hình trước
              },
              child: const Text('Thoát'),
            ),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sắc màu hồi tưởng',
          style: TextStyle(fontSize: 48),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: currentColor ?? Colors.white,
                border: Border.all(color: Colors.black, width: 2),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 30),
            if (!isDisplaying)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: colors.map((color) {
                  return ElevatedButton(
                    onPressed: () => _onColorPressed(color),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      minimumSize: const Size(80, 80),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    child: const SizedBox(),
                  );
                }).toList(),
              ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.black, width: 2),
              ),
              child: Text(
                'Điểm: $score',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
