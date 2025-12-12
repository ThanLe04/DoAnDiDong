import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback

class MathDuel extends StatefulWidget {
  const MathDuel({super.key});

  @override
  State<MathDuel> createState() => _MathDuelState();
}

class _MathDuelState extends State<MathDuel> {
  // Cấu hình
  final int winningScore = 5;
  final Random random = Random();

  // Trạng thái game
  bool isGameRunning = false;
  int scoreP1 = 0; // Player 1 (Xanh - Dưới)
  int scoreP2 = 0; // Player 2 (Đỏ - Trên)
  
  // Dữ liệu câu hỏi hiện tại
  String question = "";
  int answer = 0;
  List<int> options = [];

  @override
  void initState() {
    super.initState();
  }

  void _startGame() {
    setState(() {
      scoreP1 = 0;
      scoreP2 = 0;
      isGameRunning = true;
      _generateQuestion();
    });
  }

  void _generateQuestion() {
    int a = random.nextInt(10) + 1; 
    int b = random.nextInt(10) + 1; 
    String op = ['+', '-', '×'][random.nextInt(3)];

    int result = 0;
    switch (op) {
      case '+': result = a + b; break;
      case '-': 
        if (a < b) { int temp = a; a = b; b = temp; }
        result = a - b; 
        break;
      case '×': result = a * b; break;
    }

    Set<int> optionSet = {result};
    while (optionSet.length < 3) {
      int wrong = result + (random.nextInt(10) - 5);
      if (wrong >= 0 && wrong != result) {
        optionSet.add(wrong);
      }
    }

    List<int> newOptions = optionSet.toList()..shuffle();

    setState(() {
      question = "$a $op $b";
      answer = result;
      options = newOptions;
    });
  }

  void _checkAnswer(int playerIndex, int selectedValue) {
    if (!isGameRunning) return;

    if (selectedValue == answer) {
      // --- ĐÚNG ---
      HapticFeedback.lightImpact();
      setState(() {
        if (playerIndex == 1) {
          scoreP1++; // P1 (Dưới) cộng điểm
        } else {
          scoreP2++; // P2 (Trên) cộng điểm
        }
      });
      _checkWinCondition();
    } else {
      // --- SAI ---
      HapticFeedback.heavyImpact();
      setState(() {
        if (playerIndex == 1) {
          if (scoreP1 > 0) scoreP1--;
        } else {
          if (scoreP2 > 0) scoreP2--;
        }
      });
    }
  }

  void _checkWinCondition() {
    if (scoreP1 >= winningScore) {
      _showWinnerDialog("Người chơi 1 (Xanh)");
    } else if (scoreP2 >= winningScore) {
      _showWinnerDialog("Người chơi 2 (Đỏ)");
    } else {
      _generateQuestion();
    }
  }

  void _showWinnerDialog(String winnerName) {
    setState(() => isGameRunning = false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("🏆 KẾT THÚC!"),
        content: Text("$winnerName đã chiến thắng!", style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); 
              Navigator.pop(context); 
            },
            child: const Text("Thoát"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startGame(); 
            },
            child: const Text("Đấu lại"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // --- PLAYER 2 (MÀU ĐỎ - Ở TRÊN - XOAY NGƯỢC) ---
          Expanded(
            child: RotatedBox(
              quarterTurns: 2, // Xoay 180 độ
              child: _buildPlayerArea(
                playerIndex: 2,
                color: Colors.redAccent, // Màu Đỏ
                score: scoreP2,
              ),
            ),
          ),

          // --- THANH CÔNG CỤ Ở GIỮA ---
          Container(
            height: 50,
            color: Colors.black, // Màu đen làm dải phân cách
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isGameRunning)
                  IconButton(
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    onPressed: _startGame,
                  )
                else
                  TextButton.icon(
                    icon: const Icon(Icons.play_arrow, color: Colors.greenAccent),
                    label: const Text("BẮT ĐẦU", style: TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                    onPressed: _startGame,
                  ),
                
                const SizedBox(width: 20),
                
                IconButton(
                  icon: const Icon(Icons.exit_to_app, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // --- PLAYER 1 (MÀU XANH - Ở DƯỚI - KHÔNG XOAY) ---
          Expanded(
            child: _buildPlayerArea(
              playerIndex: 1,
              color: Colors.blueAccent, // Màu Xanh
              score: scoreP1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayerArea({
    required int playerIndex,
    required Color color,
    required int score,
  }) {
    return Container(
      color: Colors.white, // --- NỀN TRẮNG ---
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Điểm số & Thanh Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Player $playerIndex", style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
              Text("$score / $winningScore", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: score / winningScore,
              minHeight: 10,
              color: color,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          
          const Spacer(),

          // Hiển thị câu hỏi
          if (isGameRunning) ...[
            Text(
              question,
              style: const TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            
            const SizedBox(height: 30),

            // Các nút đáp án
            Row(
              children: options.map((opt) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: ElevatedButton(
                      onPressed: () => _checkAnswer(playerIndex, opt),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: color, // Nút màu (Đỏ hoặc Xanh)
                        foregroundColor: Colors.white, // Chữ trắng
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 5,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        "$opt",
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ] else ...[
            // Màn hình chờ
            const Icon(Icons.videogame_asset, size: 80, color: Colors.grey),
            const Text("Sẵn sàng?", style: TextStyle(fontSize: 24, color: Colors.grey)),
          ],

          const Spacer(),
        ],
      ),
    );
  }
}