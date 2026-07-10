import 'package:url_launcher/url_launcher.dart';
import 'smart_fallback_ad.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SquareAdPlaceholder extends StatefulWidget {
  final String slotId;
  const SquareAdPlaceholder({super.key, required this.slotId});
  @override
  State<SquareAdPlaceholder> createState() => _SquareAdPlaceholderState();
}

class _SquareAdPlaceholderState extends State<SquareAdPlaceholder> {
  final int _seed = Random().nextInt(10000);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ads')
          .where('slot_id', isEqualTo: widget.slotId)
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
                    launchUrl(Uri.parse(adData['target_url']));
                  }
                },
                child: Image.network(
                  adData['image_url'],
                  fit: BoxFit.cover,
                  width: 300,
                  height: 250,
                ),
              );
            } else {
              content = const SmartFallbackAd(width: 300, height: 250);
            }
          } else {
            content = const SmartFallbackAd(width: 300, height: 250);
          }
        } else {
          content = const SmartFallbackAd(width: 300, height: 250);
        }

        return SizedBox(
          width: 300,
          height: 250,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: content,
          ),
        );
      },
    );
  }
}
