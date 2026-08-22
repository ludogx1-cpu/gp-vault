import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class TimewallQuickLinksWidget extends StatelessWidget {
  final String uid;

  const TimewallQuickLinksWidget({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 15),
        const Text(
          "TimeWall Direct Links (Opens in new tab):",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: [
            ActionChip(
              backgroundColor: Colors.green.shade100,
              label: const Text("📝 Tasks", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              onPressed: () => launchUrl(Uri.parse('https://timewall.io/users/login?oid=00b4588ba45c68fb&uid=$uid&tab=tasks')),
            ),
            ActionChip(
              backgroundColor: Colors.blue.shade100,
              label: const Text("🖱️ Clicks", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              onPressed: () => launchUrl(Uri.parse('https://timewall.io/users/login?oid=00b4588ba45c68fb&uid=$uid&tab=clicks')),
            ),
            ActionChip(
              backgroundColor: Colors.purple.shade100,
              label: const Text("🎮 Games", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
              onPressed: () => launchUrl(Uri.parse('https://timewall.io/users/login?oid=00b4588ba45c68fb&uid=$uid&tab=games')),
            ),
            ActionChip(
              backgroundColor: Colors.orange.shade100,
              label: const Text("💎 BuyPoints", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
              onPressed: () => launchUrl(Uri.parse('https://timewall.io/users/login?oid=00b4588ba45c68fb&uid=$uid&tab=buypoints')),
            ),
          ],
        ),
      ],
    );
  }
}
