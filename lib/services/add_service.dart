import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  InterstitialAd? _interstitialAd;
  int _counter = 0;

  void loadInterstitial() {
    InterstitialAd.load(
      adUnitId: 'YOUR_INTERSTITIAL_ID',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitialAd = ad;
        },
        onAdFailedToLoad: (error) {
          _interstitialAd = null;
        },
      ),
    );
  }

  void showInterstitialIfNeeded() {
    _counter++;

    if (_counter >= 3) {
      _counter = 0;

      if (_interstitialAd != null) {
        _interstitialAd!.show();
        _interstitialAd = null;
        loadInterstitial(); // reload
      }
    }
  }
}