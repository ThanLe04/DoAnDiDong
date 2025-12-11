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
  // Định nghĩa các game thuộc thể loại nào
  final Map<String, List<String>> _gameCategoriesMap = {
    'Trí nhớ': ['memoryGame'],
    'Quan sát': ['observationGame'],
    'Logic': ['logicGame'],
    'Tính toán': ['calculationGame'],
    'Tốc độ': ['speedGame'], // Ví dụ thêm 1 loại
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hồ sơ năng lực')),
      body: StreamBuilder(
        stream: FirebaseDatabase.instance.ref('users/${widget.user.uid}/highScores').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return const Center(child: Text('Lỗi tải dữ liệu'));
          }

          final highScores = snapshot.data?.snapshot.value as Map<dynamic, dynamic>? ?? {};
          
          // Tính toán dữ liệu cho biểu đồ
          final radarData = _calculateRadarData(highScores);

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                const Text(
                  'Biểu đồ kỹ năng não bộ',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 40),
                
                // --- VẼ BIỂU ĐỒ RADAR ---
                SizedBox(
                  height: 300,
                  child: RadarChart(
                    RadarChartData(
                      radarShape: RadarShape.polygon,
                      ticksTextStyle: const TextStyle(color: Colors.transparent),
                      gridBorderData: BorderSide(color: Colors.grey.shade300, width: 1),
                      titlePositionPercentageOffset: 0.2,
                      titleTextStyle: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.bold),
                      
                      // Cấu hình các trục (5 cạnh)
                      getTitle: (index, angle) {
                        final titles = _gameCategoriesMap.keys.toList();
                        if (index < titles.length) {
                          return RadarChartTitle(text: titles[index]);
                        }
                        return const RadarChartTitle(text: '');
                      },
                      
                      // Dữ liệu
                      dataSets: [
                        RadarDataSet(
                          fillColor: Colors.blue.withOpacity(0.4),
                          borderColor: Colors.blue,
                          entryRadius: 3,
                          dataEntries: _gameCategoriesMap.keys.map((category) {
                            return RadarEntry(value: radarData[category] ?? 0.0);
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                // -------------------------

                const SizedBox(height: 40),
                // Ghi chú
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Biểu đồ này hiển thị điểm trung bình của bạn ở các kỹ năng khác nhau. Hãy chơi nhiều game hơn để mở rộng biểu đồ!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
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
          // Lấy điểm thô
          double rawScore = (highScores[key] as num).toDouble();
          
          // CHUẨN HÓA VỀ THANG 100 (Ví dụ)
          // Bạn cần sửa logic này tùy theo thang điểm max của từng game
          if (category == 'Logic') {
             // Logic game điểm thấp là tốt -> Cần đảo ngược (ví dụ 60s - thời gian)
             // Tạm thời để nguyên cho đơn giản
             totalScore += rawScore;
          } else {
             totalScore += rawScore;
          }
          count++;
        }
      }
      // Tính trung bình
      radarScores[category] = count > 0 ? (totalScore / count) : 0.0;
    });

    return radarScores;
  }
}