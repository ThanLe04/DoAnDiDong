import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/user_service.dart';
import 'dart:math';
import 'dart:async';

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
    'VÀNG': Colors.yellow.shade700,
    'TÍM': Colors.purple.shade400,
    'ĐEN': Colors.black87,
    'HỒNG': Colors.pink.shade300,
  };

  final UserService _userService = UserService();
  final Random random = Random();

  int score = 0;
  int currentHighScore = 0;
  
  double timeLeft = 8;
  double maxTimePerQuestion = 8;
  Timer? gameTimer;

  String currentWord = "";
  Color currentColor = Colors.black;
  List<Color> answerOptions = [];

  bool isReversedMode = false;
  // Trạng thái hồi sinh
  bool hasRevived = false;

  @override
  void initState() {
    super.initState();
    _fetchCurrentHighScore();
    _startGame();
  }

  @override
  void dispose() {
    gameTimer?.cancel();
    super.dispose();
  }

  void _fetchCurrentHighScore() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('users/${widget.user.uid}/highScores/logicGame')
        .get();
    if (snapshot.exists) {
      setState(() {
        currentHighScore = (snapshot.value as int?) ?? 0;
      });
    }
  }

  void _startGame() {
    setState(() {
      score = 0;
      isReversedMode = false;
      hasRevived = false; // Reset trạng thái hồi sinh
    });
    _nextQuestion();
  }

  void _startTimer() {
    gameTimer?.cancel();
    timeLeft = maxTimePerQuestion;

    gameTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
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

  void _nextQuestion() {
    final List<String> allWords = colorMap.keys.toList();
    final List<Color> allColors = colorMap.values.toList();

    if (score >= 10) {
      maxTimePerQuestion = 5.0;
    } else {
      maxTimePerQuestion = 8.0;
    }

    final String newWord = allWords[random.nextInt(allWords.length)];
    Color newColor = allColors[random.nextInt(allColors.length)];
    while (colorMap[newWord] == newColor) {
      newColor = allColors[random.nextInt(allColors.length)];
    }

    bool newMode = false;
    if (score >= 3) {
      int chance = (score >= 5) ? 50 : 30; 
      newMode = random.nextInt(100) < chance;
    }

    final Color correctAnswer;
    if (newMode) {
      correctAnswer = colorMap[newWord]!;
    } else {
      correctAnswer = newColor;
    }

    List<Color> options = [correctAnswer];
    List<Color> otherColors = allColors.where((c) => c != correctAnswer).toList();
    otherColors.shuffle();
    options.addAll(otherColors.take(3));
    options.shuffle();

    setState(() {
      currentWord = newWord;
      currentColor = newColor;
      answerOptions = options;
      isReversedMode = newMode;
    });

    _startTimer();
  }

  void _onAnswerPressed(Color selectedColor) {
    final Color correctAnswer;
    if (isReversedMode) {
      correctAnswer = colorMap[currentWord]!;
    } else {
      correctAnswer = currentColor;
    }

    if (selectedColor == correctAnswer) {
      HapticFeedback.lightImpact();
      setState(() {
        score++;
      });
      _nextQuestion();
    } else {
      gameTimer?.cancel();
      HapticFeedback.heavyImpact();
      // Sai -> Kiểm tra hồi sinh
      _checkReviveOption();
    }
  }

  // --- LOGIC HỒI SINH ---
  void _checkReviveOption() async {
    if (hasRevived) {
      _showGameOverDialog();
      return;
    }

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
      timeLeft = maxTimePerQuestion; // Reset thời gian
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã hồi sinh! Cố lên! ❤️"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      )
    );
    
    _nextQuestion();
  }
  // ---------------------

  void _showGameOverDialog() {
    _userService.updatePostGameActivity(
      userId: widget.user.uid,
      gameKey: 'logicGame',
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
              timeLeft <= 0 ? 'Hết giờ!' : 'Chọn sai rồi!',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 10),
            Text(
              'Điểm số: $score',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 15),
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
                    'Cao nhất: $displayHighScore', 
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                onPressed: () {
                  Navigator.of(context).pop();
                  if (score > currentHighScore) {
                    setState(() => currentHighScore = score);
                  }
                  _startGame();
                },
                child: const Text('Chơi lại', style: TextStyle(color: Colors.white)),
              ),
            ],
          )
        ],
      ),
    );
  }

  // ... (Phần Widget build giữ nguyên như cũ)
  
  // Widget InfoChip
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String instructionText = isReversedMode
        ? "Chọn Ý NGHĨA của chữ"
        : "Chọn MÀU của chữ";

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Màu sắc hỗn loạn',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(Icons.timer, '${timeLeft.toStringAsFixed(1)}s', timeLeft < 3 ? Colors.red : Colors.blue),
                  _buildInfoChip(Icons.star, '$score', Colors.orange),
                ],
              ),
              
              const SizedBox(height: 15),
              
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: timeLeft / maxTimePerQuestion,
                  minHeight: 8,
                  backgroundColor: Colors.grey.shade300,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    timeLeft < 3 ? Colors.red : Colors.blueAccent
                  ),
                ),
              ),

              const Spacer(),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: Container(
                  key: ValueKey<String>(currentWord + isReversedMode.toString()),
                  padding: const EdgeInsets.all(30),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                    ],
                    border: isReversedMode 
                        ? Border.all(color: Colors.orangeAccent, width: 3) 
                        : null,
                  ),
                  child: Column(
                    children: [
                      Text(
                        isReversedMode ? "CHỌN Ý NGHĨA CỦA CHỮ!" : "CHỌN MÀU SẮC CỦA CHỮ!",
                        style: TextStyle(
                          fontSize: 14, 
                          fontWeight: FontWeight.bold, 
                          color: isReversedMode ? Colors.orange : Colors.grey[600],
                          letterSpacing: 1.5
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        currentWord,
                        style: TextStyle(
                          fontSize: 56,
                          fontWeight: FontWeight.bold,
                          color: currentColor, 
                          fontFamily: 'Roboto',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(),

              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 4,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 2.0, 
                ),
                itemBuilder: (context, index) {
                  if (index >= answerOptions.length) return const SizedBox();
                  
                  return ElevatedButton(
                    onPressed: () => _onAnswerPressed(answerOptions[index]),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: answerOptions[index],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      elevation: 4,
                      shadowColor: answerOptions[index].withOpacity(0.5),
                    ),
                    child: const SizedBox(), 
                  );
                },
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}