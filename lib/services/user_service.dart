import 'package:firebase_database/firebase_database.dart';

class UserService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> updateGameScoreIfHigher(String uid, String gameKey, int newScore) async {
    try {
      final currentScore = await getGameScore(uid, gameKey);
      if (newScore > currentScore) {
        await _dbRef
            .child('users')
            .child(uid)
            .child('highScores')
            .update({gameKey: newScore});
      }
    } catch (e) {
      print('Lỗi khi cập nhật điểm: $e');
    }
  }

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
}
