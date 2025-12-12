import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  // Logic Game
  int a = 0;
  int b = 0;
  String operator = '+';
  int answer = 0;
  String userAnswer = '';
  int score = 0;
  int currentHighScore = 0;

  // Cấu hình thời gian
  int currentInitialTime = 10;
  final int minInitialTime = 3;
  double timeLeft = 10;
  Timer? _timer;

  // Trạng thái hồi sinh
  bool hasRevived = false;

  final Color primaryColor = const Color(0xFF578FCA);

  @override
  void initState() {
    super.initState();
    _fetchCurrentHighScore();
    _generateQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _fetchCurrentHighScore() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('users/${widget.user.uid}/highScores/calculationGame')
        .get();
    if (snapshot.exists) {
      setState(() {
        currentHighScore = (snapshot.value as int?) ?? 0;
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    timeLeft = currentInitialTime.toDouble();
    
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        timeLeft -= 0.1;
        if (timeLeft <= 0) {
          timeLeft = 0;
          timer.cancel();
          // Hết giờ -> Kiểm tra hồi sinh
          _checkReviveOption();
        }
      });
    });
  }

  void _generateQuestion() {
    final random = Random();
    List<String> operators = ['+', '-', '×', '÷'];
    operator = operators[random.nextInt(operators.length)];

    int maxVal = 50;
    bool allowNegative = false;

    if (score <= 4) {
      maxVal = 50; allowNegative = false;
    } else if (score <= 9) {
      maxVal = 50; allowNegative = true;
    } else if (score <= 14) {
      maxVal = 100; allowNegative = false;
    } else {
      maxVal = 100; allowNegative = true;
    }

    if (operator == '÷') {
      b = random.nextInt(10) + 2;
      int result = random.nextInt(10) + 1;
      a = b * result;
      answer = result;
    } else if (operator == '×') {
      int limit = (maxVal == 50) ? 10 : 12; 
      a = random.nextInt(limit) + 1;
      b = random.nextInt(limit) + 1;
      answer = a * b;
    } else if (operator == '-') {
      a = random.nextInt(maxVal) + 1;
      b = random.nextInt(maxVal) + 1;
      if (!allowNegative && b > a) {
        int temp = a; a = b; b = temp;
      }
      answer = a - b;
    } else {
      a = random.nextInt(maxVal) + 1;
      b = random.nextInt(maxVal) + 1;
      answer = a + b;
    }

    setState(() {
      userAnswer = '';
    });

    _startTimer();
  }

  void _onNumberPressed(String value) {
    HapticFeedback.lightImpact();
    if (value == '-') {
      if (userAnswer.isEmpty) setState(() => userAnswer = '-');
      return;
    }
    if (userAnswer.length < 5) {
      setState(() => userAnswer += value);
    }
  }

  void _onClear() {
    HapticFeedback.mediumImpact();
    setState(() => userAnswer = '');
  }

  void _onBackspace() {
    HapticFeedback.lightImpact();
    if (userAnswer.isNotEmpty) {
      setState(() => userAnswer = userAnswer.substring(0, userAnswer.length - 1));
    }
  }

  void _onSubmit() {
    if (userAnswer == '' || userAnswer == '-') return;
    
    if (int.tryParse(userAnswer) == answer) {
      _timer?.cancel();
      HapticFeedback.heavyImpact();
      
      setState(() {
        score++;
        if (score % 5 == 0 && currentInitialTime > minInitialTime) {
          currentInitialTime--;
        }
      });
      _generateQuestion();
      
    } else {
      _timer?.cancel();
      // Sai -> Kiểm tra hồi sinh
      _checkReviveOption();
    }
  }

  // --- LOGIC HỒI SINH ---
  void _checkReviveOption() async {
    // Nếu đã dùng rồi thì thôi (1 lần/ván)
    if (hasRevived) {
      _showGameOverDialog();
      return;
    }

    // Kiểm tra kho
    int potionCount = await _userService.getItemCount(widget.user.uid, 'revive_potion');

    if (potionCount > 0 && mounted) {
      _showReviveDialog(potionCount);
    } else {
      _showGameOverDialog();
    }
  }

  void _showReviveDialog(int count) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Colors.red),
            SizedBox(width: 10),
            Text("Cơ hội thứ 2!"),
          ],
        ),
        content: Text("Bạn có muốn dùng 1 Hồi sinh để chơi tiếp không?\n(Bạn đang có: $count)"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showGameOverDialog();
            },
            child: const Text("Không, chấp nhận thua"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              // Trừ thuốc
              bool success = await _userService.updateItemCount(widget.user.uid, 'revive_potion', -1);
              if (success && mounted) {
                Navigator.pop(ctx);
                _reviveGame();
              } else {
                Navigator.pop(ctx);
                _showGameOverDialog();
              }
            },
            child: const Text("Dùng Hồi sinh", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _reviveGame() {
    setState(() {
      hasRevived = true;
      timeLeft = currentInitialTime.toDouble(); // Reset thời gian
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã hồi sinh! Cố lên! ❤️"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      )
    );
    
    // Tạo câu hỏi mới để tiếp tục
    _generateQuestion();
  }
  // ---------------------

  void _showGameOverDialog() {
    _userService.updatePostGameActivity(
      userId: widget.user.uid,
      gameKey: 'calculationGame',
      newScore: score,
    );

    int displayHighScore = (score > currentHighScore) ? score : currentHighScore;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Column(
          children: [
            Icon(Icons.sentiment_dissatisfied, size: 50, color: Colors.redAccent),
            SizedBox(height: 10),
            Text('Kết thúc!', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Điểm của bạn: $score',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.amber.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.amber, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Điểm cao nhất: $displayHighScore', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Thoát'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {
                    if (score > currentHighScore) currentHighScore = score;
                    score = 0;
                    currentInitialTime = 10;
                    hasRevived = false; // Reset trạng thái hồi sinh cho ván mới
                  });
                  _generateQuestion();
                },
                child: const Text('Chơi lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ... (Phần Widget build giữ nguyên như cũ, không thay đổi gì về giao diện)
  
  Widget _buildButton(String text, VoidCallback onPressed, {Color? bgColor, Color? textColor}) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: bgColor ?? Colors.white,
            foregroundColor: textColor ?? primaryColor,
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            padding: const EdgeInsets.symmetric(vertical: 18), 
          ),
          child: Text(
            text,
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text('Thần đồng tính toán', 
          style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.orange, size: 20),
                        const SizedBox(width: 5),
                        Text('$score', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.orange)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.timer, color: Colors.red, size: 20),
                        const SizedBox(width: 5),
                        Text('${timeLeft.toStringAsFixed(1)}s', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: timeLeft / currentInitialTime,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    timeLeft < 3 ? Colors.red : primaryColor
                  ),
                ),
              ),
            ),

            const Spacer(),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(20),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                ],
              ),
              child: Column(
                children: [
                  Text(
                    'Giải phép tính:',
                    style: TextStyle(color: Colors.grey[600], fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    child: Text(
                      '$a $operator $b = ?',
                      key: ValueKey<String>('$a$operator$b'),
                      style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: primaryColor),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 30),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4F8),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      userAnswer.isEmpty ? '...' : userAnswer,
                      style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, letterSpacing: 2),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 20, offset: Offset(0, -5))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _buildButton('7', () => _onNumberPressed('7')),
                      _buildButton('8', () => _onNumberPressed('8')),
                      _buildButton('9', () => _onNumberPressed('9')),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('4', () => _onNumberPressed('4')),
                      _buildButton('5', () => _onNumberPressed('5')),
                      _buildButton('6', () => _onNumberPressed('6')),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('1', () => _onNumberPressed('1')),
                      _buildButton('2', () => _onNumberPressed('2')),
                      _buildButton('3', () => _onNumberPressed('3')),
                    ],
                  ),
                  Row(
                    children: [
                      _buildButton('-', () => _onNumberPressed('-'), bgColor: Colors.blue.shade50),
                      _buildButton('0', () => _onNumberPressed('0')),
                      _buildButton('⌫', _onBackspace, bgColor: Colors.orange.shade50, textColor: Colors.orange),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _onSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        elevation: 5,
                      ),
                      child: const Text('TRẢ LỜI NGAY', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}