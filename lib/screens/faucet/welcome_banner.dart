import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../src/theme_provider.dart';
import '../../widgets/animated_hover_card.dart';

class WelcomeBanner extends StatelessWidget {
  const WelcomeBanner({super.key});

  void _openFaucetPayLink() {
    launchUrl(Uri.parse('https://faucetpay.io/?r=5173106'));
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: themeProvider,
      builder: (context, _) {
        final isDark = themeProvider.isDarkMode;
        return AnimatedHoverCard(
          backgroundColor: isDark
              ? themeProvider.darkGreyBoxColor
              : Colors.amber[50],
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDark
                ? themeProvider.darkGreyBorder
                : Colors.amber.shade200,
            width: 1,
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        "🌟 Welcome to the Golden Paw Faucet! 🌟",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  "We make earning crypto simple. Whether you are here to grab some quick Dogecoin or want to build a long-term balance, you are in the right place.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? Colors.white70 : Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      "•  Enter your Dogecoin address below and claim your free Doge instantly to FaucetPay.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white70
                            : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "• Optionally toggle the switch to Hold it and move it to the Staking pool to earn passive rewards.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark
                            ? Colors.white70
                            : Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      alignment: WrapAlignment.center,
                      runSpacing: 4,
                      children: [
                        Text(
                          "•  Withdraw directly to ",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white70
                                : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        InkWell(
                          onTap: _openFaucetPayLink,
                          child: const Text(
                            "FaucetPay",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          " whenever you are ready.",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? Colors.white70
                                : Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
