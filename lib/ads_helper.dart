import 'package:shared_preferences/shared_preferences.dart';

/// 広告表示制御のためのヘルパークラス
class AdsHelper {
  // 広告削除状態を保存するためのキー
  static const String _removeAdsPrefKey = 'isAdsRemoved';
  static const String _adDisabledUntilKey = 'ad_disabled_until';
  
  /// 広告削除フラグを保存
  static Future<void> saveAdRemovalFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_removeAdsPrefKey, value);
  }
  
  /// 広告が削除されているかチェック
  static Future<bool> isAdRemoved() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_removeAdsPrefKey) ?? false;
  }
  
  /// 24時間広告を無効化（リワード広告視聴後）
  static Future<void> disableAdsFor24Hours() async {
    final prefs = await SharedPreferences.getInstance();
    final disabledUntil = DateTime.now().add(Duration(hours: 24)).millisecondsSinceEpoch;
    await prefs.setInt(_adDisabledUntilKey, disabledUntil);
  }
  
  /// 広告が一時的に無効化されているかチェック
  static Future<bool> isAdTemporarilyDisabled() async {
    final prefs = await SharedPreferences.getInstance();
    final disabledUntil = prefs.getInt(_adDisabledUntilKey) ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    return disabledUntil > now;
  }
  
  /// 広告を表示すべきかどうかの総合判定
  static Future<bool> shouldShowAds() async {
    final isRemoved = await isAdRemoved();
    final isTemporarilyDisabled = await isAdTemporarilyDisabled();
    
    // 購入済みの場合は広告を表示しない
    if (isRemoved) return false;
    
    // 一時的に無効化されている場合は広告を表示しない
    if (isTemporarilyDisabled) return false;
    
    // その他の場合は広告を表示
    return true;
  }
}
