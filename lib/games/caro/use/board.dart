class Board {
  static const int size = 10;
  static const int winCount = 5;
  List<List<String>> cells;

  Board() : cells = List.generate(size, (_) => List.filled(size, ''));

  bool isFull() {
    for (var row in cells) {
      for (var cell in row) {
        if (cell == '') return false;
      }
    }
    return true;
  }

  bool checkWin(int row, int col, String player) {
    return _checkDirection(row, col, player, 1, 0) || // ngang
           _checkDirection(row, col, player, 0, 1) || // dọc
           _checkDirection(row, col, player, 1, 1) || // chéo xuôi
           _checkDirection(row, col, player, 1, -1);  // chéo ngược
  }

  bool _checkDirection(int row, int col, String player, int dx, int dy) {
    int count = 1;

    for (int i = 1; i < winCount; i++) {
      int r = row + dx * i;
      int c = col + dy * i;
      if (_valid(r, c) && cells[r][c] == player) {
        count++;
      } else break;
    }

    for (int i = 1; i < winCount; i++) {
      int r = row - dx * i;
      int c = col - dy * i;
      if (_valid(r, c) && cells[r][c] == player) {
        count++;
      } else break;
    }

    return count >= winCount;
  }

  bool _valid(int r, int c) => r >= 0 && r < size && c >= 0 && c < size;
  
  String? getWinnerSymbol() {
    for (int i = 0; i < size; i++) {
      for (int j = 0; j < size; j++) {
        String symbol = cells[i][j];
        if (symbol == '') continue;
        if (checkWin(i, j, symbol)) {
          return symbol;
        }
      }
    }
    return null;
  }

}
