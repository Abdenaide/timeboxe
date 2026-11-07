import 'dart:math';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AudioService {
  AudioService() {
    _configureMobileAudio();
  }

  // Small pool of players so overlap-safe sounds (buzzer -> double bell,
  // warning beeps) don't cancel each other with stop().
  final List<AudioPlayer> _players = [
    AudioPlayer(),
    AudioPlayer(),
    AudioPlayer(),
  ];
  int _nextPlayer = 0;

  /// Makes the workout sounds behave like an alarm on mobile: they are routed
  /// to the alarm stream (audible even with media volume low) and, on iOS, they
  /// play even when the phone is in silent mode.
  Future<void> _configureMobileAudio() async {
    if (kIsWeb) return;
    try {
      await AudioPlayer.global.setAudioContext(
        AudioContext(
          android: const AudioContextAndroid(
            isSpeakerphoneOn: false,
            audioMode: AndroidAudioMode.normal,
            stayAwake: false,
            contentType: AndroidContentType.sonification,
            usageType: AndroidUsageType.alarm,
            audioFocus: AndroidAudioFocus.gainTransientMayDuck,
          ),
          iOS: AudioContextIOS(
            category: AVAudioSessionCategory.playback,
            options: const {AVAudioSessionOptions.mixWithOthers},
          ),
        ),
      );
    } catch (_) {
      // Not supported on this platform (e.g. desktop); sounds still play.
    }
  }

  /// Short vibration used together with the sounds on phones.
  void _haptic(Future<void> Function() feedback) {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return;
    }
    feedback().catchError((_) {});
  }

  AudioPlayer _takePlayer() {
    final player = _players[_nextPlayer];
    _nextPlayer = (_nextPlayer + 1) % _players.length;
    return player;
  }

  Uint8List? _bellWav;
  Uint8List? _buzzerWav;
  Uint8List? _beepWav;
  Uint8List? _doubleBellWav;

  Uint8List _cachedBellWav() => _bellWav ??= _generateToneWav(
    frequency: 800,
    durationMs: 500,
    volume: 0.8,
    decay: 3.0,
  );

  Uint8List _cachedBuzzerWav() => _buzzerWav ??= _generateToneWav(
    frequency: 400,
    durationMs: 700,
    volume: 0.7,
    decay: 1.5,
  );

  Uint8List _cachedBeepWav() => _beepWav ??= _generateToneWav(
    frequency: 1000,
    durationMs: 150,
    volume: 0.6,
    decay: 5.0,
  );

  bool _isMuted = false;

  bool get isMuted => _isMuted;

  void toggleMute() {
    _isMuted = !_isMuted;
  }

  /// Play round start bell
  Future<void> playBell() async {
    if (_isMuted) return;
    _haptic(HapticFeedback.mediumImpact);
    try {
      await _takePlayer().play(BytesSource(_cachedBellWav()));
    } catch (_) {}
  }

  /// Play round end buzzer
  Future<void> playBuzzer() async {
    if (_isMuted) return;
    _haptic(HapticFeedback.heavyImpact);
    try {
      await _takePlayer().play(BytesSource(_cachedBuzzerWav()));
    } catch (_) {}
  }

  /// Play warning beep
  Future<void> playBeep() async {
    if (_isMuted) return;
    _haptic(HapticFeedback.selectionClick);
    try {
      await _takePlayer().play(BytesSource(_cachedBeepWav()));
    } catch (_) {}
  }

  /// Play double bell at the end of workout
  Future<void> playDoubleBell() async {
    if (_isMuted) return;
    _haptic(HapticFeedback.heavyImpact);
    try {
      await _takePlayer().play(BytesSource(_cachedDoubleBellWav()));
    } catch (_) {}
  }

  Uint8List _cachedDoubleBellWav() => _doubleBellWav ??= () {
    final bell1 = _generateToneSamples(
      frequency: 800,
      durationMs: 350,
      volume: 0.8,
      decay: 4.0,
    );
    final silence = Uint8List((22050 * 2 * 0.15).toInt()); // 150ms silence
    final bell2 = _generateToneSamples(
      frequency: 900,
      durationMs: 450,
      volume: 0.8,
      decay: 3.0,
    );
    final combined = Uint8List.fromList([...bell1, ...silence, ...bell2]);
    return _wrapInWav(combined, 22050);
  }();

  /// Generate raw PCM 16-bit mono samples
  Uint8List _generateToneSamples({
    required double frequency,
    required int durationMs,
    required double volume,
    required double decay,
    int sampleRate = 22050,
  }) {
    final numSamples = (sampleRate * durationMs / 1000).toInt();
    final bytes = ByteData(numSamples * 2);

    for (int i = 0; i < numSamples; i++) {
      final t = i / sampleRate;
      final envelope = volume * exp(-decay * t);
      final sample = (envelope * sin(2 * pi * frequency * t) * 32767)
          .toInt()
          .clamp(-32767, 32767);
      bytes.setInt16(i * 2, sample, Endian.little);
    }

    return bytes.buffer.asUint8List();
  }

  /// Generate a complete WAV file bytes from a tone
  Uint8List _generateToneWav({
    required double frequency,
    required int durationMs,
    required double volume,
    required double decay,
    int sampleRate = 22050,
  }) {
    final samples = _generateToneSamples(
      frequency: frequency,
      durationMs: durationMs,
      volume: volume,
      decay: decay,
      sampleRate: sampleRate,
    );
    return _wrapInWav(samples, sampleRate);
  }

  /// Wrap raw PCM data in a WAV header
  Uint8List _wrapInWav(Uint8List rawData, int sampleRate) {
    final dataLength = rawData.length;
    final fileLength = dataLength + 36;
    final header = ByteData(44);

    // RIFF header
    header.setUint8(0, 0x52); // R
    header.setUint8(1, 0x49); // I
    header.setUint8(2, 0x46); // F
    header.setUint8(3, 0x46); // F
    header.setUint32(4, fileLength, Endian.little);
    header.setUint8(8, 0x57); // W
    header.setUint8(9, 0x41); // A
    header.setUint8(10, 0x56); // V
    header.setUint8(11, 0x45); // E

    // fmt subchunk
    header.setUint8(12, 0x66); // f
    header.setUint8(13, 0x6D); // m
    header.setUint8(14, 0x74); // t
    header.setUint8(15, 0x20); // ' '
    header.setUint32(16, 16, Endian.little); // PCM chunk size
    header.setUint16(20, 1, Endian.little); // PCM format
    header.setUint16(22, 1, Endian.little); // Mono
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, sampleRate * 2, Endian.little); // Byte rate
    header.setUint16(32, 2, Endian.little); // Block align
    header.setUint16(34, 16, Endian.little); // Bits per sample

    // data subchunk
    header.setUint8(36, 0x64); // d
    header.setUint8(37, 0x61); // a
    header.setUint8(38, 0x74); // t
    header.setUint8(39, 0x61); // a
    header.setUint32(40, dataLength, Endian.little);

    return Uint8List.fromList([...header.buffer.asUint8List(), ...rawData]);
  }

  void dispose() {
    for (final player in _players) {
      player.dispose();
    }
  }
}
