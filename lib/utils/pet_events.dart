import 'dart:async';

class PetEvents {
  static final StreamController<String> _trickController = StreamController<String>.broadcast();
  static Stream<String> get trickStream => _trickController.stream;

  static void performTrick(String trickName) {
    _trickController.add(trickName);
  }
}
