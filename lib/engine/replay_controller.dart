import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/candle_model.dart';

enum ReplaySpeed { x1, x2, x5, x10, x50 }

class ReplayController extends ChangeNotifier {
  List<Candle> _fullHistory = [];
  int _currentIndex = 0;
  bool _isPlaying = false;
  ReplaySpeed _speed = ReplaySpeed.x1;
  Timer? _timer;

  // Output stream (simulating WebSocket stream)
  final StreamController<Candle> _candleStreamController =
      StreamController.broadcast();
  Stream<Candle> get candleStream => _candleStreamController.stream;

  // State Getters
  int get currentIndex => _currentIndex;
  int get totalCandles => _fullHistory.length;
  List<Candle> get fullHistory => _fullHistory; // [NEW] Exposed for Sandbox
  bool get isPlaying => _isPlaying;
  ReplaySpeed get speed => _speed;

  double get progress => totalCandles == 0 ? 0.0 : _currentIndex / totalCandles;

  DateTime? get currentDate =>
      _currentIndex >= 0 && _currentIndex < _fullHistory.length
          ? _fullHistory[_currentIndex].date
          : null;

  void loadHistory(List<Candle> history) {
    _fullHistory = history;
    _currentIndex = 0;
    _isPlaying = false;
    _timer?.cancel();
    notifyListeners();
  }

  void play() {
    if (_isPlaying) return;
    if (_currentIndex >= _fullHistory.length - 1) {
      _currentIndex = 0;
    }
    _isPlaying = true;
    _startTimer();
    notifyListeners();
  }

  void pause() {
    if (!_isPlaying) return;
    _isPlaying = false;
    _timer?.cancel();
    notifyListeners();
  }

  void togglePlayPause() {
    if (_isPlaying) {
      pause();
    } else {
      play();
    }
  }

  void setSpeed(ReplaySpeed newSpeed) {
    if (_speed == newSpeed) return;
    _speed = newSpeed;
    if (_isPlaying) {
      _startTimer(); // Restart with new speed
    }
    notifyListeners();
  }

  void seekTo(double progress) {
    if (_fullHistory.isEmpty) return;
    // Pause during seek to prevent race conditions
    pause();

    int index = (progress * (_fullHistory.length - 1)).round();
    _currentIndex = index.clamp(0, _fullHistory.length - 1);

    // IMPORTANT: When seeking, the consumer must reset its state.
    // We notify listeners, and the Consumer (ChartController) should
    // likely pull `historySoFar` to repopulate.

    notifyListeners();

    // If it was playing, we could auto-resume, but standard UX is usually to stay paused after seek.
    // if (wasPlaying) play();
  }

  void _startTimer() {
    _timer?.cancel();
    int speedMs = 1000;
    switch (_speed) {
      case ReplaySpeed.x1:
        speedMs = 1000;
        break;
      case ReplaySpeed.x2:
        speedMs = 500;
        break;
      case ReplaySpeed.x5:
        speedMs = 200;
        break;
      case ReplaySpeed.x10:
        speedMs = 100;
        break;
      case ReplaySpeed.x50:
        speedMs = 20;
        break;
    }

    _timer = Timer.periodic(Duration(milliseconds: speedMs), (timer) {
      _tick();
    });
  }

  void stepForward() {
    pause();
    _tick();
  }

  void stepBack() {
    pause();
    if (_currentIndex > 0) {
      _currentIndex--;
      // Notifying listeners will trigger UI update.
      // The ChartController will re-read `historySoFar`.
      notifyListeners();
    }
  }

  void jumpToStart() {
    pause();
    _currentIndex = 0;
    notifyListeners();
  }

  void jumpToEnd() {
    pause();
    _currentIndex = _fullHistory.length - 1;
    notifyListeners();
  }

  void _tick() {
    if (_currentIndex >= _fullHistory.length) {
      pause();
      return;
    }

    final candle = _fullHistory[_currentIndex];
    // Emit the new candle for real-time listeners (like ChartController or Strategy)
    _candleStreamController.add(candle);

    _currentIndex++;
    notifyListeners();
  }

  // Method to get current historical slice for initial load or seek/reset
  List<Candle> get historySoFar => _fullHistory.sublist(0, _currentIndex);

  @override
  void dispose() {
    _timer?.cancel();
    _candleStreamController.close();
    super.dispose();
  }
}
