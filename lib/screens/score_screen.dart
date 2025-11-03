import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ScoreScreen extends StatefulWidget {
  @override
  _ScoreScreenState createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  // --- THAY ĐỔI 1: Thêm 'streak' vào danh sách ---
  final List<String> _gameTypes = [
    'streak', // Thêm vào đây
    'observationGame',
    'memoryGame',
    'logicGame',
    'calculationGame'
  ];

  // --- THAY ĐỔI 2: Đặt 'streak' làm giá trị mặc định ---
  String _selectedGame = 'streak'; 

  // --- THAY ĐỔI 3: Cập nhật hàm _getScoresStream ---
  Stream<DatabaseEvent> _getScoresStream() {
    if (_selectedGame == 'streak') {
      // Nếu là 'streak', sắp xếp theo node 'streak'
      return _database.child('users').orderByChild('streak').onValue;
    } else {
      // Nếu là game, sắp xếp theo node 'highScores/ten_game'
      return _database.child('users').orderByChild('highScores/$_selectedGame').onValue;
    }
  }

  // --- THAY ĐỔI 4: Cập nhật hàm getGameDisplayName ---
  String getGameDisplayName(String key) {
    switch (key) {
      case 'memoryGame':
        return 'Trí nhớ';
      case 'observationGame':
        return 'Quan sát';
      case 'logicGame':
        return 'Logic';
      case 'calculationGame':
        return 'Tính toán';
      case 'streak': // Thêm case cho streak
        return 'Chuỗi ngày 🔥';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Xếp Hạng"), // Đổi tiêu đề
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            Text(
              'Bảng xếp hạng: ${getGameDisplayName(_selectedGame)}',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedGame,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Chọn bảng xếp hạng', // Đổi text
              ),
              items: _gameTypes.map((String game) {
                return DropdownMenuItem<String>(
                  value: game,
                  child: Text(getGameDisplayName(game)),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedGame = newValue!;
                });
              },
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _getScoresStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(child: Text('Có lỗi xảy ra'));
                  }

                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return Center(child: Text('Chưa có dữ liệu'));
                  }

                  final data = snapshot.data!.snapshot.value as Map;
                  List<Map<String, dynamic>> scores = [];

                  // --- THAY ĐỔI 5: Cập nhật logic trích xuất dữ liệu ---
                  data.forEach((key, value) {
                    // Biến 'value' giờ đây là giá trị để sắp xếp
                    final int displayValue; 
                    
                    if (_selectedGame == 'streak') {
                      displayValue = value['streak'] ?? 0;
                    } else {
                      var highScores = value['highScores'];
                      displayValue = highScores != null ? highScores[_selectedGame] ?? 0 : 0;
                    }

                    scores.add({
                      'username': value['name'],
                      'avatarBase64': value['avatarBase64'],
                      'value': displayValue, // Dùng key chung là 'value'
                    });
                  });

                  // Sắp xếp
                  if (_selectedGame == 'logicGame') { 
                    // Logic game: điểm thấp là tốt
                    scores.sort((a, b) => a['value'].compareTo(b['value']));
                  } else {
                    // Các game khác & streak: điểm cao là tốt
                    scores.sort((a, b) => b['value'].compareTo(a['value']));
                  }

                  return ListView.builder(
                    itemCount: scores.length,
                    itemBuilder: (context, index) {
                      final score = scores[index];
                      final rank = index + 1;
                      final isTop1 = rank == 1;

                      return Card(
                        color: isTop1 ? Colors.amber.shade100 : null,
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: isTop1 ? Colors.amber : Colors.blue,
                            child: Text('$rank'),
                          ),
                          title: Row(
                            children: [
                              if (isTop1) const Text('👑 ', style: TextStyle(fontSize: 18)),
                              if (score['avatarBase64'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: CircleAvatar(
                                    radius: 16,
                                    backgroundImage: MemoryImage(base64Decode(score['avatarBase64'])),
                                  ),
                                ),
                              Text(
                                score['username'],
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          // --- THAY ĐỔI 6: Cập nhật trailing ---
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min, // Quan trọng
                            children: [
                              // Nếu là streak, thêm icon lửa
                              if (_selectedGame == 'streak')
                                const Icon(
                                  Icons.local_fire_department,
                                  color: Colors.orange,
                                  size: 20,
                                ),
                              if (_selectedGame == 'streak') 
                                const SizedBox(width: 4),
                              // Hiển thị giá trị
                              Text(
                                score['value'].toString(), // Luôn dùng 'value'
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}