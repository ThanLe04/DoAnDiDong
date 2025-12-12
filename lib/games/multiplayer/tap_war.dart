import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // HapticFeedback

class TapWar extends StatefulWidget {
  const TapWar({super.key});

  @override
  State<TapWar> createState() => _TapWarState();
}

class _TapWarState extends State<TapWar> {
  // Trạng thái game
  bool isGameRunning = false;
  
  // Vị trí của thanh chắn (0.0 là giữa, -1.0 là đỉnh, 1.0 là đáy)
  // P1 (Xanh - Dưới) muốn đẩy lên (-1.0)
  // P2 (Đỏ - Trên) muốn đẩy xuống (1.0)
  double battlePosition = 0.0;
  
  // Độ khó: Mỗi lần tap đẩy được bao nhiêu % (0.05 = 5%)
  final double pushStrength = 0.05;

  void _startGame() {
    setState(() {
      battlePosition = 0.0;
      isGameRunning = true;
    });
  }

  void _handleTap(int playerIndex) {
    if (!isGameRunning) return;

    setState(() {
      if (playerIndex == 1) {
        // Player 1 (Xanh - Dưới) bấm -> Đẩy lên (giảm giá trị)
        battlePosition -= pushStrength;
      } else {
        // Player 2 (Đỏ - Trên) bấm -> Đẩy xuống (tăng giá trị)
        battlePosition += pushStrength;
      }
    });

    // Rung nhẹ tạo cảm giác lực
    HapticFeedback.lightImpact();

    _checkWinCondition();
  }

  void _checkWinCondition() {
    // P1 thắng nếu đẩy thanh chạm đỉnh (-1.0) (Lưu ý: có thể dùng ngưỡng nhỏ hơn chút như -0.95)
    if (battlePosition <= -0.95) {
      _endGame("Người chơi 1 (Xanh)");
    } 
    // P2 thắng nếu đẩy thanh chạm đáy (1.0)
    else if (battlePosition >= 0.95) {
      _endGame("Người chơi 2 (Đỏ)");
    }
  }

  void _endGame(String winner) {
    setState(() => isGameRunning = false);
    HapticFeedback.heavyImpact();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("🏆 CHIẾN THẮNG!"),
        content: Text("$winner có ngón tay mạnh nhất!", style: const TextStyle(fontSize: 18)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context); // Thoát
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
      body: Stack(
        children: [
          // --- 2 VÙNG BẤM (TAP ZONES) ---
          Column(
            children: [
              // Player 2 Zone (Đỏ - Trên)
              Expanded(
                child: Material(
                  color: Colors.redAccent,
                  child: InkWell(
                    onTap: () => _handleTap(2),
                    splashColor: Colors.white24,
                    child: const Center(
                      child: RotatedBox(
                        quarterTurns: 2,
                        child: Text(
                          "TAP!", 
                          style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white24)
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              
              // Player 1 Zone (Xanh - Dưới)
              Expanded(
                child: Material(
                  color: Colors.blueAccent,
                  child: InkWell(
                    onTap: () => _handleTap(1),
                    splashColor: Colors.white24,
                    child: const Center(
                      child: Text(
                        "TAP!", 
                        style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white24)
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // --- THANH CHẮN Ở GIỮA (MOVING BAR) ---
          AnimatedAlign(
            alignment: Alignment(0, battlePosition), // Di chuyển theo trục Y
            duration: const Duration(milliseconds: 100), // Hiệu ứng trượt mượt
            curve: Curves.easeOut,
            child: Container(
              width: double.infinity,
              height: 60,
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  )
                ],
                // Hình mũi tên hoặc thanh chắn
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (!isGameRunning) 
                    // Nút Start nằm ngay trên thanh chắn
                    TextButton.icon(
                      onPressed: _startGame,
                      icon: const Icon(Icons.play_arrow, color: Colors.black),
                      label: const Text("BẮT ĐẦU", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    )
                  else
                    // Icon chỉ hướng lực đẩy
                    const Icon(Icons.swap_vert, size: 30, color: Colors.black54),
                ],
              ),
            ),
          ),

          // Nút thoát nhỏ ở góc
          if (!isGameRunning)
            Positioned(
              top: 40,
              left: 20,
              child: CircleAvatar(
                backgroundColor: Colors.white54,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
        ],
      ),
    );
  }
}