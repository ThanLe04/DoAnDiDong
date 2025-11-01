import 'package:flutter/material.dart';
import '../use/board.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Board board;
  String currentPlayer = 'X';
  bool gameOver = false;

  @override
  void initState() {
    super.initState();
    board = Board();
  }

  void _showGameOverDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false, // Không thể tắt dialog ngoài vùng dialog
      builder: (context) => WillPopScope(
        onWillPop: () async => false, // Disable nút back trên điện thoại
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
                Navigator.of(context).pop(); // trở về màn hình trước
              },
              child: const Text('Thoát'),
            ),
          ],
        ),
      ),
    );
  }

  void handleTap(int row, int col) {
    if (board.cells[row][col] != '' || gameOver) return;

    setState(() {
      board.cells[row][col] = currentPlayer;

      if (board.checkWin(row, col, currentPlayer)) {
        gameOver = true;
        // Hiện dialog thông báo người thắng
        _showGameOverDialog('Người thắng: $currentPlayer');
      } else if (board.isFull()) {
        gameOver = true;
        // Hòa
        _showGameOverDialog('Trận đấu hòa!');
      } else {
        currentPlayer = currentPlayer == 'X' ? 'O' : 'X';
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
        title: const Text('Đánh 2 Người'),
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
