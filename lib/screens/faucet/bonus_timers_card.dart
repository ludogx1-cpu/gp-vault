import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../src/user_provider.dart';
import '../../src/theme_provider.dart';
import '../../api_constants.dart';
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
                          color: Colors.amber,
                          width: 0.5,
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
                          const SizedBox(height: 15),
                          const Text(
                            "Support Sponsors (0.004 DOGE) for extra rewards & XP!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canClaimBonus
                                    ? Colors.amber
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              onPressed: canClaimBonus
                                  ? () {
                                      final sponsorUri = kIsWeb
                                          ? Uri.base.resolve('sponsors.html')
                                          : Uri.parse('https://goldenpaw.dog/sponsors.html');
                                      launchUrl(sponsorUri);
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) =>
                                            BonusTimerDialog(
                                              endpoint: '${ApiConstants.baseUrl}/claim-bonus-sponsor',
                                              targetUrl: sponsorUri.toString(),
                                            ),
                                      );
                                    }
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Watch the Ecosystem Video (0.003 DOGE) for extra rewards & XP!",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: canClaimEcoVideo
                                    ? Colors.red.shade600
                                    : Colors.grey,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              onPressed: canClaimEcoVideo
                                  ? () {
                                      launchUrl(Uri.parse('https://www.youtube.com/watch?v=_P9YSHwbcC0'));
                                      showDialog(
                                        barrierDismissible: false,
                                        context: context,
                                        builder: (context) =>
                                            BonusTimerDialog(
                                              durationSeconds: 30,
                                              endpoint: '${ApiConstants.baseUrl}/claim-ecosystem-video',
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
