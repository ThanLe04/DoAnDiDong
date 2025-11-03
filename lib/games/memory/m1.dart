import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart';
import 'dart:math';

class M1 extends StatefulWidget {
  final User user;
  const M1({super.key, required this.user});

  @override
  State<M1> createState() => _M1State();
}

class _M1State extends State<M1> {
  final List<Color> colors = [
    Colors.red.shade400,
    Colors.green.shade400,
    Colors.blue.shade400,
    Colors.yellow.shade600,
    Colors.orange.shade400,
    Colors.purple.shade400,
  ];

  final UserService _userService = UserService();

  List<Color> sequence = [];
  List<Color> userInput = [];
  bool isDisplaying = false;
  Color? currentColor;
  int score = 0;

  // Màu "tắt" (mặc định) cho giao diện sáng
  final Color offColor = Colors.grey.shade200;

  @override
  void initState() {
    super.initState();
    // Đặt màu ban đầu là màu "tắt"
    currentColor = offColor; 
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
      int nextLength = score + 1;
      sequence = List.generate(
          nextLength, (_) => colors[Random().nextInt(colors.length)]);
      userInput.clear();
      isDisplaying = true;
      _displaySequence();
    });
  }

  Future<void> _displaySequence() async {
    await Future.delayed(const Duration(milliseconds: 1000));

    for (var color in sequence) {
      setState(() {
        currentColor = color;
      });
      await Future.delayed(const Duration(milliseconds: 1000));
      setState(() {
        // Sửa lỗi: Quay về màu "tắt"
        currentColor = offColor; 
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
        Future.delayed(const Duration(milliseconds: 500), () {
          _generateNewSequence();
        });
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
    _userService.updatePostGameActivity(
      userId: widget.user.uid,
      gameKey: 'memoryGame',
      newScore: score,
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          // Bỏ màu nền tối, dùng màu trắng mặc định
          // backgroundColor: Colors.grey[800],
          // Bỏ style chữ trắng
          // titleTextStyle: const TextStyle(color: Colors.white, fontSize: 24),
          // contentTextStyle: const TextStyle(color: Colors.white, fontSize: 16),
          title: const Text('Game Over!'),
          content: Text('Bạn đã đạt được $score điểm. Chơi lại?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startGame();
              },
              // Dùng màu mặc định (hoặc Colors.blue)
              child: const Text('Chơi lại'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              // Dùng màu đỏ cho dễ thấy
              child: const Text('Thoát', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Đặt nền sáng (ví dụ: xám rất nhạt)
      backgroundColor: Color(0xFF578FCA), 
      appBar: AppBar(
        // Đặt nền AppBar màu trắng
        backgroundColor: Colors.white, 
        // Đặt màu icon/chữ trên AppBar là màu đen
        foregroundColor: Colors.black, 
        // Thêm một chút bóng mờ để phân tách AppBar
        elevation: 1.0, 
        title: Text(
          'Sắc màu hồi tưởng',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                // Chữ màu đen
                color: Colors.black, 
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: currentColor,
                borderRadius: BorderRadius.circular(20),
                // Thêm viền (border) để khối màu nổi bật trên nền sáng
                border: Border.all(color: Colors.grey.shade300, width: 2),
                boxShadow: [
                  // Sửa lỗi: Thêm màu cho boxShadow
                  BoxShadow(
                    color: (currentColor ?? offColor).withOpacity(0.3),
                    blurRadius: 25,
                    spreadRadius: 5,
                  )
                ],
              ),
            ),
            const SizedBox(height: 50),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Wrap(
                spacing: 15,
                runSpacing: 15,
                alignment: WrapAlignment.center,
                children: colors.map((color) {
                  return ElevatedButton(
                    onPressed: isDisplaying ? null : () => _onColorPressed(color),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      disabledBackgroundColor: color.withOpacity(0.3),
                      minimumSize: const Size(90, 90),
                      shape: const CircleBorder(),
                      elevation: 8,
                    ),
                    child: const SizedBox(),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                // Nền trắng cho hộp điểm
                color: Colors.white, 
                borderRadius: BorderRadius.circular(30),
                // Thêm bóng mờ nhẹ
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  )
                ]
              ),
              child: Text(
                'Điểm: $score',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  // Chữ màu đen
                  color: Colors.black, 
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}