const functions = require("firebase-functions");
const admin = require("firebase-admin");

// Khởi tạo Firebase Admin để có quyền ghi vào Database
admin.initializeApp();

// Hàm Webhook nhận tín hiệu từ Sepay
exports.sepayWebhook = functions.https.onRequest(async (req, res) => {
    // 1. Lấy dữ liệu Sepay gửi sang
    const data = req.body;

    // Log ra để kiểm tra (xem trong Firebase Console -> Functions -> Logs)
    console.log("Dữ liệu nhận được từ Sepay:", JSON.stringify(data));

    const amount = data.transferAmount; // Số tiền (VND)
    const content = data.transferContent; // Nội dung chuyển khoản (Ví dụ: "NAP USER123")

    // 2. Kiểm tra dữ liệu đầu vào
    if (!content || !amount) {
        return res.status(400).send("Thiếu thông tin quan trọng");
    }

    // 3. Phân tích nội dung để tìm User ID
    // Quy ước nội dung chuyển khoản là: "NAP <USER_ID>"
    // Cần đảm bảo logic này khớp với app Flutter
    if (!content.includes("NAP")) {
        return res.status(200).send("Bỏ qua: Không đúng cú pháp");
    }

    // Lấy chuỗi sau chữ "NAP " và xóa khoảng trắng thừa
    // Ví dụ: "NAP J82ad..." -> lấy "J82ad..."
    // Lưu ý: Nếu ở App bạn chỉ gửi 6 ký tự cuối, thì ở đây bạn phải tìm User có 6 ký tự cuối trùng khớp.
    // ĐỂ ĐƠN GIẢN CHO ĐỒ ÁN: Ở App hãy gửi FULL UID luôn cho dễ tìm.
    const userId = content.split("NAP")[1].trim();

    if (!userId) {
        return res.status(200).send("Lỗi: Không tìm thấy User ID trong nội dung");
    }

    try {
        // 4. Quy đổi VND sang Xu (Ví dụ: 100đ = 1 Xu -> 20.000đ = 200 Xu)
        // Tùy chỉnh tỷ lệ này theo ý bạn
        const coinsToAdd = Math.floor(amount / 100);

        // 5. Cộng tiền vào Realtime Database
        // Đường dẫn phải khớp với cấu trúc DB của bạn: users/{userId}/coins
        const userRef = admin.database().ref(`users/${userId}`);

        // Dùng transaction để cộng dồn an toàn
        await userRef.child('coins').transaction((currentCoins) => {
            return (currentCoins || 0) + coinsToAdd;
        });

        console.log(`✅ Đã cộng ${coinsToAdd} xu cho user ${userId}`);

        // Trả lời Sepay là thành công
        return res.status(200).json({ success: true, message: "Đã cộng xu thành công" });

    } catch (error) {
        console.error("❌ Lỗi Server:", error);
        return res.status(500).send("Lỗi Server");
    }
});