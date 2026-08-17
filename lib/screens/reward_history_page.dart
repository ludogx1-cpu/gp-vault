import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';

class RewardHistoryPage extends StatefulWidget {
  const RewardHistoryPage({super.key});

  @override
  State<RewardHistoryPage> createState() => _RewardHistoryPageState();
}

class _RewardHistoryPageState extends State<RewardHistoryPage> {
  final User? user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: const GlobalAppBar(),
      body: PageWithFooter(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "Reward Audit History",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: gpBrownText(context, darkColor: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "A complete, immutable log of all your Golden Paw rewards.",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 30),
                  if (user == null)
                    const Center(child: Text("Please log in to view your reward history."))
                  else
                    Expanded(
                      child: StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('reward_audits')
                            .where('userId', isEqualTo: user!.uid)
                            .orderBy('timestamp', descending: true)
                            .limit(100)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                "Error loading history: ${snapshot.error}",
                                style: const TextStyle(color: Colors.red),
                              ),
                            );
                          }
                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return const Center(
                              child: Text("No reward history found."),
                            );
                          }

                          final docs = snapshot.data!.docs;
                          
                          return ListenableBuilder(
                            listenable: themeProvider,
                            builder: (context, _) {
                              final isDark = themeProvider.isDarkMode;
                              return ListView.builder(
                                itemCount: docs.length,
                                itemBuilder: (context, index) {
                                  final data = docs[index].data() as Map<String, dynamic>;
                                  final amount = data['amount'] ?? 0;
                                  final type = data['type'] ?? 'Unknown';
                                  final timestamp = data['timestamp'] as Timestamp?;
                                  final metadata = data['metadata'] as Map<String, dynamic>? ?? {};

                                  DateTime? date;
                                  if (timestamp != null) {
                                    date = timestamp.toDate();
                                  }

                                  String dateStr = date != null
                                      ? DateFormat('MMM dd, yyyy - hh:mm a').format(date)
                                      : 'Processing...';

                                  IconData icon;
                                  Color iconColor;

                                  switch (type) {
                                    case 'faucet_claim':
                                      icon = Icons.water_drop;
                                      iconColor = Colors.blue;
                                      break;
                                    case 'staking_yield':
                                      icon = Icons.bolt;
                                      iconColor = Colors.amber;
                                      break;
                                    case 'ptc_reward':
                                      icon = Icons.ads_click;
                                      iconColor = Colors.green;
                                      break;
                                    case 'offerwall_completion':
                                      icon = Icons.local_offer;
                                      iconColor = Colors.purple;
                                      break;
                                    default:
                                      icon = Icons.monetization_on;
                                      iconColor = Colors.amber;
                                  }

                                  return Card(
                                    color: isDark ? Colors.grey.shade900 : Colors.white,
                                    margin: const EdgeInsets.only(bottom: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      side: BorderSide(color: Colors.amber.shade200, width: 0.5),
                                    ),
                                    child: ListTile(
                                      leading: CircleAvatar(
                                        backgroundColor: iconColor.withValues(alpha: 0.2),
                                        child: Icon(icon, color: iconColor),
                                      ),
                                      title: Text(
                                        "+$amount DOGE",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: isDark ? Colors.green.shade400 : Colors.green.shade700,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          Text(
                                            type.toString().replaceAll('_', ' ').toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                              color: isDark ? Colors.white70 : Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            dateStr,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                      trailing: metadata.isNotEmpty
                                          ? IconButton(
                                              icon: const Icon(Icons.info_outline, color: Colors.grey),
                                              onPressed: () {
                                                showDialog(
                                                  context: context,
                                                  builder: (context) => AlertDialog(
                                                    title: const Text("Reward Details"),
                                                    content: SingleChildScrollView(
                                                      child: Text(metadata.toString()),
                                                    ),
                                                    actions: [
                                                      TextButton(
                                                        onPressed: () => Navigator.of(context).pop(),
                                                        child: const Text("Close"),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
