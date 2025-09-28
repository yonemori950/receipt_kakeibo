import 'package:shared_preferences/shared_preferences.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'dart:async';

class PaymentManager {
  static const String _adRemovalPurchasedKey = 'ad_removal_purchased';
  static const String _adDisabledUntilKey = 'ad_disabled_until';
  static const String _adRemovalProductId = 'ad_removal_premium';
  
  static final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  static StreamSubscription<List<PurchaseDetails>>? _subscription;
  
  // 広告削除が購入済みかどうか
  static Future<bool> isAdRemovalPurchased() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adRemovalPurchasedKey) ?? false;
  }
  
  // 広告が一時的に無効化されているかどうか（リワード広告視聴後）
  static Future<bool> isAdTemporarilyDisabled() async {
    final prefs = await SharedPreferences.getInstance();
    final disabledUntil = prefs.getInt(_adDisabledUntilKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return disabledUntil > now;
  }
  
  // 広告を表示すべきかどうか
  static Future<bool> shouldShowAds() async {
    final isPurchased = await isAdRemovalPurchased();
    final isTemporarilyDisabled = await isAdTemporarilyDisabled();
    
    // 購入済みの場合は広告を表示しない
    if (isPurchased) return false;
    
    // 一時的に無効化されている場合は広告を表示しない
    if (isTemporarilyDisabled) return false;
    
    // その他の場合は広告を表示
    return true;
  }
  
  // 永続的な広告削除を購入済みとして設定
  static Future<void> setAdRemovalPurchased() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_adRemovalPurchasedKey, true);
  }
  
  // 24時間広告を無効化（リワード広告視聴後）
  static Future<void> disableAdsFor24Hours() async {
    final prefs = await SharedPreferences.getInstance();
    final disabledUntil = DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch;
    await prefs.setInt(_adDisabledUntilKey, disabledUntil);
  }
  
  // 課金商品の購入を開始
  static Future<bool> purchaseAdRemoval() async {
    try {
      // 商品情報を取得
      final available = await _inAppPurchase.isAvailable();
      if (!available) return false;
      
      // 商品詳細を取得
      final productDetailsResponse = await _inAppPurchase.queryProductDetails({_adRemovalProductId});
      
      if (productDetailsResponse.notFoundIDs.isNotEmpty) {
        print('商品が見つかりません: ${productDetailsResponse.notFoundIDs}');
        return false;
      }
      
      if (productDetailsResponse.productDetails.isEmpty) {
        print('商品詳細が空です');
        return false;
      }
      
      final productDetails = productDetailsResponse.productDetails.first;
      
      // 購入を開始
      final purchaseParam = PurchaseParam(productDetails: productDetails);
      final success = await _inAppPurchase.buyNonConsumable(purchaseParam: purchaseParam);
      
      return success;
    } catch (e) {
      print('購入エラー: $e');
      return false;
    }
  }
  
  // 購入の復元
  static Future<bool> restorePurchases() async {
    try {
      await _inAppPurchase.restorePurchases();
      return true;
    } catch (e) {
      print('復元エラー: $e');
      return false;
    }
  }
  
  // 購入リスナーを設定
  static void initializePurchaseListener(Function(PurchaseDetails) onPurchaseUpdate) {
    _subscription = _inAppPurchase.purchaseStream.listen((purchaseDetailsList) {
      for (final purchaseDetails in purchaseDetailsList) {
        onPurchaseUpdate(purchaseDetails);
      }
    });
  }
  
  // リスナーを破棄
  static void dispose() {
    _subscription?.cancel();
  }
}
