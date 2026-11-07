import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
                          InkWell(
                            onTap: () => launchUrl(Uri.parse('mailto:goldenpaw.dogeadmin@gmail.com')),
                            child: Text(
                              "goldenpaw.dogeadmin@gmail.com",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.amber.shade200 : Colors.blue.shade700,
                                decoration: TextDecoration.underline,
                              ),
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
                    const SizedBox(height: 25),
                    Text(
                      "Official Channels & Studios",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.amber : Colors.amber.shade700,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse('https://x.com/ludogx101'),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text("X (@ludogx101)"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: titleColor,
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse('https://www.instagram.com/goldenpawdoge'),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              gradient: const RadialGradient(
                                center: Alignment(-0.8, 0.8),
                                radius: 1.2,
                                colors: [
                                  Color(0xFFFFDC80),
                                  Color(0xFFF77737),
                                  Color(0xFFFD1D1D),
                                  Color(0xFFE1306C),
                                  Color(0xFF833AB4),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Center(
                              child: Icon(Icons.camera_alt, size: 12, color: Colors.white),
                            ),
                          ),
                          label: const Text("Instagram"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: titleColor,
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse('https://www.tiktok.com/@goldenpawstudios'),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.tiktok, size: 16),
                          label: const Text("TikTok"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: titleColor,
                            side: BorderSide(color: isDark ? Colors.white24 : Colors.grey.shade400),
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => launchUrl(
                            Uri.parse('https://goldenpaw.dog/studios'),
                            mode: LaunchMode.externalApplication,
                          ),
                          icon: const Icon(Icons.pets, size: 16, color: Colors.amber),
                          label: const Text("Golden Paw Studios ↗"),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.amber,
                            side: const BorderSide(color: Colors.amber),
                          ),
                        ),
                      ],
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


