import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/user_service.dart'; // Import UserService
import 'dart:math';
import 'dart:async';

class O1 extends StatefulWidget {
  final User user;
  const O1({super.key, required this.user});

  @override
  State<O1> createState() => _O1State();
}

class _O1State extends State<O1> {
  final List<String> fruits = ['🍎', '🍌', '🍊', '🍇'];
  List<String> grid = [];
  String correctAnswer = '';
  int score = 0;
  int timeLeft = 5;
  Timer? timer;
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _generateGrid();
    _startTimer();
  }

  void _generateGrid() {
    Map<String, int> fruitCount = {};
    List<String> newGrid = [];
    for (int i = 0; i < 25; i++) {
      String fruit = fruits[Random().nextInt(fruits.length)];
      newGrid.add(fruit);
      fruitCount[fruit] = (fruitCount[fruit] ?? 0) + 1;
    }
    correctAnswer = fruitCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;
    setState(() {
      grid = newGrid;
    });
  }

  void _startTimer() {
    timeLeft = 5;
    timer?.cancel();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (timeLeft > 0) {
        setState(() {
          timeLeft--;
        });
      } else {
        timer.cancel();
        _showGameOverDialog();
      }
    });
  }

  void _onFruitSelected(String fruit) {
    if (fruit == correctAnswer) {
      setState(() {
        score++;
      });
      _startGame();
    } else {
      _showGameOverDialog();
    }
  }

  void _showGameOverDialog() {
    _userService.updatePostGameActivity(
      userId: widget.user.uid,
      gameKey: 'observationGame',
      newScore: score,
    );
  showDialog(
    context: context,
    barrierDismissible: false, // Không cho phép tắt dialog bằng cách nhấn ra ngoài
    builder: (context) => PopScope(
      canPop: false, // Vô hiệu hoá nút Back
      child: AlertDialog(
        title: const Text('Game Over!'),
        content: Text('Điểm: $score. Chơi lại?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                score = 0;
              });
              _startGame();
            },
            child: const Text('Chơi lại'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Đóng dialog game over
              Navigator.of(context).pop(); // Quay lại màn hình trước (home hoặc main menu)
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
        title: const Text('Mùa màng bội thu', style: TextStyle(fontSize: 48)),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('Chọn loại trái cây nhiều nhất!', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text('Thời gian: $timeLeft giây', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            SizedBox(
              width: 300,
              height: 300,
              child: GridView.builder(
                shrinkWrap: true,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 5,
                  mainAxisSpacing: 5,
                  childAspectRatio: 1,
                ),
                itemCount: grid.length,
                itemBuilder: (context, index) {
                  return Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.black),
                    ),
                    child: Text(grid[index], style: const TextStyle(fontSize: 32)),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
            Text('Điểm: $score', style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 20),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              children: fruits.map((fruit) {
                return ElevatedButton(
                  onPressed: () => _onFruitSelected(fruit),
                  child: Text(fruit, style: const TextStyle(fontSize: 32)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }
}
