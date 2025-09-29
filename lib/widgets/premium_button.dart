import 'package:flutter/material.dart';
import '../ads_helper.dart';
import '../premium_dialog.dart';

/// 広告表示状態に応じてPremiumボタンを表示/非表示するウィジェット
class PremiumButton extends StatelessWidget {
  const PremiumButton({Key? key}) : super(key: key);

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
        
        // Premiumボタンを表示
        return IconButton(
          icon: Icon(Icons.star, color: Colors.amber),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => PremiumDialog(),
            );
          },
          tooltip: 'Premium版で広告を削除',
        );
      },
    );
  }
}

/// リワード広告ボタンを表示/非表示するウィジェット
class ConditionalRewardAdButton extends StatelessWidget {
  final VoidCallback onPressed;
  final Widget child;
  
  const ConditionalRewardAdButton({
    Key? key,
    required this.onPressed,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AdsHelper.shouldShowAds(),
      builder: (context, snapshot) {
        // データが読み込み中の場合は無効化
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Opacity(
            opacity: 0.5,
            child: child,
          );
        }
        
        // エラーの場合は無効化
        if (snapshot.hasError) {
          return Opacity(
            opacity: 0.5,
            child: child,
          );
        }
        
        // 広告を表示すべきでない場合は無効化
        if (snapshot.data != true) {
          return Opacity(
            opacity: 0.5,
            child: child,
          );
        }
        
        // ボタンを有効化
        return GestureDetector(
          onTap: onPressed,
          child: child,
        );
      },
    );
  }
}
