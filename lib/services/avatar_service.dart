import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';

Future<void> pickAndUploadAvatarBase64(String userId) async {
  final picker = ImagePicker();
  final pickedImage = await picker.pickImage(source: ImageSource.gallery);

  if (pickedImage != null) {
    final bytes = await File(pickedImage.path).readAsBytes();
    final base64Image = base64Encode(bytes);

    // Lưu vào Firebase Realtime Database
    await FirebaseDatabase.instance
        .ref('users/$userId/avatarBase64')
        .set(base64Image);
  }
}
