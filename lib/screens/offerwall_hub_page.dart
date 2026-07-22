import '../widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';



// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---






// ==========================================
// 1. THE SHELL
// ==========================================

class OfferwallHubPage extends StatefulWidget {
  const OfferwallHubPage({super.key});

  @override
  State<OfferwallHubPage> createState() => _OfferwallHubPageState();
}

class _OfferwallHubPageState extends State<OfferwallHubPage> {
  // Tracks which network engine is currently loaded into the container view
  String selectedNetwork = "NONE";

  // Generates the personalized, cryptographically tracked wall link for each user
  String getOfferwallUrl(String provider, String uid) {
    if (provider == "MONLIX") {
      // ⚠️ Replace 'YOUR_MONLIX_ID' with your real API ID from your Monlix account
      return "https://offers.monlix.com/wall?appid=YOUR_MONLIX_ID&userid=$uid";
    }
    if (provider == "LOOTABLY") {
      // ⚠️ Replace 'YOUR_LOOTABLY_ID' with your real API ID from your Lootably account
      return "https://wall.lootably.com/web/YOUR_LOOTABLY_ID/$uid";
    }
    if (provider == "BITCOTASKS") {
      return "https://bitcotasks.com/offerwall/6xwmdur28o2s2jx3y4nj4ldt6jx5u9/$uid";
    }
    if (provider == "TIMEWALL") {
      return "https://timewall.io/users/login?oid=00b4588ba45c68fb&uid=$uid";
    }
    return "https://google.com"; // Fallback placeholder
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return AppScaffold(
        appBar: AppBar(
          title: const Text('Offerwalls'),
          backgroundColor: Colors.amber,
        ),
        body: const Center(
          child: Text(
            "Please log in to view high-paying tasks!",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    }

    return AppScaffold(
      appBar: AppBar(
        title: const Text(
          'Offerwall Tasks',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.amber,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.amber),
            );
          }

          var userData = snapshot.data?.data() as Map<String, dynamic>?;
          double pendingBalance = (userData?['pending_offer_balance'] ?? 0.0)
              .toDouble();
          int xp = (userData?['xp'] ?? 0).toInt();
          int level = sqrt(xp / 100).floor();

          // 🔒 Level Protection Gate
          if (level < 3) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_person, size: 70, color: Colors.grey),
                    const SizedBox(height: 20),
                    const Text(
                      "Offerwalls Locked!",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "To prevent fraud, you must reach Level 3 before unlocking premium offers. You are currently Level $level.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 💼 Balance Staging Display Card
                Card(
                  color: Colors.amber.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                    side: BorderSide(color: Colors.amber.shade200),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Pending Offer Yield:",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              "Held for verification safety",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "${pendingBalance.toStringAsFixed(4)} DOGE",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 15),

                // ⚠️ Quarantine Policy Banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 18),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Safety Policy: Offerwall rewards remain pending for 7 days to clear network anti-fraud sweeps before routing to your main balance.",
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.blueGrey,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // 🌐 PROVIDER SELECTION INTERFACE
                Text(
                  "Select a Task Provider Network:",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Monlix Selection Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedNetwork == "MONLIX"
                              ? Colors.orange
                              : Colors.grey.shade200,
                          foregroundColor: selectedNetwork == "MONLIX"
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: const Icon(Icons.rocket_launch),
                        label: const Text(
                          "Monlix Engine",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () =>
                            setState(() => selectedNetwork = "MONLIX"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // Lootably Selection Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedNetwork == "LOOTABLY"
                              ? Colors.purple
                              : Colors.grey.shade200,
                          foregroundColor: selectedNetwork == "LOOTABLY"
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: const Icon(Icons.flash_on),
                        label: const Text(
                          "Lootably Core",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () =>
                            setState(() => selectedNetwork = "LOOTABLY"),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 15),
                Row(
                  children: [
                    // BitcoTasks Selection Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedNetwork == "BITCOTASKS"
                              ? Colors.blue
                              : Colors.grey.shade200,
                          foregroundColor: selectedNetwork == "BITCOTASKS"
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: const Icon(Icons.task_alt),
                        label: const Text(
                          "BitcoTasks",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () =>
                            setState(() => selectedNetwork = "BITCOTASKS"),
                      ),
                    ),
                    const SizedBox(width: 15),
                    // TimeWall Selection Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedNetwork == "TIMEWALL"
                              ? Colors.green
                              : Colors.grey.shade200,
                          foregroundColor: selectedNetwork == "TIMEWALL"
                              ? Colors.white
                              : Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                        ),
                        icon: const Icon(Icons.timelapse),
                        label: const Text(
                          "TimeWall",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        onPressed: () =>
                            setState(() => selectedNetwork = "TIMEWALL"),
                      ),
                    ),
                  ],
                ),
                
                // 🚀 TIMEWALL QUICK LINKS 🚀
                if (selectedNetwork == "TIMEWALL") ...[
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
                        onPressed: () => launchUrl(Uri.parse('https://timewall.io/users/login?oid=00b4588ba45c68fb&uid=${user.uid}&tab=tasks')),
                      ),
                      ActionChip(
                        backgroundColor: Colors.blue.shade100,
                        label: const Text("🖱️ Clicks", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        onPressed: () => launchUrl(Uri.parse('https://timewall.io/users/login?oid=00b4588ba45c68fb&uid=${user.uid}&tab=clicks')),
                      ),
                      ActionChip(
                        backgroundColor: Colors.purple.shade100,
                        label: const Text("🎮 Games", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
                        onPressed: () => launchUrl(Uri.parse('https://timewall.io/users/login?oid=00b4588ba45c68fb&uid=${user.uid}&tab=games')),
                      ),
                      ActionChip(
                        backgroundColor: Colors.orange.shade100,
                        label: const Text("💎 BuyPoints", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange)),
                        onPressed: () => launchUrl(Uri.parse('https://timewall.io/users/login?oid=00b4588ba45c68fb&uid=${user.uid}&tab=buypoints')),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 30),

                // 🖼️ DYNAMIC RAW HTML IFRAME CONTAINER CONTEXT
                if (selectedNetwork == "NONE")
                  Container(
                    height: 400,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app, size: 50, color: Colors.grey),
                        SizedBox(height: 10),
                        Text(
                          "Choose a provider network above to initialize your tasks matrix.",
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  )
                else ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Active Matrix: $selectedNetwork",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          fontSize: 13,
                        ),
                      ),
                      TextButton.icon(
                        icon: const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.red,
                        ),
                        label: const Text(
                          "Close Tasks View",
                          style: TextStyle(color: Colors.red, fontSize: 12),
                        ),
                        onPressed: () =>
                            setState(() => selectedNetwork = "NONE"),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // The actual embedded HTML view frame box container
                  Container(
                    height:
                        700, // Allocates a tall sandbox inside your layout for the scrolling offers
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                        color: Colors.amber.shade300,
                        width: 2,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: HtmlElementView.fromTagName(
                      tagName: 'iframe',
                      onElementCreated: (Object element) {
                        // Casts the generated web element dynamically to tweak browser properties
                        final iframe = element as dynamic;
                        iframe.src = getOfferwallUrl(selectedNetwork, user.uid);
                        iframe.style.border = 'none';
                        iframe.style.width = '100%';
                        iframe.style.height = '100%';
                      },
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}


