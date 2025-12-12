// Import 2 gói cần thiết
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';

class UserService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  /// Hàm này sẽ được gọi KHI KẾT THÚC BẤT KỲ GAME NÀO
  /// Nó sẽ cập nhật điểm và logic chuỗi ngày bằng Transaction
  /// (Thay thế cho hàm updateGameScoreIfHigher cũ)
  Future<void> updatePostGameActivity({
    required String userId,
    required String gameKey, // ví dụ: 'logicGame'
    required int newScore,
  }) async {
    // 1. Lấy ngày hôm nay và hôm qua
    final now = DateTime.now();
    final String today = DateFormat('yyyy-MM-dd').format(now);
    final String yesterday =
        DateFormat('yyyy-MM-dd').format(now.subtract(const Duration(days: 1)));

    // 2. Lấy tham chiếu đến node của user cụ thể
    final userRef = _dbRef.child('users').child(userId);

    // 3. Chạy Transaction để đảm bảo an toàn dữ liệu
    try {
      final TransactionResult transactionResult =
          await userRef.runTransaction((Object? data) {
        
        // `data` là dữ liệu hiện tại ở `userRef`
        if (data == null) {
          // Nếu data = null (user không tồn tại), hủy bỏ
          return Transaction.abort();
        }

        // Ép kiểu dữ liệu về Map
        final Map<String, dynamic> userData =
            Map<String, dynamic>.from(data as Map);

        // --- 4a. Xử lý Logic Điểm Số ---
        // Lấy map highScores ra
        final Map<String, dynamic> highScores =
            Map<String, dynamic>.from(userData['highScores'] ?? {});
        
        // Lấy điểm cao hiện tại của game này
        final int currentHighScore = (highScores[gameKey] ?? 0) as int;
        
        // Nếu điểm mới cao hơn, cập nhật lại
        if (newScore > currentHighScore) {
          highScores[gameKey] = newScore;
        }
        // Gán map highScores mới vào lại data chính
        userData['highScores'] = highScores;

        // Lấy số coin hiện tại
        int currentCoins = (userData['coins'] ?? 0) as int;
        
        // Công thức: 10 điểm = 1 vàng. Dùng .floor() để làm tròn xuống.
        // Ví dụ: 45 điểm -> 4 vàng.
        int earnedCoins = (newScore / 10).floor(); 
        
        // Cộng dồn vào ví
        if (earnedCoins > 0) {
          userData['coins'] = currentCoins + earnedCoins;
        }

        // --- 4b. Xử lý Logic Chuỗi Ngày (Streak) ---
        final int currentStreak = (userData['streak'] ?? 0) as int;
        final String lastPlayedDate = (userData['lastPlayedDate'] ?? "") as String;

        if (lastPlayedDate == today) {
          // Đã chơi hôm nay rồi -> không làm gì cả
        } else if (lastPlayedDate == yesterday) {
          // Chơi liên tiếp (hôm qua có chơi) -> Tăng chuỗi
          userData['streak'] = currentStreak + 1;
          userData['lastPlayedDate'] = today;
        } else {
          // Bỏ lỡ 1 ngày hoặc chơi lần đầu -> Reset chuỗi về 1
          userData['streak'] = 1;
          userData['lastPlayedDate'] = today;
        }

        // 5. Trả về dữ liệu đã được cập nhật
        // Firebase sẽ tự động ghi đè dữ liệu này lên `userRef`
        return Transaction.success(userData);
      });

      if (!transactionResult.committed) {
        // Transaction bị hủy bỏ (ví dụ: data là null)
        print("Lỗi: Transaction đã bị hủy bỏ.");
      } else {
        // Transaction thành công
        print("Đã cập nhật điểm và chuỗi ngày thành công!");
      }
    } catch (e) {
      // Xử lý lỗi nếu transaction thất bại
      print("Transaction thất bại: $e");
    }
  }

  // Bạn vẫn có thể giữ hàm getGameScore nếu cần
  // (Ví dụ: để hiển thị điểm ở đâu đó khác)
  Future<int> getGameScore(String uid, String gameKey) async {
    try {
      final snapshot = await _dbRef
          .child('users')
          .child(uid)
          .child('highScores')
          .child(gameKey)
          .get();
      if (snapshot.exists) {
        return snapshot.value as int;
      }
    } catch (e) {
      print('Lỗi khi lấy điểm: $e');
    }
    return 0;
  }
  
  // Bạn cũng có thể thêm hàm lấy streak để hiển thị trên UI
  Future<int> getUserStreak(String uid) async {
     try {
      final snapshot = await _dbRef
          .child('users')
          .child(uid)
          .child('streak')
          .get();
      if (snapshot.exists) {
        return snapshot.value as int;
      }
    } catch (e) {
      print('Lỗi khi lấy streak: $e');
    }
    return 0;
  }
  Future<int> purchaseItem(String userId, String itemId, int price) async {
    final userRef = _dbRef.child('users').child(userId);

    try {
      final result = await userRef.runTransaction((Object? data) {
        if (data == null) return Transaction.abort();

        // Convert dữ liệu
        final Map<String, dynamic> userData = Map<String, dynamic>.from(data as Map);
        final int currentCoins = (userData['coins'] ?? 0) as int;
        final Map<String, dynamic> inventory = Map<String, dynamic>.from(userData['inventory'] ?? {});

        // Kiểm tra tiền
        if (currentCoins < price) {
          return Transaction.abort(); // Hủy giao dịch nếu nghèo
        }

        // 1. Trừ tiền
        userData['coins'] = currentCoins - price;

        // 2. Cộng đồ
        final int currentCount = (inventory[itemId] ?? 0) as int;
        inventory[itemId] = currentCount + 1;
        userData['inventory'] = inventory;

        return Transaction.success(userData);
      });

      if (result.committed) {
        return 0; // Thành công
      } else {
        // Nếu không committed thì khả năng cao là do abort (không đủ tiền)
        // Check lại số dư thực tế để chắc chắn (hoặc trả về mã lỗi 1)
        return 1; 
      }
    } catch (e) {
      print("Lỗi mua hàng: $e");
      return 2;
    }
  }

  // --- 2. HÀM CẬP NHẬT SỐ LƯỢNG (Dùng khi Chơi game / Nhận thưởng) ---
  // change: số lượng thay đổi (ví dụ: -1 là dùng, +1 là nhận thưởng)
  Future<bool> updateItemCount(String userId, String itemId, int change) async {
    final userRef = _dbRef.child('users/$userId/inventory/$itemId');

    try {
      final result = await userRef.runTransaction((Object? currentData) {
        // Lấy số lượng hiện tại (nếu null coi như là 0)
        int currentCount = (currentData ?? 0) as int;
        
        // Tính số lượng mới
        int newCount = currentCount + change;

        // Nếu số lượng mới < 0 (ví dụ dùng thuốc khi đã hết) -> Hủy
        if (newCount < 0) {
          return Transaction.abort();
        }

        // Cập nhật số lượng mới
        return Transaction.success(newCount);
      });

      return result.committed;
    } catch (e) {
      print("Lỗi cập nhật item: $e");
      return false;
    }
  }
  
  // Hàm kiểm tra số lượng (Helper)
  Future<int> getItemCount(String userId, String itemId) async {
    final snapshot = await _dbRef.child('users/$userId/inventory/$itemId').get();
    if (snapshot.exists) {
      return (snapshot.value as int?) ?? 0;
    }
    return 0;
  }
}