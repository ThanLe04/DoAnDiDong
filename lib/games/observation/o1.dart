import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/user_service.dart';
import 'dart:math';
import 'dart:async';

class O1 extends StatefulWidget {
  final User user;
  const O1({super.key, required this.user});

  @override
  State<O1> createState() => _O1State();
}

class _O1State extends State<O1> {
  final List<String> allFruits = ['🍎', '🍌', '🍊', '🍇', '🍓', '🍉', '🍍', '🥝'];
  List<String> currentFruits = [];
  List<String> grid = [];
  String correctAnswer = '';
  
  int score = 0;
  int currentHighScore = 0;

  double timeLeft = 8;
  double maxTimePerQuestion = 8;
  Timer? timer;
  
  final UserService _userService = UserService();

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
    timer?.cancel();
    super.dispose();
  }

  void _fetchCurrentHighScore() async {
    final snapshot = await FirebaseDatabase.instance
        .ref('users/${widget.user.uid}/highScores/observationGame')
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
      hasRevived = false; // Reset trạng thái hồi sinh
    });
    _generateGrid();
  }

  void _generateGrid() {
    int gridSize = 3; 
    int fruitTypesCount = 3; 
    maxTimePerQuestion = 8.0; 

    if (score >= 9) {
      gridSize = 6; fruitTypesCount = 5; maxTimePerQuestion = 8.0;
    } else if (score >= 6) {
      gridSize = 5; fruitTypesCount = 4;
    } else if (score >= 3) {
      gridSize = 4; fruitTypesCount = 4;
    } else {
      gridSize = 3; fruitTypesCount = 3;
    }

    final random = Random();
    currentFruits = List.from(allFruits)..shuffle();
    fruitTypesCount = min(fruitTypesCount, allFruits.length);
    currentFruits = currentFruits.take(fruitTypesCount).toList();

    Map<String, int> fruitCount = {};
    List<String> newGrid = [];
    int totalCells = gridSize * gridSize;

    for (int i = 0; i < totalCells; i++) {
      String fruit = currentFruits[random.nextInt(currentFruits.length)];
      newGrid.add(fruit);
      fruitCount[fruit] = (fruitCount[fruit] ?? 0) + 1;
    }

    var sortedEntries = fruitCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    if (sortedEntries.length > 1 && sortedEntries[0].value == sortedEntries[1].value) {
      int indexToChange = random.nextInt(totalCells);
      while (newGrid[indexToChange] == sortedEntries[0].key) {
        indexToChange = random.nextInt(totalCells);
      }
      newGrid[indexToChange] = sortedEntries[0].key;
    }

    fruitCount.clear();
    for(var f in newGrid) fruitCount[f] = (fruitCount[f] ?? 0) + 1;
    correctAnswer = fruitCount.entries.reduce((a, b) => a.value > b.value ? a : b).key;

    setState(() {
      grid = newGrid;
    });

    _startTimer();
  }

  void _startTimer() {
    timer?.cancel();
    timeLeft = maxTimePerQuestion;
    
    timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
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

  void _onFruitSelected(String fruit) {
    if (fruit == correctAnswer) {
      HapticFeedback.lightImpact();
      setState(() {
        score++;
      });
      _generateGrid();
    } else {
      timer?.cancel();
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
    
    // Tạo màn mới để tiếp tục
    _generateGrid();
  }
  // ---------------------

  void _showGameOverDialog() {
    _userService.updatePostGameActivity(
      userId: widget.user.uid,
      gameKey: 'observationGame',
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
    int gridSize = sqrt(grid.length).toInt();

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
          'Mùa màng bội thu',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            children: [
              // 1. THANH THÔNG TIN
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoChip(Icons.timer, '${timeLeft.toStringAsFixed(1)}s', timeLeft < 3 ? Colors.red : Colors.blue),
                  _buildInfoChip(Icons.star, '$score', Colors.orange),
                ],
              ),
              
              const SizedBox(height: 15),
              
              // Thanh Progress Bar
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

              const SizedBox(height: 20),
              
              const Text(
                'Chọn loại quả xuất hiện nhiều nhất!',
                style: TextStyle(fontSize: 16, color: Colors.grey, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              // 2. LƯỚI TRÁI CÂY (GRID)
              Expanded(
                child: Center(
                  child: AspectRatio(
                    aspectRatio: 1, // Giữ khung hình vuông
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))
                        ],
                      ),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          double fontSize = (constraints.maxWidth / gridSize) * 0.5;
                          
                          return GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: grid.length,
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: gridSize, 
                              crossAxisSpacing: 5,
                              mainAxisSpacing: 5,
                            ),
                            itemBuilder: (context, index) {
                              return Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Center(
                                  child: Text(
                                    grid[index], 
                                    style: TextStyle(fontSize: fontSize)
                                  ),
                                ),
                              );
                            },
                          );
                        }
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // 3. CÁC NÚT CHỌN (OPTIONS)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 15,
                runSpacing: 15,
                children: currentFruits.map((fruit) {
                  return ElevatedButton(
                    onPressed: () => _onFruitSelected(fruit),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                    child: Text(fruit, style: const TextStyle(fontSize: 32)),
                  );
                }).toList(),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

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
}