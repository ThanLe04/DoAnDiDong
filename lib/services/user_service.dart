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
}