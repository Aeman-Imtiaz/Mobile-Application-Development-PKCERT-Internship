import 'package:google_mobile_ads/google_mobile_ads.dart';
class AdService {
  // Google's official TEST Ad Unit IDs — safe to use during development.
  // Replace these with your real IDs (saved in Notepad) only when publishing.
  static const String bannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String rewardedAdUnitId = 'ca-app-pub-3940256099942544/5224354917';
  static const String interstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  static Future<void> init() async {
    await MobileAds.instance.initialize();
  }
}