import 'dart:async';

class PetEvents {
  static final StreamController<String> _trickController =
      StreamController<String>.broadcast();
  static Stream<String> get trickStream => _trickController.stream;

  static final StreamController<bool> _sleepController =
      StreamController<bool>.broadcast();
  static Stream<bool> get sleepStream => _sleepController.stream;

  static final StreamController<String> _equipBallController =
      StreamController<String>.broadcast();
  static Stream<String> get equipBallStream => _equipBallController.stream;

  static final StreamController<void> _refreshController =
      StreamController<void>.broadcast();
  static Stream<void> get refreshStream => _refreshController.stream;

  static final StreamController<String> _reactionController =
      StreamController<String>.broadcast();
  static Stream<String> get reactionStream => _reactionController.stream;

  static void performTrick(String trickName) {
    _trickController.add(trickName);
  }

  static void toggleSleep(bool sleep) {
    _sleepController.add(sleep);
  }

  static void equipBall(String color) {
    _equipBallController.add(color);
  }

  static void notifyStatusChanged({String? reactionEmoji}) {
    _refreshController.add(null);
    if (reactionEmoji != null && reactionEmoji.isNotEmpty) {
      _reactionController.add(reactionEmoji);
    }
  }
}
