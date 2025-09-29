import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../ads_helper.dart';

/// 広告表示状態に応じてバナー広告を表示/非表示するウィジェット
class ConditionalAdBanner extends StatelessWidget {
  final String adUnitId;
  final double height;
  
  const ConditionalAdBanner({
    Key? key,
    required this.adUnitId,
    this.height = 50.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdsHelper.shouldShowAds(),
      builder: (context, snapshot) {
        // データが読み込み中の場合は何も表示しない
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox.shrink();
        }
        
        // エラーの場合は何も表示しない
        if (snapshot.hasError) {
          return SizedBox.shrink();
        }
        
        // 広告を表示すべきでない場合は何も表示しない
        if (snapshot.data != true) {
          return SizedBox.shrink();
        }
        
        // 広告を表示
        return Container(
          width: double.infinity,
          height: height,
          child: AdWidget(
            ad: BannerAd(
              adUnitId: adUnitId,
              size: AdSize.banner,
              request: AdRequest(),
              listener: BannerAdListener(
                onAdLoaded: (ad) {
                  print('バナー広告が読み込まれました');
                },
                onAdFailedToLoad: (ad, error) {
                  print('バナー広告の読み込みに失敗: $error');
                  ad.dispose();
                },
              ),
            )..load(),
          ),
        );
      },
    );
  }
}
