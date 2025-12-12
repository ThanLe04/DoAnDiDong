import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard_tab.dart'; // Tab 1: Trang chủ cũ
import 'profile_tab.dart';   // Tab 2: Hồ sơ mới
import 'shop_tab.dart';

class MainScreen extends StatefulWidget {
  final User user;
  const MainScreen({super.key, required this.user});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 1; // Mặc định chọn tab đầu tiên (Home)

  // Danh sách các màn hình con
  late final List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _pages = [
      ShopTab(user: widget.user),
      DashboardTab(user: widget.user), // Tab 1
      ProfileTab(user: widget.user),   // Tab 2
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Body sẽ thay đổi dựa theo tab đang chọn
      body: IndexedStack( // Dùng IndexedStack để giữ trạng thái khi chuyển tab
        index: _selectedIndex,
        children: _pages,
      ),
      
      // Thanh điều hướng bên dưới
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront),
            label: 'Cửa hàng',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_filled),
            label: 'Trang chủ',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent, // Màu khi chọn
        unselectedItemColor: Colors.grey,     // Màu khi không chọn
        onTap: _onItemTapped,
      ),
    );
  }
}