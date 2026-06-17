import 'smart_fallback_ad.dart';
import 'package:pointer_interceptor/pointer_interceptor.dart';
import 'package:web/web.dart' as web;
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class InterstitialAdDialog extends StatefulWidget {
  const InterstitialAdDialog({super.key});
  @override
  State<InterstitialAdDialog> createState() => _InterstitialAdDialogState();
}

class _InterstitialAdDialogState extends State<InterstitialAdDialog> {
  int _timeLeft = 6;
  Timer? _timer;
  final int _seed = Random().nextInt(10000);

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        if (mounted) setState(() => _timeLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        width: 350,
        height: 450,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Sponsor Advertisement",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 15),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('ads')
                    .where('slot_id', isEqualTo: 'interstitial')
                    .snapshots(),
                builder: (context, snapshot) {
                  Widget content;
                  if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                    final now = DateTime.now();
                    var activeAds = snapshot.data!.docs.where((doc) {
                      String expiresAtStr =
                          (doc.data() as Map<String, dynamic>)['expires_at'] ??
                          '';
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
                          child: Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.amber, width: 2),
                              image: DecorationImage(
                                image: NetworkImage(adData['image_url']),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        );
                      } else {
                        content = const SmartFallbackAd(
                          width: 300,
                          height: 250,
                        );
                      }
                    } else {
                      content = const SmartFallbackAd(width: 300, height: 250);
                    }
                  } else {
                    content = const SmartFallbackAd(width: 300, height: 250);
                  }

                  return PointerInterceptor(child: content);
                },
              ),
            ),
            const SizedBox(height: 20),
            if (_timeLeft > 0)
              Text(
                "You can claim in $_timeLeft seconds...",
                style: const TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              )
            else
              PointerInterceptor(
                child: SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).pop(true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      "CONTINUE TO CLAIM",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
