import 'package:just_audio/just_audio.dart';

class AudioManager {
  static final AudioManager _instance = AudioManager._internal();
  factory AudioManager() => _instance;

  final AudioPlayer _player = AudioPlayer();

  AudioManager._internal();

  Future<void> startMusic() async {
    try {
      await _player.setAsset('assets/music/Aylex-LastSummer.mp3');
      _player.setLoopMode(LoopMode.all);
      await _player.play();
    } catch (e) {
      print("Lỗi khi phát nhạc: $e");
    }
  }

  void stopMusic() {
    _player.stop();
  }

  void pauseMusic() {
    _player.pause();
  }

  void resumeMusic() {
    _player.play();
  }

  void dispose() {
    _player.dispose();
  }

  double _currentVolume = 1.0; // Mặc định 100%

  void setVolume(double volume) {
    _currentVolume = volume;
    _player.setVolume(volume); // Giá trị từ 0.0 (tắt) đến 1.0 (to nhất)
  }

  double get currentVolume => _currentVolume;
}
