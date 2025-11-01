import 'dart:math';
import 'board.dart';

class CaroAI {
  final String aiPlayer;
  final String humanPlayer;
  final String difficulty;

  CaroAI({required this.aiPlayer, required this.humanPlayer, required this.difficulty});

  Point<int>? getMove(Board board) {
    if (difficulty == 'easy') {
      return _getNearOpponentMove(board); // Easy AI gần người chơi
    } else {
      return _getSmartMove(board); // Smart AI
    }
  }

  Point<int>? _getNearOpponentMove(Board board) {
    List<Point<int>> nearMoves = [];
    for (int i = 0; i < Board.size; i++) {
      for (int j = 0; j < Board.size; j++) {
        if (board.cells[i][j] == '') {
          // Kiểm tra vùng xung quanh ô này
          for (int dx = -1; dx <= 1; dx++) {
            for (int dy = -1; dy <= 1; dy++) {
              int ni = i + dx;
              int nj = j + dy;
              if (ni >= 0 && ni < Board.size && nj >= 0 && nj < Board.size) {
                if (board.cells[ni][nj] == humanPlayer) {
                  nearMoves.add(Point(i, j));
                  break;
                }
              }
            }
            if (nearMoves.isNotEmpty && nearMoves.last == Point(i, j)) break;
          }
        }
      }
    }
    if (nearMoves.isNotEmpty) {
      return nearMoves[Random().nextInt(nearMoves.length)];
    } else {
      return _getRandomMove(board); // fallback nếu bàn trống
    }
  }
  Point<int>? _getRandomMove(Board board) {
    final rand = Random();
    List<Point<int>> moves = [];

    for (int i = 0; i < Board.size; i++) {
      for (int j = 0; j < Board.size; j++) {
        if (board.cells[i][j] == '') {
          moves.add(Point(i, j));
        }
      }
    }
    return moves.isNotEmpty ? moves[rand.nextInt(moves.length)] : null;
  }

  bool _hasNeighbor(Board board, int y, int x, [int radius = 2]) {
    for (int dy = -radius; dy <= radius; dy++) {
      for (int dx = -radius; dx <= radius; dx++) {
        int ny = y + dy;
        int nx = x + dx;
        if (ny >= 0 && ny < Board.size && nx >= 0 && nx < Board.size) {
          if (board.cells[ny][nx] != '') {
            return true;
          }
        }
      }
    }
    return false;
  }

  Point<int>? _getSmartMove(Board board) {
    List<Point<int>> candidates = [];
    for (int i = 0; i < Board.size; i++) {
      for (int j = 0; j < Board.size; j++) {
        if (board.cells[i][j] == '' && _hasNeighbor(board, i, j)) {
          candidates.add(Point(i, j));
        }
      }
    }

    int bestScore = -999999;
    Point<int>? bestMove;

    for (var move in candidates) {
      int attackScore = _evaluate(board, move.x, move.y, aiPlayer);
      int defenseScore = _evaluate(board, move.x, move.y, humanPlayer);
      int totalScore = attackScore + 2 * defenseScore;

      if (totalScore > bestScore) {
        bestScore = totalScore;
        bestMove = move;
      }
    }

    return bestMove;
  }

  int _evaluate(Board board, int y, int x, String player) {
    int score = 0;
    List<List<int>> directions = [
      [1, 0],
      [0, 1],
      [1, 1],
      [1, -1]
    ];

    for (var dir in directions) {
      int count = _countLine(board, y, x, dir[0], dir[1], player);
      score += count * count;
    }

    return score;
  }

  int _countLine(Board board, int y, int x, int dy, int dx, String player) {
    int count = 0;
    for (int i = -4; i <= 4; i++) {
      int ny = y + i * dy;
      int nx = x + i * dx;
      if (ny >= 0 && ny < Board.size && nx >= 0 && nx < Board.size) {
        if (board.cells[ny][nx] == player) {
          count++;
        }
      }
    }
    return count;
  }
}
