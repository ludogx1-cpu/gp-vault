import '../screens/affiliate_links_page.dart';
import 'package:web/web.dart' as web;
import '../screens/ad_hub_page.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../src/theme_provider.dart';

class SmartFallbackAd extends StatelessWidget {
  final double width;
  final double height;

  const SmartFallbackAd({super.key, required this.width, required this.height});

  IconData _getAdminIcon(String name) {
    switch (name) {
      case 'wallet':
        return Icons.account_balance_wallet;
      case 'ptc':
        return Icons.ads_click;
      case 'faucet':
        return Icons.water_drop;
      case 'mining':
        return Icons.cloud_sync;
      default:
        return Icons.star;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('partners').snapshots(),
      builder: (context, snapshot) {
        return ListenableBuilder(
          listenable: themeProvider,
          builder: (context, _) {
            final isDark = themeProvider.isDarkMode;

            // 1. 10% chance to show the "Buy an Ad" banner
            if (Random().nextInt(100) < 10) {
              return InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdHubPage()),
                ),
                child: Container(
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: isDark
                        ? themeProvider.darkGreyBoxColor
                        : Colors.orange.shade50,
                    border: isDark
                        ? Border.all(color: themeProvider.darkGreyBorder)
                        : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.campaign,
                        color: isDark ? Colors.amber : Colors.orange,
                        size: height > 100 ? 40 : 24,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "Get your ad placed here!",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: height > 100 ? 14 : 12,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        "Click to visit Buy Ads",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: height > 100 ? 11 : 9,
                          color: isDark
                              ? Colors.white70
                              : Colors.orange.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // 2. Otherwise, load the hybrid Affiliate Partners list!
            List<Map<String, dynamic>> allPartners = [];

            for (var p in partnerList) {
              allPartners.add({
                'title': p.title,
                'url': p.url,
                'iconName': 'star',
                'colorHex': p.color.toARGB32().toRadixString(16),
                '_isHardcoded': true,
                '_iconData': p.icon,
              });
            }

            if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
              for (var doc in snapshot.data!.docs) {
                allPartners.add(doc.data() as Map<String, dynamic>);
              }
            }

            if (allPartners.isEmpty) {
              return SizedBox(width: width, height: height);
            }

            var data = allPartners[Random().nextInt(allPartners.length)];
            Color iconColor = data['_isHardcoded'] == true
                ? Color(int.parse(data['colorHex'] ?? 'ffffc107', radix: 16))
                : Colors.amber;
            IconData displayIcon = data['_isHardcoded'] == true
                ? data['_iconData']
                : _getAdminIcon(data['iconName'] ?? '');

            return InkWell(
              onTap: () => web.window.open(data['url'] ?? '', '_blank'),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: isDark
                      ? themeProvider.darkGreyBoxColor
                      : Colors.amber.shade50,
                  border: isDark
                      ? Border.all(color: themeProvider.darkGreyBorder)
                      : null,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        displayIcon,
                        color: iconColor,
                        size: height > 100 ? 40 : 24,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        data['title'] ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: height > 100 ? 14 : 12,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        "Partner Promotion",
                        style: TextStyle(
                          fontSize: height > 100 ? 10 : 9,
                          color: isDark ? Colors.white54 : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
