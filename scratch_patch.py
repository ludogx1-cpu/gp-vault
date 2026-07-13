import sys
import re

def process(filepath, pattern, replacement):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    new_content = re.sub(pattern, replacement, content, flags=re.DOTALL)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)

pattern = r'void _onCaptchaMessage\(String messageStr\) \{.*?\n  \}'
repl1 = '''  void _onCaptchaMessage(String messageStr) {
    if (!mounted) return;
    try {
      if (messageStr.contains("captcha") || messageStr.contains("token")) {
        final data = jsonDecode(messageStr) as Map<String, dynamic>;
        final token = data["token"] ?? data["captcha_token"] ?? data["turnstile_token"];
        if (token != null) {
          setState(() {
            _captchaToken = token;
          });
          if (_showCaptcha && !_isProcessing) {
            _processClaim();
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }'''

repl2 = '''  void _onCaptchaMessage(String messageStr) {
    if (!mounted) return;
    try {
      if (messageStr.contains("start_bonus_timer")) {
        if (!_timerStarted) {
          setState(() {
            _timerStarted = true;
          });
          _stopwatch.start();
          _startTimer();
        }
      } else if (messageStr.contains("captcha") || messageStr.contains("token")) {
        final data = jsonDecode(messageStr) as Map<String, dynamic>;
        final token = data["token"] ?? data["captcha_token"] ?? data["turnstile_token"];
        if (token != null) {
          setState(() {
            _captchaToken = token;
          });
          if (_showCaptcha && !_isProcessing) {
            _processBonusClaim();
          }
        }
      }
    } catch (e) {
      // ignore
    }
  }'''

process('lib/widgets/ptc_timer_dialog.dart', pattern, repl1)
process('lib/widgets/bonus_timer_dialog.dart', pattern, repl2)
