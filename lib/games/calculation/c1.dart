import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../../services/user_service.dart';

class C1 extends StatefulWidget {
  final User user;
  const C1({super.key, required this.user});

  @override
  State<C1> createState() => _C1State();
}

class _C1State extends State<C1> {
  final UserService _userService = UserService();

  int a = 0;
  int b = 0;
  String operator = '+';
  int answer = 0;
  String userAnswer = '';
  int score = 0;

  // Thời gian bắt đầu và giới hạn tối thiểu
  int currentInitialTime = 10;
  final int minInitialTime = 5;

  int timeLeft = 3;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  void _startTimer() {
    _timer?.cancel(); // Huỷ timer cũ nếu có
    timeLeft = currentInitialTime;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        timeLeft--;
        if (timeLeft == 0) {
          timer.cancel();
          _showGameOverDialog();
        }
      });
    });
  }

  void _generateQuestion() {
    final random = Random();
    final operators = ['+', '-', '×', '÷'];
    operator = operators[random.nextInt(operators.length)];

    if (operator == '÷') {
      b = random.nextInt(9) + 1;
      answer = random.nextInt(10) + 1;
      a = b * answer;
    } else if (operator == '-') {
      a = random.nextInt(20) + 1;
      b = random.nextInt(a + 1);
      answer = a - b;
    } else {
      a = random.nextInt(20) + 1;
      b = random.nextInt(20) + 1;

      switch (operator) {
        case '+':
          answer = a + b;
          break;
        case '×':
          answer = a * b;
          break;
      }
    }

    setState(() {
      userAnswer = '';
    });

    _startTimer();
  }

  void _onNumberPressed(String value) {
    setState(() {
      userAnswer += value;
    });
  }

  void _onClear() {
    setState(() {
      userAnswer = '';
    });
  }

  void _onSubmit() {
    if (userAnswer == '') return;
    if (int.tryParse(userAnswer) == answer) {
      _timer?.cancel();
      setState(() {
        score++;

        // Giảm thời gian mỗi khi đạt mốc 3 điểm
        if (score % 3 == 0 && currentInitialTime > minInitialTime) {
          currentInitialTime--;
        }
      });
      _generateQuestion();
    } else {
      _timer?.cancel();
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    _timer?.cancel();
    _userService.updateGameScoreIfHigher(widget.user.uid, 'calculationGame', score);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Hết giờ rồi!'),
          content: Text('Điểm: $score\nBạn muốn chơi lại không?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  score = 0;
                  currentInitialTime = 10; // Reset lại thời gian khi chơi lại
                });
                _generateQuestion();
              },
              child: const Text('Chơi lại'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Thoát'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberButton(String value) {
    return ElevatedButton(
      onPressed: () => _onNumberPressed(value),
      style: ElevatedButton.styleFrom(
        fixedSize: const Size(70, 70),
      ),
      child: Text(value, style: const TextStyle(fontSize: 24)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thần đồng tính toán', style: TextStyle(fontSize: 30)),
        centerTitle: true,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('⏱️ Còn lại: $timeLeft giây', style: const TextStyle(fontSize: 24, color: Colors.red)),
          const SizedBox(height: 10),
          const Text('Giải phép tính sau:', style: TextStyle(fontSize: 24)),
          const SizedBox(height: 10),
          Text('$a $operator $b = ?', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          Text('Đáp án của bạn: $userAnswer', style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: List.generate(10, (i) => _buildNumberButton(i.toString())),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _onClear,
                child: const Text('Xoá', style: TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 20),
              ElevatedButton(
                onPressed: _onSubmit,
                child: const Text('Trả lời', style: TextStyle(fontSize: 20)),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text('Điểm: $score', style: const TextStyle(fontSize: 24)),
        ],
      ),
    );
  }
}
