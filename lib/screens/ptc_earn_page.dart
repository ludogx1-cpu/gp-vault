import 'package:flutter/material.dart';
import 'dart:async';
import 'package:web/web.dart' as web;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/theme_provider.dart';
import '../widgets/widgets.dart';
import '../widgets/monetag_timer_dialog.dart';

// --- GLOBAL THEME CONSTANTS 🚀 ---


// --- CAPTCHA JS BINDINGS ---






// ==========================================
// 1. THE SHELL
// ==========================================

class PtcEarnPage extends StatefulWidget {
  const PtcEarnPage({super.key});

  @override
  State<PtcEarnPage> createState() => _PtcEarnPageState();
}

class _PtcEarnPageState extends State<PtcEarnPage> {
  Stream<DocumentSnapshot>? _userStream;
  Stream<QuerySnapshot>? _adsStream;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // 🔑 Initialize streams exactly ONCE to prevent Firebase Web crashes
      _userStream = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots();
      _adsStream = FirebaseFirestore.instance
          .collection('ptc_ads')
          .where('clicks_remaining', isGreaterThan: 0)
          .snapshots();
    }
  }

  void _watchAd(
    BuildContext context,
    String adId,
    String targetUrl,
    int duration,
  ) {
    web.window.open(targetUrl, '_blank');
    showDialog(
      barrierDismissible: false,
      context: context,
      builder: (context) => PtcTimerDialog(adId: adId, duration: duration),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null ||
        _userStream == null ||
        _adsStream == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'EARN DOGE (PTC)',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
          ),
          backgroundColor: Colors.amber,
          centerTitle: true,
        ),
        body: const Center(
          child: Text(
            "You must log in to earn from PTC ads!",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontSize: 18,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: const GlobalAppBar(showBackArrow: true),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _userStream,
        builder: (context, userDocSnapshot) {
          bool canClaimBonus = true;
          int minutesLeftBonus = 0;
          bool canClaimMonetag = true;
          int minutesLeftMonetag = 0;

          if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
            var uData = userDocSnapshot.data!.data() as Map<String, dynamic>?;
            
            Timestamp? lastClaimBonus = uData?['last_bonus_sponsor_claim'] as Timestamp?;
            if (lastClaimBonus != null) {
              final now = DateTime.now();
              final difference = now.difference(lastClaimBonus.toDate());
              if (difference.inMinutes < 15) {
                canClaimBonus = false;
                minutesLeftBonus = 15 - difference.inMinutes;
              }
            }

            Timestamp? lastClaimMonetag = uData?['last_monetag_sponsor_claim'] as Timestamp?;
            if (lastClaimMonetag != null) {
              final now = DateTime.now();
              final difference = now.difference(lastClaimMonetag.toDate());
              if (difference.inMinutes < 10) {
                canClaimMonetag = false;
                minutesLeftMonetag = 10 - difference.inMinutes;
              }
            }
          }

          List<String> clickedLast24h = [];
          if (userDocSnapshot.hasData && userDocSnapshot.data!.exists) {
            var uData = userDocSnapshot.data!.data() as Map<String, dynamic>?;
            Map<String, dynamic>? ptcHistory = uData?['ptc_history'] as Map<String, dynamic>?;
            if (ptcHistory != null) {
              final now = DateTime.now();
              ptcHistory.forEach((adId, timestamp) {
                if (timestamp is Timestamp) {
                  if (now.difference(timestamp.toDate()).inHours < 24) {
                    clickedLast24h.add(adId);
                  }
                }
              });
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _adsStream,
            builder: (context, adsSnapshot) {
                  if (adsSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    );
                  }

                  var allAds = adsSnapshot.data?.docs ?? [];

                  // We show all ads, but we grey them out if clickedLast24h.contains(doc.id)
                  // 👑 WRAP THE REST OF THE PAGE IN THE THEME BUILDER
                  return ListenableBuilder(
                    listenable: themeProvider,
                    builder: (context, _) {
                      final isDark = themeProvider.isDarkMode;

                      Widget adContent;
                      if (allAds.isEmpty) {
                        adContent = const Center(
                          child: Text(
                            "No ads available right now. Check back later!",
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      } else {
                        adContent = Column(
                          children: allAds.map((doc) {
                            final adData =
                                doc.data() as Map<String, dynamic>? ?? {};

                            int duration = adData['duration'] as int? ?? 10;
                            double reward = (adData['reward'] as num? ?? 0.002)
                                .toDouble();
                            String title =
                                adData['title'] as String? ??
                                "Sponsored Website";
                            String targetUrl =
                                adData['target_url'] as String? ?? "";

                            bool isClicked = clickedLast24h.contains(doc.id);

                            return Opacity(
                              opacity: isClicked ? 0.5 : 1.0,
                              child: Card(
                                // THEMED AD CARDS
                                color: isDark
                                    ? themeProvider.darkGreyBoxColor
                                    : Colors.white,
                                elevation: isDark ? 0 : 3,
                                margin: const EdgeInsets.only(bottom: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                  side: BorderSide(
                                    color: isDark
                                        ? themeProvider.darkGreyBorder
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(15),
                                  leading: Icon(
                                    Icons.monetization_on,
                                    color: isClicked ? Colors.grey : Colors.amber,
                                    size: 40,
                                  ),
                                  title: Text(
                                    title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: isClicked
                                          ? Colors.grey
                                          : (isDark ? Colors.white : Colors.black87),
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Reward: +${reward.toStringAsFixed(4)} DOGE\nTimer: $duration Seconds",
                                    style: TextStyle(
                                      color: isClicked ? Colors.grey : Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  trailing: ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: isClicked ? Colors.grey : Colors.green,
                                    ),
                                    onPressed: isClicked
                                        ? null
                                        : () => _watchAd(
                                              context,
                                              doc.id,
                                              targetUrl,
                                              duration,
                                            ),
                                    child: Text(
                                      isClicked ? "COOLDOWN" : "VIEW",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        );
                      }

                      return ListView(
                        padding: const EdgeInsets.all(20),
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? themeProvider.darkGreyBoxColor
                                  : (canClaimBonus
                                        ? Colors.amber.shade100
                                        : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isDark
                                    ? themeProvider.darkGreyBorder
                                    : (canClaimBonus
                                          ? Colors.amber.shade400
                                          : Colors.grey.shade400),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "🌟 Support Golden Paw & Earn DOGE 🌟",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  "Stay on the page for 10 seconds to earn\n0.0002 DOGE & 15 XP!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canClaimBonus
                                          ? Colors.amber
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: Icon(
                                      canClaimBonus
                                          ? Icons.card_giftcard
                                          : Icons.lock_clock,
                                    ),
                                    label: Text(
                                      canClaimBonus
                                          ? 'VIEW BONUS SPONSORS'
                                          : 'COOLDOWN: $minutesLeftBonus MIN',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    onPressed: canClaimBonus
                                        ? () {
                                            web.window.open(
                                              '/sponsors.html',
                                              '_blank',
                                            );
                                            showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (context) =>
                                                  const BonusTimerDialog(),
                                            );
                                          }
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? themeProvider.darkGreyBoxColor
                                  : (canClaimMonetag
                                        ? Colors.amber.shade100
                                        : Colors.grey.shade200),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: isDark
                                    ? themeProvider.darkGreyBorder
                                    : (canClaimMonetag
                                          ? Colors.amber.shade400
                                          : Colors.grey.shade400),
                                width: 2,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "✨ View Sponsor & Earn DOGE ✨",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 5),
                                const Text(
                                  "Stay on the page for 30 seconds to earn\n0.0001 DOGE & 10 XP!",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 15),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: canClaimMonetag
                                          ? Colors.amber
                                          : Colors.grey,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: Icon(
                                      canClaimMonetag
                                          ? Icons.star
                                          : Icons.lock_clock,
                                    ),
                                    label: Text(
                                      canClaimMonetag
                                          ? 'VIEW SPONSOR'
                                          : 'COOLDOWN: $minutesLeftMonetag MIN',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 15,
                                        letterSpacing: 1.1,
                                      ),
                                    ),
                                    onPressed: canClaimMonetag
                                        ? () {
                                            web.window.open(
                                              'https://omg10.com/4/11195831',
                                              '_blank',
                                            );
                                            showDialog(
                                              barrierDismissible: false,
                                              context: context,
                                              builder: (context) =>
                                                  const MonetagTimerDialog(),
                                            );
                                          }
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),
                          adContent,
                        ],
                      );
                    },
                  );
            },
          );
        },
      ),
    );
  }
}

// ==========================================
// 🚀 SECRET ADMIN DASHBOARD 🚀
// ==========================================

