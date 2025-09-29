import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';
import 'ads_helper.dart';

/// アプリ内課金処理のためのヘルパークラス
class IAPHelper {
  static const String removeAdsProductId = 'remove_ads';
  
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  /// 課金が利用可能かチェック
  static Future<bool> isAvailable() async {
    return await _inAppPurchase.isAvailable();
  }
  
  /// 広告削除商品の購入処理
  static Future<bool> purchaseRemoveAds() async {
    try {
      final available = await _inAppPurchase.isAvailable();
      if (!available) {
        print('課金が利用できません');
        return false;
      }

      final ProductDetailsResponse response =
          await _inAppPurchase.queryProductDetails({removeAdsProductId});
      
      if (response.notFoundIDs.isNotEmpty) {
        print('商品が見つかりません: ${response.notFoundIDs}');
        return false;
      }

      if (response.productDetails.isEmpty) {
        print('商品詳細が空です');
        return false;
      }

      final productDetails = response.productDetails.first;
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      
      final success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      return success;
    } catch (e) {
      print('購入エラー: $e');
      return false;
    }
  }
  
  /// 購入の復元
  static Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      print('復元エラー: $e');
      return false;
    }
  }
  
  /// 購入更新のリスナーを設定
  static void listenToPurchaseUpdates(Function(PurchaseDetails) onPurchaseUpdate) {
    _subscription = _inAppPurchase.purchaseStream.listen((purchases) {
      for (var purchase in purchases) {
        onPurchaseUpdate(purchase);
        
        // 購入完了時の処理
        if (purchase.productID == removeAdsProductId &&
            purchase.status == PurchaseStatus.purchased) {
          // 広告削除フラグを保存
          AdsHelper.saveAdRemovalFlag(true);
        }
        
        // 購入処理を完了させる
        if (purchase.pendingCompletePurchase) {
          _inAppPurchase.completePurchase(purchase);
        }
      }
    });
  }
  
  /// リスナーを破棄
  static void dispose() {
    _subscription?.cancel();
  }
}
