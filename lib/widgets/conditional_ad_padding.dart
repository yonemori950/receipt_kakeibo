import 'package:flutter/material.dart';
import '../ads_helper.dart';

/// 広告表示状態に応じてパディングを調整するウィジェット
class ConditionalAdPadding extends StatelessWidget {
  final Widget child;
  final double adHeight;
  
  const ConditionalAdPadding({
    Key? key,
    required this.child,
    this.adHeight = 80.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdsHelper.shouldShowAds(),
      builder: (context, snapshot) {
        // データが読み込み中の場合は通常のパディング
        if (snapshot.connectionState == ConnectionState.waiting) {
          return child;
        }
        
        // エラーの場合は通常のパディング
        if (snapshot.hasError) {
          return child;
        }
        
        // 広告を表示すべきでない場合は広告分のパディングを追加しない
        if (snapshot.data != true) {
          return child;
        }
        
        // 広告を表示する場合は広告分のパディングを追加
        return Padding(
          padding: EdgeInsets.only(bottom: adHeight),
          child: child,
        );
      },
    );
  }
}
