import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'main_menu.dart'; // Import MainMenu

class OnboardingSurveyScreen extends StatefulWidget {
  final User user;
  const OnboardingSurveyScreen({super.key, required this.user});

  @override
  State<OnboardingSurveyScreen> createState() => _OnboardingSurveyScreenState();
}

class _OnboardingSurveyScreenState extends State<OnboardingSurveyScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Các biến để lưu lựa chọn
  String? _selectedAgeGroup;
  String? _selectedCategory; // Đây là 'preferredCategory'

  bool _isLoading = false;

  final List<String> _ageGroups = ['Dưới 18', '18-25', '26-40', 'Trên 40'];
  final Map<String, String> _categories = {
    'memoryGame': 'Trí nhớ',
    'observationGame': 'Quan sát',
    'logicGame': 'Logic',
    'calculationGame': 'Tính toán',
  };

  Future<void> _submitSurvey() async {
    if (!_formKey.currentState!.validate()) {
      return; // Nếu form không hợp lệ, không làm gì cả
    }

    setState(() => _isLoading = true);

    try {
      // Cập nhật dữ liệu lên Firebase
      await FirebaseDatabase.instance.ref('users/${widget.user.uid}').update({
        'ageGroup': _selectedAgeGroup,
        'preferredCategory': _selectedCategory,
        'hasCompletedOnboarding': true, // Đánh dấu là đã hoàn thành
      });

      // Điều hướng đến MainMenu
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => MainMenu(user: widget.user)),
        );
      }
    } catch (e) {
      // Xử lý lỗi
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã xảy ra lỗi: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final Color backgroundColor = Theme.of(context).primaryColor; 

    return Scaffold(
      // 1. ĐẶT MÀU NỀN XANH TỔNG THỂ
      backgroundColor: backgroundColor,
      body: Center(
        child: SingleChildScrollView(
          // 2. PADDING BÊN NGOÀI THẺ TRẮNG
          // Tạo khoảng cách từ lề màn hình tới thẻ
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          
          child: Container(
            // 3. TẠO THẺ MÀU TRẮNG
            padding: const EdgeInsets.all(24.0), // Padding bên trong thẻ
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0), // Bo tròn góc
              boxShadow: [ // Thêm đổ bóng nhẹ cho đẹp
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min, // Giúp thẻ co lại vừa đủ
                children: [
                  Text(
                    'Chào mừng bạn!',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).primaryColor, 
                    ),
                  ),
                  const Text(
                    'Hãy cho chúng tôi biết thêm thông tin về bạn nhé.',
                    style: TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 40),

                  // --- 1. Câu hỏi Tuổi ---
                  // (Không cần đổi gì, nó sẽ tự động nằm trong thẻ trắng)
                  DropdownButtonFormField<String>(
                    value: _selectedAgeGroup,
                    hint: const Text('Chọn nhóm tuổi của bạn'),
                    decoration: const InputDecoration(
                      labelText: 'Nhóm tuổi',
                      border: OutlineInputBorder(),
                      // Thêm nền trắng nhẹ cho ô input để phân biệt
                      filled: true, 
                      fillColor: Color(0xFFFAFAFA), 
                    ),
                    items: _ageGroups.map((String age) {
                      return DropdownMenuItem<String>(
                        value: age,
                        child: Text(age),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAgeGroup = value;
                      });
                    },
                    validator: (value) =>
                        value == null ? 'Vui lòng chọn nhóm tuổi' : null,
                  ),
                  const SizedBox(height: 30),

                  // --- 2. Câu hỏi Mục tiêu ---
                  const Text(
                    'Bạn muốn cải thiện kỹ năng nào nhất?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  ..._categories.entries.map((entry) {
                    return RadioListTile<String>(
                      title: Text(entry.value),
                      value: entry.key,
                      groupValue: _selectedCategory,
                      onChanged: (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                    );
                  }).toList(),
                  
                  if (_formKey.currentState?.validate() == false &&
                      _selectedCategory == null)
                    Padding(
                      padding: const EdgeInsets.only(left: 15.0),
                      child: Text(
                        'Vui lòng chọn một kỹ năng',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                            fontSize: 12),
                      ),
                    ),

                  const SizedBox(height: 40),

                  // --- 3. Nút Submit ---
                  // 4. ĐỔI THÀNH TEXTBUTTON (GIỐNG TRONG HÌNH)
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: _submitSurvey,
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              foregroundColor: Theme.of(context).primaryColor,
                            ),
                            child: const Text(
                              'Bắt đầu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold, // Chữ đậm
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}