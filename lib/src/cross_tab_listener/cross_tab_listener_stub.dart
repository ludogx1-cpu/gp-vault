abstract class CrossTabListener {
  void setup(Function(String) onMessage);
  void cancel();
  void setBrowserTitle(String title);
  bool hasFocus();
  void renderHCaptcha();
  void renderTurnstile();
}

CrossTabListener getCrossTabListener() => throw UnsupportedError('Cannot create a CrossTabListener');
