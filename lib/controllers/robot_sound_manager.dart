import 'package:audioplayers/audioplayers.dart';

class RobotSoundManager {
  final AudioPlayer _sfxPlayer = AudioPlayer();
  final AudioPlayer _loopPlayer = AudioPlayer();

  bool isMuted = false;

  Future<void> init() async {
    await _loopPlayer.setVolume(0.35); // loops are softer
  }

  /// Play a sound from assets/sounds/
  Future<void> play(
    String soundName, {
    bool loop = false,
    double volume = 1.0,
  }) async {
    if (isMuted) return;

    final path = 'sounds/$soundName.mp3';

    if (loop) {
      await _loopPlayer.setSource(AssetSource(path));
      await _loopPlayer.setReleaseMode(ReleaseMode.loop);
      await _loopPlayer.resume();
    } else {
      await _sfxPlayer.setVolume(volume);
      await _sfxPlayer.play(AssetSource(path));
    }
  }

  void stopLoop() {
    _loopPlayer.stop();
  }

  void toggleMute() {
    isMuted = !isMuted;
    if (isMuted) stopLoop();
  }

  void dispose() {
    _sfxPlayer.dispose();
    _loopPlayer.dispose();
  }
}
