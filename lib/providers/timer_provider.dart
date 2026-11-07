import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/workout_config.dart';
import '../models/timer_state.dart';
import '../services/audio_service.dart';

class TimerProvider extends ChangeNotifier {
  final AudioService _audioService;

  TimerProvider(this._audioService);

  // State
  WorkoutConfig? _config;
  TimerPhase _phase = TimerPhase.preparation;
  int _currentRound = 1;
  int _remainingSeconds = 0;
  int _totalPhaseSeconds = 0;
  bool _isRunning = false;
  bool _isPaused = false;
  bool _hasStarted = false;

  Timer? _timer;
  DateTime? _phaseEndsAt;
  int _lastWarningBeepSecond = -1;

  // Getters
  WorkoutConfig? get config => _config;
  TimerPhase get phase => _phase;
  int get currentRound => _currentRound;
  int get remainingSeconds => _remainingSeconds;
  int get totalPhaseSeconds => _totalPhaseSeconds;
  bool get isRunning => _isRunning;
  bool get isPaused => _isPaused;
  bool get hasStarted => _hasStarted;
  bool get isFinished => _phase == TimerPhase.finished;
  AudioService get audioService => _audioService;

  double get progress {
    if (_totalPhaseSeconds == 0) return 0;
    return 1.0 - (_remainingSeconds / _totalPhaseSeconds);
  }

  String get timeDisplay {
    final minutes = _remainingSeconds ~/ 60;
    final seconds = _remainingSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String get phaseLabel {
    if (_phase == TimerPhase.round || _phase == TimerPhase.warning) {
      return 'ROUND $_currentRound';
    }
    return _phase.label;
  }

  String get phaseSubLabel {
    if (_config == null) return '';
    switch (_phase) {
      case TimerPhase.preparation:
        return 'Round 1 começando...';
      case TimerPhase.round:
      case TimerPhase.warning:
        return 'de ${_config!.rounds}';
      case TimerPhase.rest:
        return 'Próximo: Round ${_currentRound + 1}';
      case TimerPhase.finished:
        return 'Treino completo! 🥊';
    }
  }

  String get currentPhaseKey {
    return _phase.phaseKey;
  }

  bool get isInWarning {
    return _phase == TimerPhase.warning ||
        (_phase == TimerPhase.round &&
            _config != null &&
            _remainingSeconds <= _config!.warningSeconds &&
            _remainingSeconds > 0);
  }

  // Actions
  void configure(WorkoutConfig config) {
    _config = config;
    _reset();
    notifyListeners();
  }

  void start() {
    if (_config == null) return;

    if (!_hasStarted) {
      _hasStarted = true;
      _currentRound = 1;

      if (_config!.prepDurationSeconds > 0) {
        _setPhase(TimerPhase.preparation, _config!.prepDurationSeconds);
      } else {
        _setPhase(TimerPhase.round, _config!.roundDurationSeconds);
        _audioService.playBell();
      }
    }

    _isRunning = true;
    _isPaused = false;
    _phaseEndsAt = DateTime.now().add(Duration(seconds: _remainingSeconds));

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), _onTick);

    notifyListeners();
  }

  void pause() {
    if (!_isRunning) return;
    if (_phaseEndsAt != null) {
      final remaining = _phaseEndsAt!.difference(DateTime.now()).inSeconds;
      _remainingSeconds = remaining > 0 ? remaining : 0;
    }
    _timer?.cancel();
    _phaseEndsAt = null;
    _isRunning = false;
    _isPaused = true;
    notifyListeners();
  }

  void resume() {
    start();
  }

  void stop() {
    _timer?.cancel();
    _reset();
    notifyListeners();
  }

  void skipToNext() {
    if (_config == null) return;
    if (!_hasStarted || _phase == TimerPhase.finished) return;
    _handlePhaseEnd();
    notifyListeners();
  }

  void togglePause() {
    if (_isRunning) {
      pause();
    } else if (_isPaused) {
      resume();
    } else {
      start();
    }
  }

  // Internal
  void _onTick(Timer timer) {
    if (!_isRunning || _phaseEndsAt == null) return;

    final remainingMs = _phaseEndsAt!.difference(DateTime.now()).inMilliseconds;
    final remainingSeconds = (remainingMs / 1000).ceil();

    if (remainingMs <= 0) {
      _remainingSeconds = 0;
      _handlePhaseEnd();
      notifyListeners();
      return;
    }

    if (remainingSeconds == _remainingSeconds) return;
    _remainingSeconds = remainingSeconds;

    // Check for warning phase transition
    if (_phase == TimerPhase.round &&
        _config != null &&
        _remainingSeconds <= _config!.warningSeconds &&
        _remainingSeconds > 0) {
      if (_phase != TimerPhase.warning) {
        _phase = TimerPhase.warning;
        _audioService.playBeep();
      }
      // Beep once per second during the last 3 seconds.
      if (_remainingSeconds <= 3 &&
          _remainingSeconds != _lastWarningBeepSecond) {
        _lastWarningBeepSecond = _remainingSeconds;
        _audioService.playBeep();
      }
    }

    notifyListeners();
  }

  void _handlePhaseEnd() {
    if (_config == null) return;

    switch (_phase) {
      case TimerPhase.preparation:
        // Start first round
        _setPhase(TimerPhase.round, _config!.roundDurationSeconds);
        _audioService.playBell();
        break;

      case TimerPhase.round:
      case TimerPhase.warning:
        // End of round
        if (_currentRound >= _config!.rounds) {
          // Workout finished. Play only the final bell (the buzzer
          // would be cancelled immediately by the double bell).
          _timer?.cancel();
          _phase = TimerPhase.finished;
          _remainingSeconds = 0;
          _phaseEndsAt = null;
          _isRunning = false;
          _isPaused = false;
          _audioService.playDoubleBell();
        } else {
          _audioService.playBuzzer();
          // Go to rest
          _setPhase(TimerPhase.rest, _config!.restDurationSeconds);
        }
        break;

      case TimerPhase.rest:
        // Start next round
        _currentRound++;
        _setPhase(TimerPhase.round, _config!.roundDurationSeconds);
        _audioService.playBell();
        break;

      case TimerPhase.finished:
        break;
    }
  }

  void _setPhase(TimerPhase phase, int durationSeconds) {
    _phase = phase;
    _remainingSeconds = durationSeconds;
    _totalPhaseSeconds = durationSeconds;
    _lastWarningBeepSecond = -1;
    // When the timer is actively ticking, the new phase gets its own
    // deadline. When paused, remainder is recalculated on resume().
    if (_timer != null && _timer!.isActive) {
      _phaseEndsAt = DateTime.now().add(Duration(seconds: durationSeconds));
    }
  }

  void _reset() {
    _timer?.cancel();
    _phaseEndsAt = null;
    _lastWarningBeepSecond = -1;
    _phase = TimerPhase.preparation;
    _currentRound = 1;
    _remainingSeconds = _config?.prepDurationSeconds ?? 0;
    _totalPhaseSeconds = _config?.prepDurationSeconds ?? 0;
    _isRunning = false;
    _isPaused = false;
    _hasStarted = false;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
