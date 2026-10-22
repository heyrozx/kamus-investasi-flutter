import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

enum StatusAd { initial, loaded }

enum BannerPlacement {
  detailDictionary,
  bookmarkPage,
  historyPage,
  alphabetsPage
}

class BannerAdWidget extends StatefulWidget {
  final BannerPlacement? placement;
  final EdgeInsetsGeometry? margin;

  const BannerAdWidget({
    super.key,
    this.placement,
    this.margin,
  });

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? myBanner;
  StatusAd statusAd = StatusAd.initial;

  BannerAdListener listener() {
    return BannerAdListener(
      onAdLoaded: (Ad ad) {
        if (kDebugMode) print('Ad Loaded');
        setState(() {
          statusAd = StatusAd.loaded;
        });
      },
      onAdFailedToLoad: (Ad ad, LoadAdError error) {
        if (kDebugMode) print('Ad Failed: $error');
        ad.dispose();
      },
    );
  }

  Future<void> initBanner() async {
    final size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(
      MediaQuery.of(context).size.width.toInt(),
    );

    if (size == null) return;

    myBanner = BannerAd(
      adUnitId: getAdUnitId(),
      size: size,
      request: const AdRequest(),
      listener: listener(),
    );

    myBanner!.load();
  }

  @override
  void initState() {
    super.initState();

    // Delay to ensure context is ready for MediaQuery
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initBanner();
    });
  }

  @override
  void dispose() {
    myBanner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (statusAd != StatusAd.loaded || myBanner == null) {
      return const SizedBox();
    }

    return Container(
      margin: widget.margin ?? const EdgeInsets.only(top: 15),
      child: SizedBox(
        width: myBanner!.size.width.toDouble(),
        height: myBanner!.size.height.toDouble(),
        child: AdWidget(ad: myBanner!),
      ),
    );
  }

  String getAdUnitId() {
    const debugUnitID = 'ca-app-pub-3940256099942544/6300978111';

    if (kDebugMode) return debugUnitID;

    switch (widget.placement) {
      case BannerPlacement.detailDictionary:
        return 'ca-app-pub-2465007971338713/1073462187';
      case BannerPlacement.bookmarkPage:
        return 'ca-app-pub-2465007971338713/1237622360';
      case BannerPlacement.historyPage:
        return 'ca-app-pub-2465007971338713/7812571326';
      case BannerPlacement.alphabetsPage:
        return 'ca-app-pub-2465007971338713/5717458272';
      default:
        return debugUnitID;
    }
  }
}
