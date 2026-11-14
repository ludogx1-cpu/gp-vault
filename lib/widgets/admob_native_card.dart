import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../src/admob_service.dart';
import '../src/theme_provider.dart';

class AdMobNativeCard extends StatefulWidget {
  final TemplateType templateType;
  final double? height;

  const AdMobNativeCard({
    super.key,
    this.templateType = TemplateType.medium,
    this.height,
  });

  @override
  State<AdMobNativeCard> createState() => _AdMobNativeCardState();
}

class _AdMobNativeCardState extends State<AdMobNativeCard> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    // Ads may only be requested once ad consent has been handled.
    if (AdMobService.adsReady.value) {
      _loadNativeAd();
    } else {
      AdMobService.adsReady.addListener(_onAdsReady);
    }
  }

  void _onAdsReady() {
    if (!AdMobService.adsReady.value) return;
    AdMobService.adsReady.removeListener(_onAdsReady);
    if (mounted && _nativeAd == null) _loadNativeAd();
  }

  void _loadNativeAd() {
    if (!AdMobService.isSupported || !AdMobService.adsReady.value) return;

    final isDark = themeProvider.isDarkMode;

    _nativeAd = NativeAd(
      adUnitId: AdMobService.activeNativeAdUnitId,
      request: const AdRequest(),
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('AdMob Native ad failed to load: $error');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
              _nativeAd = null;
            });
          }
        },
      ),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: widget.templateType,
        mainBackgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: Colors.amber.shade700,
          style: NativeTemplateFontStyle.bold,
          size: 15.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? Colors.white : Colors.black87,
          style: NativeTemplateFontStyle.bold,
          size: 15.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          size: 13.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
          size: 12.0,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    AdMobService.adsReady.removeListener(_onAdsReady);
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AdMobService.isSupported || !_isAdLoaded || _nativeAd == null) {
      return const SizedBox.shrink();
    }

    final defaultHeight =
        widget.templateType == TemplateType.small ? 90.0 : 330.0;
    final containerHeight = widget.height ?? defaultHeight;

    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        constraints: BoxConstraints(
          maxWidth: 420,
          minHeight: containerHeight,
          maxHeight: containerHeight,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: themeProvider.isDarkMode
                ? const Color(0xFF2C2C2C)
                : Colors.grey.shade300,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AdWidget(ad: _nativeAd!),
        ),
      ),
    );
  }
}
