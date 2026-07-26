import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../src/user_provider.dart';
import '../../src/theme_provider.dart';
import '../../widgets/bonus_timer_dialog.dart';

class BonusTimersCard extends StatelessWidget {
  const BonusTimersCard({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final user = authSnapshot.data;
        if (user == null) {
          return const SizedBox.shrink();
        }

        return Consumer<UserProvider>(
          builder: (context, userProvider, _) {
            bool canClaimBonus = true;
            int minutesLeftBonus = 0;
            
            bool canClaimEcoVideo = true;
            int minutesLeftEcoVideo = 0;

            final userData = userProvider.userData;
            if (userData != null) {
              final Timestamp? lastClaimBonus = userData['last_bonus_sponsor_claim'];
              if (lastClaimBonus != null) {
                final difference = DateTime.now().difference(lastClaimBonus.toDate());
                if (difference.inMinutes < 15) { // The backend is 15 minutes!
                  canClaimBonus = false;
                  minutesLeftBonus = 15 - difference.inMinutes;
                }
              }

              final Timestamp? lastEcoVideo = userData['last_ecosystem_video_claim'];
              if (lastEcoVideo != null) {
                final difference = DateTime.now().difference(lastEcoVideo.toDate());
                if (difference.inMinutes < 30) { // The backend is 30 minutes!
                  canClaimEcoVideo = false;
                  minutesLeftEcoVideo = 30 - difference.inMinutes;
                }
              }
            }
            return ListenableBuilder(
              listenable: themeProvider,
              builder: (context, _) {
                final isDark = themeProvider.isDarkMode;
                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 800),
                      padding: const EdgeInsets.all(20),
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
                            "🌟 Support Golden Paw & Boost the Faucet 🌟",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            "Support Sponsors (0.004 DOGE) or Watch the\nEcosystem Video (0.003 DOGE) for extra rewards & XP!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 20),
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
                                  borderRadius: BorderRadius.circular(
                                    10,
                                  ),
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
                                      launchUrl(Uri.base.resolve('sponsors.html'));
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
                          const SizedBox(height: 15),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canClaimEcoVideo
                                    ? Colors.red.shade600
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              icon: Icon(
                                canClaimEcoVideo
                                    ? Icons.play_circle_fill
                                    : Icons.lock_clock,
                              ),
                              label: Text(
                                canClaimEcoVideo
                                    ? 'WATCH: GOLDEN PAW ECOSYSTEM'
                                    : 'COOLDOWN: $minutesLeftEcoVideo MIN',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 1.1,
                                ),
                              ),
                              onPressed: canClaimEcoVideo
                                  ? () {
                                      launchUrl(Uri.parse('https://www.youtube.com/watch?v=_P9YSHwbcC0'));
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) =>
                                            const BonusTimerDialog(
                                              durationSeconds: 30,
                                              endpoint: 'https://golden-paw-vault.onrender.com/claim-ecosystem-video',
                                              targetUrl: 'https://www.youtube.com/watch?v=_P9YSHwbcC0',
                                            ),
                                      );
                                    }
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
