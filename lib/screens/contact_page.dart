import 'package:flutter/material.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';



// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---






// ==========================================
// 1. THE SHELL
// ==========================================

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: PageWithFooter(
        child: ListenableBuilder(
          listenable: themeProvider,
          builder: (context, _) {
            final isDark = themeProvider.isDarkMode;
            final titleColor = isDark ? Colors.white : Colors.black87;
            final textColor = isDark ? Colors.white70 : Colors.grey;

            return Padding(
              padding: const EdgeInsets.all(25.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: isDark ? themeProvider.darkGreyBoxColor : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? themeProvider.darkGreyBorder : Colors.grey.shade300,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 80,
                      color: isDark ? Colors.amber : Colors.amber.shade700,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      "Need Help?",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.amber : Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "If you have questions about a withdrawal, an ad campaign, or need to report a bug, please reach out!",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 15, color: textColor),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.black26 : Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(
                          color: isDark ? Colors.amber.withValues(alpha: 0.3) : Colors.amber.shade200,
                          width: 2,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Email Support",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.amber : Colors.amber.shade700,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "goldenpaw.dogeadmin@gmail.com",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: titleColor,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "We aim to respond to all inquiries within 24-48 hours.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: textColor),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black87,
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Back",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// ⏱️ PTC AD TIMER DIALOG
// ==========================================


