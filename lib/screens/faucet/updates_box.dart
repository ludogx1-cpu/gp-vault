import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../src/theme_provider.dart';

class UpdatesBox extends StatelessWidget {
  const UpdatesBox({super.key});

  static const List<Map<String, String>> pinnedUpdates = [
    {
      'title': 'Need Help or Found an Issue? 🛠️',
      'message': "If you are having any trouble with anything on the site, or spotted something we might have missed, please don't hesitate to get in touch with us! Our contact details are located in the footer.",
    },
    {
      'title': 'TimeWall Payout Update & 2x Pet XP Boost ⏳',
      'message': "TimeWall payouts are temporarily suspended while Golden Paw completes standard background checks. You can still complete tasks and earn from TimeWall, and Golden Paw's faucet, ads, and daily promos are 100% active and withdrawable! To thank you for your patience, all pets get 2x XP this week!",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('updates')
          .orderBy('timestamp', descending: true)
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        final List<Map<String, dynamic>> allUpdates = [
          ...pinnedUpdates,
        ];

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data['title'] ?? '';
            if (!pinnedUpdates.any((p) => p['title'] == title)) {
              allUpdates.add(data);
            }
          }
        }

        return ListenableBuilder(
          listenable: themeProvider,
          builder: (context, _) {
            final isDark = themeProvider.isDarkMode;
            return Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 800),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? themeProvider.darkGreyBoxColor : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: Colors.amber,
                  width: 0.5,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.campaign, color: isDark ? Colors.blueAccent : Colors.blue.shade800),
                      const SizedBox(width: 8),
                      Text(
                        "LATEST UPDATES",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: isDark ? Colors.blueAccent : Colors.blue.shade900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 250),
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: Column(
                          children: allUpdates.asMap().entries.map((entry) {
                            var data = entry.value;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 15, right: 10, left: 10),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Text(
                                    data['title'] ?? 'Update',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    data['content'] ?? (data['message'] ?? ''),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: isDark ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "For support, contact: goldenpaw.dogeadmin@gmail.com",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
