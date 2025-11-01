import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../use/board.dart';
import '../use/ai.dart';

class GameAIScreen extends StatefulWidget {
  final String difficulty;

  const GameAIScreen({super.key, required this.difficulty});

  @override
  State<GameAIScreen> createState() => _GameAIScreenState();
}

class _GameAIScreenState extends State<GameAIScreen> {
  late Board board;
  late CaroAI ai;
  String currentPlayer = 'X'; // X là người
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    board = Board();
    ai = CaroAI(aiPlayer: 'O', humanPlayer: 'X', difficulty: widget.difficulty);
  }

  void _showGameOverDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Không cho phép tắt dialog bằng cách nhấn ra ngoài
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Vô hiệu hóa nút back của thiết bị
        child: AlertDialog(
          title: const Text('Kết thúc trận đấu'),
          content: Text(message, style: const TextStyle(fontSize: 18)),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // đóng dialog
                resetGame();
              },
              child: const Text('Chơi lại'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // đóng dialog
                Navigator.of(context).pop(); // quay về màn trước
              },
              child: const Text('Thoát'),
            ),
          ],
        ),
      ),
    );
  }

  void handleTap(int row, int col) {
    if (board.cells[row][col] != '' || gameOver || currentPlayer != 'X') return;

    setState(() {
      board.cells[row][col] = 'X';

      if (board.checkWin(row, col, 'X')) {
        gameOver = true;
        _showGameOverDialog('Bạn thắng!');
        return;
      }
      if (board.isFull()) {
        gameOver = true;
        _showGameOverDialog('Trận đấu hòa!');
        return;
      }
      currentPlayer = 'O';
    });

    // Máy đánh sau 300ms
    Future.delayed(const Duration(milliseconds: 300), () {
      if (gameOver) return;

      Point<int>? move = ai.getMove(board);
      if (move != null) {
        setState(() {
          board.cells[move.x][move.y] = 'O';
          if (board.checkWin(move.x, move.y, 'O')) {
            gameOver = true;
            _showGameOverDialog('Máy thắng!');
          } else if (board.isFull()) {
            gameOver = true;
            _showGameOverDialog('Trận đấu hòa!');
          } else {
            currentPlayer = 'X';
          }
        });
      }
    });
  }

  void resetGame() {
    setState(() {
      board = Board();
      currentPlayer = 'X';
      gameOver = false;
    });
  }

  Widget buildCell(int row, int col) {
    return GestureDetector(
      onTap: () => handleTap(row, col),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.black12),
        ),
        child: Center(
          child: Text(
            board.cells[row][col],
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: board.cells[row][col] == 'X' ? Colors.blue : Colors.red,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double cellSize = MediaQuery.of(context).size.width / Board.size;

    return Scaffold(
      appBar: AppBar(
        title: Text('Chơi với Máy (${widget.difficulty == 'easy' ? 'Dễ' : 'Khó'})'),
        actions: [
          IconButton(onPressed: resetGame, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              itemCount: Board.size * Board.size,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: Board.size,
              ),
              itemBuilder: (context, index) {
                int row = index ~/ Board.size;
                int col = index % Board.size;
                return SizedBox(
                  width: cellSize,
                  height: cellSize,
                  child: buildCell(row, col),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
