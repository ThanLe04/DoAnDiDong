import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/user_service.dart';
import 'dart:math';
import 'dart:async';

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
    Colors.yellow.shade700,
    Colors.pink.shade400, // Đã đổi cam -> hồng
    Colors.purple.shade400,
  ];

  final UserService _userService = UserService();

  List<Color> sequence = [];
  List<Color> userInput = [];
  
  bool isGameActive = false;
  bool isDisplaying = false;
  
  Color? currentColor;
  int score = 0;
  int currentHighScore = 0;

  // Trạng thái hồi sinh
  bool hasRevived = false;

  final Color offColor = Colors.white;

  @override
  void initState() {
    super.initState();
    currentColor = offColor; 
    _fetchCurrentHighScore();
  }

  void _fetchCurrentHighScore() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('users/${widget.user.uid}/highScores/memoryGame')
        .get();
    if (snapshot.exists) {
      setState(() {
        currentHighScore = (snapshot.value as int?) ?? 0;
      });
    }
  }

  void _startGame() {
    setState(() {
      isGameActive = true;
      sequence.clear();
      userInput.clear();
      score = 0;
      hasRevived = false; // Reset trạng thái hồi sinh
      _generateNewSequence();
    });
  }

  void _generateNewSequence() {
    setState(() {
      int nextLength = score + 1;
      sequence = List.generate(nextLength, (_) => colors[Random().nextInt(colors.length)]);
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
      int displayTime = score > 5 ? 600 : 800; 
      await Future.delayed(Duration(milliseconds: displayTime));
      
      setState(() {
        currentColor = offColor; 
      });
      await Future.delayed(const Duration(milliseconds: 300));
    }

    setState(() {
      isDisplaying = false;
    });
  }

  void _onColorPressed(Color color) {
    if (isDisplaying || !isGameActive) return;

    HapticFeedback.lightImpact();

    setState(() {
      userInput.add(color);
    });

    int currentIndex = userInput.length - 1;
    if (userInput[currentIndex] != sequence[currentIndex]) {
      HapticFeedback.heavyImpact();
      // Sai -> Kiểm tra hồi sinh
      _checkReviveOption();
    } else {
      if (userInput.length == sequence.length) {
        setState(() {
          score++;
        });
        Future.delayed(const Duration(milliseconds: 1000), () {
          _generateNewSequence();
        });
      }
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
      userInput.clear(); // Xóa các bước nhập sai
      isDisplaying = true; // Chuyển sang trạng thái hiển thị lại
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Đã hồi sinh! Hãy quan sát lại nhé! ❤️"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      )
    );
    
    // Hiển thị lại chuỗi màu hiện tại để người chơi nhớ lại
    _displaySequence();
  }
  // ---------------------

  void _showGameOverDialog() {
    setState(() => isGameActive = false);

    _userService.updatePostGameActivity(
      userId: widget.user.uid,
      gameKey: 'memoryGame',
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
            Text('Sai rồi!', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    'Cao nhất: $displayHighScore', 
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA), // Nền xám nhạt
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Sắc màu hồi tưởng',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- TRẠNG THÁI & ĐIỂM ---
            if (isGameActive)
              Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Text(
                  isDisplaying ? "👀 Hãy quan sát..." : "👉 Đến lượt bạn!",
                  style: TextStyle(
                    fontSize: 18, 
                    fontWeight: FontWeight.bold,
                    color: isDisplaying ? Colors.orange : Colors.green,
                  ),
                ),
              ),

            // --- KHỐI MÀU HIỂN THỊ ---
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                color: currentColor,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade300, width: 4),
                boxShadow: [
                  BoxShadow(
                    color: (currentColor == offColor) 
                        ? Colors.black.withOpacity(0.05) 
                        : currentColor!.withOpacity(0.6),
                    blurRadius: (currentColor == offColor) ? 10 : 30,
                    spreadRadius: (currentColor == offColor) ? 0 : 5,
                  )
                ],
              ),
            ),
            
            const SizedBox(height: 40),

            // --- CÁC NÚT CHỌN MÀU ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 30.0),
              child: Wrap(
                spacing: 20,
                runSpacing: 20,
                alignment: WrapAlignment.center,
                children: colors.map((color) {
                  return SizedBox(
                    width: 80,
                    height: 80,
                    child: ElevatedButton(
                      onPressed: (!isGameActive || isDisplaying) ? null : () => _onColorPressed(color),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color,
                        disabledBackgroundColor: color.withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                        elevation: 5,
                        padding: EdgeInsets.zero,
                      ),
                      child: const SizedBox(),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 40),

            // --- KHU VỰC ĐIỂM SỐ / NÚT BẮT ĐẦU ---
            if (!isGameActive)
              SizedBox(
                width: 200,
                height: 50,
                child: ElevatedButton(
                  onPressed: _startGame,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    elevation: 5,
                  ),
                  child: const Text(
                    "BẮT ĐẦU",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 5))
                  ]
                ),
                child: Text(
                  'Điểm: $score',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}