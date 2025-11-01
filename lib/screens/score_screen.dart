import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ScoreScreen extends StatefulWidget {
  @override
  _ScoreScreenState createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  final List<String> _gameTypes = [
    'observationGame',
    'memoryGame',
    'logicGame',
    'calculationGame'
  ];

  String _selectedGame = 'observationGame';

  Stream<DatabaseEvent> _getScoresStream() {
    return _database.child('users').orderByChild('highScores/$_selectedGame').onValue;
  }

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
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Xếp Hạng Điểm"),
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
                labelText: 'Chọn trò chơi',
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
                    return Center(child: Text('Chưa có điểm cao nào'));
                  }

                  final data = snapshot.data!.snapshot.value as Map;
                  List<Map<String, dynamic>> scores = [];

                  data.forEach((key, value) {
                    var highScores = value['highScores'];
                    scores.add({
                      'username': value['name'],
                      'avatarBase64': value['avatarBase64'],
                      _selectedGame: highScores[_selectedGame] ?? 0,
                    });
                  });

                  if (_selectedGame == 'logicGame') { 
                    scores.sort((a, b) => a[_selectedGame].compareTo(b[_selectedGame]));
                  } else {
                    scores.sort((a, b) => b[_selectedGame].compareTo(a[_selectedGame]));
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
                          trailing: Text(
                            score[_selectedGame].toString(),
                            style: TextStyle(fontSize: 16),
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
