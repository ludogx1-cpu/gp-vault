import 'smart_fallback_ad.dart';
import 'package:web/web.dart' as web;
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BannerAdPlaceholder extends StatefulWidget {
  final String text;
  const BannerAdPlaceholder({super.key, this.text = ""});

  @override
  State<BannerAdPlaceholder> createState() => _BannerAdPlaceholderState();
}

class _BannerAdPlaceholderState extends State<BannerAdPlaceholder> {
  static const double _bannerWidth = 970;
  static const double _bannerHeight = 120;
  final int _seed = Random().nextInt(10000);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ads')
          .where('slot_id', isEqualTo: 'global_banner')
          .snapshots(),
      builder: (context, snapshot) {
        Widget content;

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final now = DateTime.now();
          var activeAds = snapshot.data!.docs.where((doc) {
            String expiresAtStr =
                (doc.data() as Map<String, dynamic>)['expires_at'] ?? '';
            if (expiresAtStr.isEmpty) return false;
            DateTime? expiresAt = DateTime.tryParse(expiresAtStr);
            return expiresAt != null && expiresAt.isAfter(now);
          }).toList();

          if (activeAds.isNotEmpty) {
            var adData =
                activeAds[_seed % activeAds.length].data()
                    as Map<String, dynamic>;
            if ((adData['image_url'] ?? '').isNotEmpty) {
              content = InkWell(
                onTap: () {
                  if ((adData['target_url'] ?? '').isNotEmpty) {
                    web.window.open(adData['target_url'], '_blank');
                  }
                },
                child: Image.network(
                  adData['image_url'],
                  fit: BoxFit.cover,
                  width: _bannerWidth,
                  height: _bannerHeight,
                ),
              );
            } else {
              content = const SmartFallbackAd(
                width: _bannerWidth,
                height: _bannerHeight,
              );
            }
          } else {
            content = const SmartFallbackAd(
              width: _bannerWidth,
              height: _bannerHeight,
            );
          }
        } else {
          content = const SmartFallbackAd(
            width: _bannerWidth,
            height: _bannerHeight,
          );
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _bannerWidth),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: SizedBox(
                width: _bannerWidth,
                height: _bannerHeight,
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }
}
