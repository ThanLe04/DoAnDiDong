import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class ScoreScreen extends StatefulWidget {
  const ScoreScreen({super.key});

  @override
  State<ScoreScreen> createState() => _ScoreScreenState();
}

class _ScoreScreenState extends State<ScoreScreen> {
  final DatabaseReference _database = FirebaseDatabase.instance.ref();

  final List<String> _gameTypes = [
    'streak',
    'observationGame',
    'memoryGame',
    'logicGame',
    'calculationGame'
  ];

  String _selectedGame = 'streak'; 

  Stream<DatabaseEvent> _getScoresStream() {
    if (_selectedGame == 'streak') {
      return _database.child('users').orderByChild('streak').onValue;
    } else {
      return _database.child('users').orderByChild('highScores/$_selectedGame').onValue;
    }
  }

  String getGameDisplayName(String key) {
    switch (key) {
      case 'memoryGame': return 'Trí nhớ';
      case 'observationGame': return 'Quan sát';
      case 'logicGame': return 'Logic';
      case 'calculationGame': return 'Tính toán';
      case 'streak': return 'Chuỗi ngày 🔥';
      default: return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- BẢNG MÀU MỚI (LIGHT THEME) ---
    const Color appPrimaryColor = Color.fromARGB(255, 101, 165, 233); // Màu xanh chủ đạo
    const Color scaffoldBgColor = Colors.white; // Nền màn hình TRẮNG
    const Color cardColor = Colors.white;
    
    return Scaffold(
      backgroundColor: scaffoldBgColor, 
      body: SafeArea(
        child: Column(
          children: [
            // --- A. HEADER (Màu Xanh trên nền Trắng) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nút Back (Viền Xanh, Icon Xanh)
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: appPrimaryColor.withOpacity(0.3), width: 1),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: appPrimaryColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  
                  // Tiêu đề (Chữ Xanh Đậm)
                  const Text(
                    "Bảng Xếp Hạng",
                    style: TextStyle(
                      color: appPrimaryColor, // Đổi thành màu xanh
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(width: 48), 
                ],
              ),
            ),

            // --- B. LIST DỮ LIỆU ---
            Expanded(
              child: StreamBuilder<DatabaseEvent>(
                stream: _getScoresStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: appPrimaryColor));
                  }
                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return Center(child: Text('Chưa có dữ liệu', style: TextStyle(color: Colors.grey[400])));
                  }

                  final data = snapshot.data!.snapshot.value as Map;
                  List<Map<String, dynamic>> scores = [];

                  data.forEach((key, value) {
                    final int displayValue; 
                    if (_selectedGame == 'streak') {
                      displayValue = (value['streak'] ?? 0) as int;
                    } else {
                      var highScores = value['highScores'];
                      displayValue = highScores != null ? (highScores[_selectedGame] ?? 0) as int : 0;
                    }
                    scores.add({
                      'username': value['name'] ?? 'Unknown',
                      'avatarBase64': value['avatarBase64'],
                      'value': displayValue,
                    });
                  });

                  scores.sort((a, b) => b['value'].compareTo(a['value']));

                  final topUser = scores.isNotEmpty ? scores[0] : null;
                  final otherUsers = scores.length > 1 ? scores.sublist(1) : [];

                  return Column(
                    children: [
                      // --- B1. TOP 1 PLAYER (Giao diện sáng) ---
                      if (topUser != null)
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            Stack(
                              alignment: Alignment.center,
                              clipBehavior: Clip.none,
                              children: [
                                // Avatar Top 1
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: appPrimaryColor.withOpacity(0.1), // Viền xanh nhạt
                                    boxShadow: [
                                      BoxShadow(color: appPrimaryColor.withOpacity(0.2), blurRadius: 20)
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundImage: topUser['avatarBase64'] != null
                                        ? MemoryImage(base64Decode(topUser['avatarBase64']))
                                        : const AssetImage('assets/avatar1.png') as ImageProvider,
                                  ),
                                ),
                                // Vương miện
                                const Positioned(
                                  top: -28,
                                  child: Icon(Icons.emoji_events, color: Colors.amber, size: 45),
                                ),
                                // Badge số 1
                                Positioned(
                                  bottom: -10,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.amber,
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
                                    ),
                                    child: const Text("1", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            // Tên Top 1 (Màu Đen/Xanh Đậm)
                            Text(
                              topUser['username'],
                              style: const TextStyle(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            // Điểm số (Nền Xanh, Chữ Trắng - Đảo ngược lại lúc nãy)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                              decoration: BoxDecoration(
                                color: appPrimaryColor, // Nền Xanh
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [BoxShadow(color: appPrimaryColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4))]
                              ),
                              child: Text(
                                "${topUser['value']} ${_selectedGame == 'streak' ? 'Ngày 🔥' : 'Điểm'}",
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), // Chữ Trắng
                              ),
                            ),
                          ],
                        ),

                      const SizedBox(height: 20),

                      // --- B2. DANH SÁCH USER CÒN LẠI ---
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: otherUsers.length,
                          itemBuilder: (context, index) {
                            final user = otherUsers[index];
                            final int rank = index + 2; 

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              decoration: BoxDecoration(
                                color: cardColor, 
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(color: Colors.grey.shade100), // Thêm viền mờ cho card dễ thấy trên nền trắng
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.1), // Bóng xám nhẹ
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundImage: user['avatarBase64'] != null
                                        ? MemoryImage(base64Decode(user['avatarBase64']))
                                        : const AssetImage('assets/avatar1.png') as ImageProvider,
                                  ),
                                  const SizedBox(width: 15),
                                  
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          user['username'],
                                          style: const TextStyle(
                                            color: Colors.black87, // Tên màu đen
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            Text(
                                              "${user['value']}",
                                              style: const TextStyle(
                                                color: appPrimaryColor, // Điểm màu xanh
                                                fontWeight: FontWeight.w800,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              _selectedGame == 'streak' ? 'Ngày 🔥' : 'Điểm',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  Container(
                                    width: 32,
                                    height: 32,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.grey.shade50,
                                      border: Border.all(color: appPrimaryColor.withOpacity(0.3)),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "$rank",
                                        style: const TextStyle(
                                          color: appPrimaryColor, 
                                          fontSize: 14, 
                                          fontWeight: FontWeight.bold
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // --- C. BOTTOM BAR (Giữ nguyên style Trắng, thêm viền đậm hơn xíu) ---
            Container(
              margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20), 
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white, 
                borderRadius: BorderRadius.circular(30), 
                border: Border.all(color: Colors.grey.shade200), // Thêm viền để tách khỏi nền trắng
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 15,
                    offset: const Offset(0, 5), 
                  )
                ],
              ),
              child: Row(
                children: [
                  Text(
                    "Xem hạng:",
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 15),
                  
                  // Dropdown chính
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: appPrimaryColor.withOpacity(0.2), width: 1.5), 
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedGame,
                          isExpanded: true,
                          dropdownColor: Colors.white,
                          icon: const Icon(Icons.keyboard_arrow_down, color: appPrimaryColor),
                          style: const TextStyle(
                            color: appPrimaryColor, 
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          borderRadius: BorderRadius.circular(20), 
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedGame = newValue!;
                            });
                          },
                          items: _gameTypes.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Row(
                                children: [
                                  Icon(
                                    value == 'streak' ? Icons.local_fire_department : Icons.videogame_asset,
                                    size: 20,
                                    color: value == 'streak' ? Colors.orange : appPrimaryColor,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(getGameDisplayName(value)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}