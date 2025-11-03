import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart'; // Đảm bảo đường dẫn này đúng
import 'dart:math'; // Để dùng Random
import 'dart:async'; // Để dùng Timer

class L1 extends StatefulWidget {
  final User user;
  const L1({super.key, required this.user});

  @override
  State<L1> createState() => _L1State();
}

class _L1State extends State<L1> {
  final Map<String, Color> colorMap = {
    'ĐỎ': Colors.red.shade400,
    'XANH LÁ': Colors.green.shade400,
    'XANH LAM': Colors.blue.shade400,
    'VÀNG': Colors.yellow.shade600,
    'TÍM': Colors.purple.shade400,
    'CAM': Colors.orange.shade400,
    'ĐEN': Colors.black,
    'HỒNG': Colors.pink.shade300,
  };

  final UserService _userService = UserService();
  final Random random = Random(); // Tạo 1 đối tượng Random để tái sử dụng

  // Biến trạng thái của game
  int score = 0;
  int timeLeft = 60;
  Timer? gameTimer;

  String currentWord = "";
  Color currentColor = Colors.black;
  List<Color> answerOptions = [];

  // --- TÍNH NĂNG MỚI: Chế độ Đảo Ngược ---
  bool isReversedMode = false;
  // ------------------------------------

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _startGame() {
    setState(() {
      score = 0;
      timeLeft = 60;
      isReversedMode = false; // Luôn bắt đầu ở chế độ thường
    });
    gameTimer?.cancel();
    _startTimer();
    _nextQuestion();
  }

  void _startTimer() {
    gameTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        _showGameOverDialog();
      }
    });
  }

  void _nextQuestion() {
    final List<String> allWords = colorMap.keys.toList();
    final List<Color> allColors = colorMap.values.toList();

    // 1. Chọn CHỮ
    final String newWord = allWords[random.nextInt(allWords.length)];

    // 2. Chọn MÀU
    Color newColor = allColors[random.nextInt(allColors.length)];
    while (colorMap[newWord] == newColor) {
      newColor = allColors[random.nextInt(allColors.length)];
    }

    // --- LOGIC CẢI TIẾN ---
    // 3. Quyết định chế độ (30% cơ hội đảo ngược)
    final bool newMode = random.nextInt(100) < 30;

    // 4. Xác định đáp án đúng
    final Color correctAnswer;
    if (newMode) {
      // Chế độ Đảo Ngược: Đáp án là Ý NGHĨA CỦA CHỮ
      correctAnswer = colorMap[newWord]!;
    } else {
      // Chế độ Thường: Đáp án là MÀU CỦA CHỮ
      correctAnswer = newColor;
    }
    // -----------------------

    // 5. Tạo các lựa chọn trả lời
    List<Color> options = [correctAnswer];
    
    // Lấy các màu khác (không trùng với đáp án đúng)
    List<Color> otherColors = allColors.where((c) => c != correctAnswer).toList();
    otherColors.shuffle();

    options.addAll(otherColors.take(3));
    options.shuffle();

    // Cập nhật state để UI thay đổi
    setState(() {
      currentWord = newWord;
      currentColor = newColor;
      answerOptions = options;
      isReversedMode = newMode; // Cập nhật chế độ
    });
  }

  void _onAnswerPressed(Color selectedColor) {
    // --- LOGIC CẢI TIẾN ---
    // 1. Xác định đáp án đúng dựa trên chế độ hiện tại
    final Color correctAnswer;
    if (isReversedMode) {
      // Chế độ Đảo Ngược: Đáp án là Ý NGHĨA CỦA CHỮ
      correctAnswer = colorMap[currentWord]!;
    } else {
      // Chế độ Thường: Đáp án là MÀU CỦA CHỮ
      correctAnswer = currentColor;
    }
    // -----------------------

    // 2. So sánh
    if (selectedColor == correctAnswer) {
      // --- ĐÚNG ---
      setState(() {
        score++;
      });
      _nextQuestion();
    } else {
      // --- SAI ---
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    gameTimer?.cancel();
    _userService.updatePostGameActivity(
      userId: widget.user.uid,
      gameKey: 'logicGame', // Key của game L1
      newScore: score,
    );
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          title: const Text('Game Over!'),
          content: Text(timeLeft == 0
              ? 'Hết giờ! Bạn đã đạt $score điểm.'
              : 'Sai rồi! Điểm cuối cùng của bạn là $score.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startGame();
              },
              child: const Text('Chơi lại'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
              },
              child: const Text('Thoát', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- UI CẢI TIẾN ---
    // Xác định văn bản hướng dẫn dựa trên chế độ
    final String instructionText = isReversedMode
        ? "Chọn Ý NGHĨA của chữ"
        : "Chọn MÀU của chữ";
    // -------------------

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1.0,
        title: Text(
          'Màu sắc hỗn loạn',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatBox('Thời gian', '$timeLeft', Colors.orange),
                _buildStatBox('Điểm', '$score', Colors.green),
              ],
            ),
            
            const SizedBox(height: 30),

            Expanded(
              child: Center(
                child: Text(
                  currentWord,
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.bold,
                    color: currentColor,
                    shadows: [
                      Shadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 5,
                        offset: const Offset(2, 2),
                      )
                    ]
                  ),
                ),
              ),
            ),

            // --- UI CẢI TIẾN ---
            // Hiển thị văn bản hướng dẫn đã thay đổi
            Text(
              instructionText,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                // Làm cho nó nổi bật
                color: Colors.black, 
              ),
              textAlign: TextAlign.center,
            ),
            // -------------------
            
            const SizedBox(height: 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 15,
                mainAxisSpacing: 15,
                childAspectRatio: 2.5,
              ),
              itemBuilder: (context, index) {
                if (answerOptions.isEmpty) return Container();
                
                final Color optionColor = answerOptions[index];
                
                return ElevatedButton(
                  onPressed: () => _onAnswerPressed(optionColor),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: optionColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: const SizedBox(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBox(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}