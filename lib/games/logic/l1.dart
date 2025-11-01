import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:async';
import '../../services/user_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class L1 extends StatefulWidget {
  final User user;
  const L1({super.key, required this.user});

  @override
  State<L1> createState() => _L1State();
}

class _L1State extends State<L1> {
  final UserService _userService = UserService();

  List<List<int>> solution = List.generate(9, (_) => List.filled(9, 0));
  List<List<int?>> puzzle = List.generate(9, (_) => List.filled(9, null));
  List<List<bool>> editable = List.generate(9, (_) => List.filled(9, false));

  int selectedRow = -1;
  int selectedCol = -1;
  int lives = 3;
  int elapsedSeconds = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _generateSudoku();
    _startTimer();
  }

  void _startTimer() {
    elapsedSeconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        elapsedSeconds++;
      });
    });
  }

  void _generateSudoku() {
    _fillDiagonalBoxes();
    _fillRemaining(0, 3);
    _copySolution();
    _removeCells(30);
  }

  void _fillDiagonalBoxes() {
    for (int i = 0; i < 9; i += 3) {
      _fillBox(i, i);
    }
  }

  void _fillBox(int row, int col) {
    List<int> nums = List.generate(9, (i) => i + 1);
    nums.shuffle();
    int idx = 0;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        solution[row + i][col + j] = nums[idx++];
      }
    }
  }

  bool _isSafe(int row, int col, int num) {
    for (int i = 0; i < 9; i++) {
      if (solution[row][i] == num || solution[i][col] == num) return false;
    }
    int startRow = row - row % 3;
    int startCol = col - col % 3;
    for (int i = 0; i < 3; i++) {
      for (int j = 0; j < 3; j++) {
        if (solution[startRow + i][startCol + j] == num) return false;
      }
    }
    return true;
  }

  bool _fillRemaining(int row, int col) {
    if (col >= 9 && row < 8) {
      row++;
      col = 0;
    }
    if (row >= 9 && col >= 9) return true;
    if (row < 3 && col < 3) col = 3;
    else if (row < 6 && col == (row ~/ 3) * 3) col += 3;
    else if (row >= 6 && col == 6) {
      row++;
      col = 0;
      if (row >= 9) return true;
    }

    for (int num = 1; num <= 9; num++) {
      if (_isSafe(row, col, num)) {
        solution[row][col] = num;
        if (_fillRemaining(row, col + 1)) return true;
        solution[row][col] = 0;
      }
    }
    return false;
  }

  void _copySolution() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        puzzle[i][j] = solution[i][j];
        editable[i][j] = false;
      }
    }
  }

  void _removeCells(int count) {
    final rand = Random();
    int removed = 0;
    while (removed < count) {
      int row = rand.nextInt(9);
      int col = rand.nextInt(9);
      if (puzzle[row][col] != null) {
        puzzle[row][col] = null;
        editable[row][col] = true;
        removed++;
      }
    }
  }

  void _onCellTap(int row, int col) {
    if (editable[row][col]) {
      setState(() {
        selectedRow = row;
        selectedCol = col;
      });
    }
  }

  void _onNumberInput(int num) {
    if (selectedRow != -1 && selectedCol != -1) {
      if (solution[selectedRow][selectedCol] == num) {
        setState(() {
          puzzle[selectedRow][selectedCol] = num;
          selectedRow = -1;
          selectedCol = -1;
        });
        if (_checkWin()) {
          _timer?.cancel();
          _userService.updateGameScoreIfHigher(widget.user.uid, 'logicGame', elapsedSeconds);
          _showVictoryDialog();
        }
      } else {
        setState(() {
          lives--;
        });
        if (lives == 0) {
          _timer?.cancel();
          _showGameOverDialog();
        }
      }
    }
  }

  bool _checkWin() {
    for (int i = 0; i < 9; i++) {
      for (int j = 0; j < 9; j++) {
        if (puzzle[i][j] != solution[i][j]) return false;
      }
    }
    return true;
  }

  void _showVictoryDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('🎉 Chiến thắng!'),
        content: Text('Bạn đã hoàn thành với thời gian: $elapsedSeconds giây'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restartGame();
            },
            child: const Text('Chơi lại'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }

  void _showGameOverDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('💀 Game Over'),
        content: const Text('Bạn đã hết 3 lượt sai!'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _restartGame();
            },
            child: const Text('Chơi lại'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Thoát'),
          ),
        ],
      ),
    );
  }
  void _restartGame() {
    setState(() {
      solution = List.generate(9, (_) => List.filled(9, 0));
      puzzle = List.generate(9, (_) => List.filled(9, null));
      editable = List.generate(9, (_) => List.filled(9, false));
      selectedRow = -1;
      selectedCol = -1;
      lives = 3;
      _generateSudoku();
      _timer?.cancel();
      _startTimer();
    });
  }



  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildGrid() {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(9, (i) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(9, (j) {
            return GestureDetector(
              onTap: () => _onCellTap(i, j),
              child: Container(
                width: 36,
                height: 36,
                margin: const EdgeInsets.all(1),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  color: selectedRow == i && selectedCol == j
                      ? Colors.blue.shade100
                      : Colors.white,
                ),
                child: Text(
                  puzzle[i][j]?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 18,
                    color: editable[i][j] ? Colors.blue : Colors.black,
                  ),
                ),
              ),
            );
          }),
        );
      }),
    ),
  );
}


  Widget _buildNumberPad() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: AspectRatio(
        aspectRatio: 1, // Tạo khối vuông
        child: GridView.builder(
          itemCount: 9,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                backgroundColor: Colors.blue[100],
              ),
              onPressed: () => _onNumberInput(index + 1),
              child: Center(
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }




  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sudoku')),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text('⏱️ Thời gian: $elapsedSeconds giây', style: const TextStyle(fontSize: 18)),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) {
                return Icon(
                  index < lives ? Icons.favorite : Icons.favorite_border,
                  color: Colors.red,
                );
              }),
            ),
            const SizedBox(height: 10),
            _buildGrid(),
            const SizedBox(height: 10),
            _buildNumberPad(),
          ],
        ),
      ),
    );
  }
}
