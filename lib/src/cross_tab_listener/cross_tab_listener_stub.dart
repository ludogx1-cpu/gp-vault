abstract class CrossTabListener {
  void setup(Function(String) onMessage);
  void cancel();
  void setBrowserTitle(String title);
  bool hasFocus();
  void renderHCaptcha();
  void renderTurnstile();
  void injectAdsterraPopunder(String scriptUrl);
  void removeAdsterraPopunder(String scriptUrl);
}

CrossTabListener getCrossTabListener() => throw UnsupportedError('Cannot create a CrossTabListener');
