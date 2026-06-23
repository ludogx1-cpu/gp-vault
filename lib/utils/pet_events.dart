import 'dart:async';

class PetEvents {
  static final StreamController<String> _trickController = StreamController<String>.broadcast();
  static Stream<String> get trickStream => _trickController.stream;

  static final StreamController<bool> _sleepController = StreamController<bool>.broadcast();
  static Stream<bool> get sleepStream => _sleepController.stream;

  static void performTrick(String trickName) {
    _trickController.add(trickName);
  }

  static void toggleSleep(bool sleep) {
    _sleepController.add(sleep);
  }
}
