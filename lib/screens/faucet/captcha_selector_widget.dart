import 'package:flutter/material.dart';
import '../../src/theme_provider.dart';
import '../../widgets/universal_web_view/universal_web_view.dart';
import 'package:provider/provider.dart';

class CaptchaSelectorWidget extends StatelessWidget {
  final String selectedCaptcha;
  final int secondsRemaining;
  final bool isCheckingCooldown;
  final bool captchaLoading;
  final ValueChanged<String?> onChanged;
  final void Function(String) onMessageReceived;
  final VoidCallback onForceRender;

  const CaptchaSelectorWidget({
    super.key,
    required this.selectedCaptcha,
    required this.secondsRemaining,
    required this.isCheckingCooldown,
    required this.captchaLoading,
    required this.onChanged,
    required this.onMessageReceived,
    required this.onForceRender,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Select Captcha:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              decoration: BoxDecoration(
                color: isDark
                    ? themeProvider.darkGreyBoxColor
                    : Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? themeProvider.darkGreyBorder
                      : Colors.amber.shade200,
                ),
              ),
              child: DropdownButton<String>(
                value: selectedCaptcha,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.amber : Colors.black87,
                ),
                elevation: 16,
                style: TextStyle(
                  color: isDark ? Colors.amber : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
                underline: Container(),
                onChanged: secondsRemaining > 0 ? null : onChanged,
                items: const [
                  DropdownMenuItem(value: 'hCaptcha', child: Text('hCaptcha')),
                  DropdownMenuItem(
                    value: 'Turnstile',
                    child: Text('Turnstile'),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Container(
          height: 120,
          width: 340,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.amber, width: 2),
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              if (isCheckingCooldown)
                const Center(
                  child: Text(
                    "Checking Vault Status...",
                    style: TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                )
              else if (selectedCaptcha == 'hCaptcha' && secondsRemaining == 0)
                UniversalWebView.create(
                  viewType: 'hcaptcha-widget',
                  width: 320,
                  height: 90,
                  onMessageReceived: onMessageReceived,
                )
              else if (selectedCaptcha == 'Turnstile' && secondsRemaining == 0)
                UniversalWebView.create(
                  viewType: 'turnstile-widget',
                  width: 320,
                  height: 90,
                  onMessageReceived: onMessageReceived,
                ),
              if (!isCheckingCooldown &&
                  captchaLoading &&
                  secondsRemaining == 0)
                const CircularProgressIndicator(color: Colors.amber),
              if (secondsRemaining > 0)
                Center(
                  child: Text(
                    "Vault Cooling Down...\nWait ${_formatTime(secondsRemaining)} to claim again.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                )
              else if (!isCheckingCooldown && !captchaLoading)
                Positioned(
                  bottom: 4,
                  right: 4,
                  child: IconButton(
                    icon: const Icon(
                      Icons.refresh,
                      size: 24,
                      color: Colors.grey,
                    ),
                    onPressed: onForceRender,
                    tooltip: "Reload Captcha",
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(int seconds) {
    int m = seconds ~/ 60;
    int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
