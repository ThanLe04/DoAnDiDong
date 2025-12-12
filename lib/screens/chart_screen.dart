import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ChartScreen extends StatefulWidget {
  final User user;
  const ChartScreen({super.key, required this.user});

  @override
  State<ChartScreen> createState() => _ChartScreenState();
}

class _ChartScreenState extends State<ChartScreen> {
  final Map<String, List<String>> _gameCategoriesMap = {
    'Trí nhớ': ['memoryGame'],
    'Quan sát': ['observationGame'],
    'Logic': ['logicGame'],
    'Tính toán': ['calculationGame'],
    'Tốc độ': ['speedGame', 'calculationGame'],
  };

  @override
  Widget build(BuildContext context) {
    // --- BẢNG MÀU MỚI (NỀN TRẮNG - CHỮ XANH) ---
    const Color appPrimaryColor = Color.fromARGB(255, 101, 165, 233);
    const Color scaffoldBgColor = Colors.white; // Nền trắng
    
    // Màu lưới biểu đồ (Xanh mờ để nổi trên nền trắng)
    final Color gridColor = appPrimaryColor.withOpacity(0.3); 
    
    // Màu tô vùng dữ liệu (Xanh dương)
    final Color chartFillColor = appPrimaryColor.withOpacity(0.8);
    final Color chartBorderColor = appPrimaryColor;

    return Scaffold(
      backgroundColor: scaffoldBgColor, 
      appBar: AppBar(
        title: const Text(
          'Hồ sơ năng lực',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        // Icon nút Back màu đen hoặc xanh
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('users/${widget.user.uid}/highScores').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: appPrimaryColor));
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Lỗi tải dữ liệu', style: TextStyle(color: Colors.black54)));
          }

          final highScores = snapshot.data?.snapshot.value as Map<dynamic, dynamic>? ?? {};
          final radarData = _calculateRadarData(highScores);

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  // Tiêu đề (Chữ Xanh Đậm)
                  const Text(
                    'Biểu đồ Kỹ năng',
                    style: TextStyle(
                      fontSize: 26, 
                      fontWeight: FontWeight.bold, 
                      color: appPrimaryColor // Màu xanh chủ đạo
                    ),
                  ),
                  const SizedBox(height: 40),
                  
                  // --- VẼ BIỂU ĐỒ RADAR (GIAO DIỆN TRẮNG) ---
                  SizedBox(
                    height: 320,
                    child: RadarChart(
                      RadarChartData(
                        // Màu nền bên trong hình ngũ giác (Xanh rất nhạt cho dịu mắt)
                        radarBackgroundColor: appPrimaryColor.withOpacity(0.05),
                        

                        radarShape: RadarShape.polygon,
                        ticksTextStyle: const TextStyle(color: Colors.transparent),
                        
                        // Màu lưới (Grid Lines) -> Màu Xanh mờ
                        gridBorderData: BorderSide(color: gridColor, width: 1.5),
                        
                        // Viền bao ngoài cùng -> Màu Xanh rõ hơn chút
                        borderData: FlBorderData(show: true, border: Border.all(color: appPrimaryColor.withOpacity(0.5), width: 1.5)),

                        titlePositionPercentageOffset: 0.2,
                        
                        // Màu chữ các trục (Logic, Trí nhớ...) -> Màu Xanh Đậm
                        titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
                        
                        getTitle: (index, angle) {
                          final titles = _gameCategoriesMap.keys.toList();
                          if (index < titles.length) {
                            return RadarChartTitle(text: titles[index]);
                          }
                          return const RadarChartTitle(text: '');
                        },
                        
                        dataSets: [
                          RadarDataSet(
                            fillColor: chartFillColor,
                            borderColor: chartBorderColor,
                            entryRadius: 4,
                            borderWidth: 3,
                            dataEntries: _gameCategoriesMap.keys.map((category) {
                              return RadarEntry(value: radarData[category] ?? 0.0);
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // -------------------------
            
                  const SizedBox(height: 50),
                  
                  // Ghi chú (Card màu Xanh để tạo điểm nhấn ngược lại)
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: appPrimaryColor, // Nền Xanh
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: appPrimaryColor.withOpacity(0.4), 
                          blurRadius: 15, 
                          offset: const Offset(0, 5)
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.auto_graph, color: Colors.white, size: 32),
                        const SizedBox(height: 10),
                        const Text(
                          'Phân tích năng lực',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Biểu đồ hiển thị thế mạnh của bạn. Hãy chơi đều các game để hình ngũ giác trở nên cân đối!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 15, color: Colors.white), // Chữ trắng mờ
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Hàm tính toán dữ liệu
  Map<String, double> _calculateRadarData(Map<dynamic, dynamic> highScores) {
    Map<String, double> radarScores = {};

    _gameCategoriesMap.forEach((category, gameKeys) {
      double totalScore = 0;
      int count = 0;

      for (var key in gameKeys) {
        if (highScores.containsKey(key)) {
          double rawScore = (highScores[key] as num).toDouble();
          totalScore += rawScore;
          count++;
        }
      }
      
      double avgScore = count > 0 ? (totalScore / count) : 0.0;
      // Giới hạn hiển thị tối thiểu là 10 để biểu đồ đẹp
      radarScores[category] = avgScore < 10 ? 10.0 : avgScore;
    });

    return radarScores;
  }
}