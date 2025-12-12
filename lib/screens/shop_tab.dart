import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import '../../services/user_service.dart'; // Đảm bảo đường dẫn đúng

class ShopTab extends StatefulWidget {
  final User user;
  const ShopTab({super.key, required this.user});

  @override
  State<ShopTab> createState() => _ShopTabState();
}

class _ShopTabState extends State<ShopTab> {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();
  final UserService _userService = UserService();

  // --- CẤU HÌNH TÀI KHOẢN NHẬN TIỀN ---
  final String myBankId = 'MB'; 
  final String myAccountNo = '0393157003'; // Thay số tài khoản của bạn vào đây
  // ------------------------------------

  // Danh sách vật phẩm
  final List<Map<String, dynamic>> _shopItems = [
    {
      'id': 'revive_potion',
      'name': 'Hồi sinh',
      'desc': 'Tiếp tục chơi khi lỡ trả lời sai. (1 lần/ván)',
      'price': 10,
      'icon': Icons.favorite,
      'color': Colors.redAccent,
    },
    {
      'id': 'streak_freeze',
      'name': 'Khiên băng',
      'desc': 'Bảo vệ chuỗi Streak nếu bạn quên đăng nhập 1 ngày.',
      'price': 10,
      'icon': Icons.ac_unit,
      'color': Colors.lightBlueAccent,
    },
  ];

  // --- XỬ LÝ MUA HÀNG ---
  Future<void> _handlePurchase(String itemId, String itemName, int price) async {
    int result = await _userService.purchaseItem(widget.user.uid, itemId, price);

    if (!mounted) return;

    if (result == 0) {
      _showSnackBar('Đã mua thành công: $itemName', Colors.green);
    } else if (result == 1) {
      _showSnackBar("Bạn không đủ tiền để mua món này!", Colors.red);
    } else {
      _showSnackBar("Có lỗi xảy ra, vui lòng thử lại sau.", Colors.red);
    }
  }

  // --- 1. CHỌN GÓI NẠP ---
  void _showDepositOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        height: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Nạp Xu (Tự động duyệt)",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.attach_money, color: Colors.green),
              ),
              title: const Text("Gói Cơ Bản"),
              subtitle: const Text("20.000đ = 200 Xu"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                // Truyền vào: Số tiền VND, Số xu hiện tại (để so sánh)
                _prepareTransaction(20000); 
              },
            ),
            
            const Divider(),

            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.diamond, color: Colors.orange),
              ),
              title: const Text("Gói Đại Gia"),
              subtitle: const Text("50.000đ = 600 Xu (Bonus +100)"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                _prepareTransaction(50000);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- 2. CHUẨN BỊ GIAO DỊCH ---
  void _prepareTransaction(int amountVND) async {
    // Lấy số dư hiện tại trước khi mở QR để làm mốc so sánh
    final snapshot = await _dbRef.child('users/${widget.user.uid}/coins').get();
    int currentCoins = (snapshot.value as int?) ?? 0;

    if (!mounted) return;
    
    // Mở QR Dialog và bắt đầu lắng nghe
    _showRealtimeQRDialog(amountVND, currentCoins);
  }

  // --- 3. HIỂN THỊ QR VÀ TỰ ĐỘNG CHECK (REAL-TIME) ---
  void _showRealtimeQRDialog(int amountVND, int initialCoins) {
    // Nội dung chuyển khoản: NAP + 6 ký tự cuối của UID (để Server nhận diện)
    String content = "NAP ${widget.user.uid}"; 
    
    String qrUrl = 'https://img.vietqr.io/image/$myBankId-$myAccountNo-compact.png?amount=$amountVND&addInfo=$content';

    showDialog(
      context: context,
      barrierDismissible: false, // Bắt buộc người dùng phải bấm Hủy mới thoát
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(15),
              decoration: const BoxDecoration(
                color: Color(0xFF578FCA),
                borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.qr_code_scanner, color: Colors.white),
                  SizedBox(width: 10),
                  Expanded(child: Text("Quét mã để thanh toán", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Ảnh QR
            Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  qrUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (_, child, loading) => loading == null ? child : const Center(child: CircularProgressIndicator()),
                  errorBuilder: (_, __, ___) => const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              ),
            ),

            const SizedBox(height: 15),
            Text(
              "${amountVND} VNĐ",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24, color: Colors.black87),
            ),
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: Colors.yellow.shade100, borderRadius: BorderRadius.circular(5)),
              child: Text("Nội dung: $content", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
            const SizedBox(height: 10),
            const Text(
              "Đang chờ ngân hàng xác nhận...",
              style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
            ),
            
            // --- BỘ LẮNG NGHE TỰ ĐỘNG (THE SOUL) ---
            StreamBuilder(
              stream: _dbRef.child('users/${widget.user.uid}/coins').onValue,
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.snapshot.value != null) {
                  int nowCoins = (snapshot.data!.snapshot.value as int);
                  
                  // LOGIC THẦN THÁNH: Nếu tiền hiện tại > tiền lúc mới mở Dialog -> Đã nạp thành công
                  if (nowCoins > initialCoins) {
                    // Dùng addPostFrameCallback để đóng dialog an toàn sau khi build xong
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      // Kiểm tra xem dialog có đang mở không để đóng
                      if (Navigator.canPop(ctx)) {
                        Navigator.pop(ctx); // Đóng Dialog
                        _showSuccessPayment(); // Hiện pháo hoa
                      }
                    });
                  }
                }
                return const SizedBox.shrink(); // Widget tàng hình
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Hủy giao dịch", style: TextStyle(color: Colors.grey)),
            ),
          ),
        ],
      ),
    );
  }

  void _showSuccessPayment() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 10),
            Expanded(child: Text("Thành công! Tiền đã vào tài khoản.")),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color, behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color appPrimaryColor = Color(0xFF578FCA);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Cửa Hàng', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder(
        stream: _dbRef.child('users/${widget.user.uid}').onValue,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data?.snapshot.value as Map<dynamic, dynamic>? ?? {};
          final int coins = (data['coins'] ?? 0) as int;
          final Map inventory = data['inventory'] ?? {};

          return Column(
            children: [
              // HEADER TIỀN
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.amber, width: 2),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Colors.amber, size: 24),
                          const SizedBox(width: 8),
                          Text('$coins', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Nút NẠP TIỀN (+)
                    InkWell(
                      onTap: _showDepositOptions,
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: appPrimaryColor, shape: BoxShape.circle),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),

              // DANH SÁCH VẬT PHẨM
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: _shopItems.length,
                  itemBuilder: (context, index) {
                    final item = _shopItems[index];
                    final String itemId = item['id'];
                    final int ownedCount = (inventory[itemId] ?? 0) as int;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 2, blurRadius: 5, offset: const Offset(0, 3)),
                        ],
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: item['color'].withOpacity(0.1),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Icon(item['icon'], color: item['color'], size: 40),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(item['name'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Text(item['desc'], style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                                const SizedBox(height: 8),
                                Text("Hiện có: $ownedCount", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.blueGrey)),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text('Mua ${item['name']}?'),
                                  content: Text('Giá: ${item['price']} xu'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(ctx);
                                        _handlePurchase(item['id'], item['name'], item['price']);
                                      },
                                      child: const Text('Mua ngay'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appPrimaryColor,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.monetization_on, size: 16, color: Colors.white),
                                const SizedBox(width: 4),
                                Text('${item['price']}', style: const TextStyle(color: Colors.white)),
                              ],
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
    );
  }
}