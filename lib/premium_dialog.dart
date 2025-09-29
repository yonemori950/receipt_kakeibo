import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'ads_helper.dart';
import 'iap_helper.dart';

class PremiumDialog extends StatefulWidget {
  @override
  _PremiumDialogState createState() => _PremiumDialogState();
}

class _PremiumDialogState extends State<PremiumDialog> {
  bool _isLoading = false;
  bool _isPurchased = false;
  String _productPrice = '¥300';

  @override
  void initState() {
    super.initState();
    _checkPurchaseStatus();
    _loadProductPrice();
  }

  Future<void> _checkPurchaseStatus() async {
    final isPurchased = await AdsHelper.isAdRemoved();
    setState(() {
      _isPurchased = isPurchased;
    });
  }

  Future<void> _loadProductPrice() async {
    try {
      final productDetailsResponse = await InAppPurchase.instance.queryProductDetails({'remove_ads'});
      if (productDetailsResponse.productDetails.isNotEmpty) {
        final product = productDetailsResponse.productDetails.first;
        setState(() {
          _productPrice = product.price;
        });
      }
    } catch (e) {
      print('価格取得エラー: $e');
    }
  }

  Future<void> _purchasePremium() async {
    setState(() {
      _isLoading = true;
    });

    final success = await IAPHelper.purchaseRemoveAds();
    
    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('購入が完了しました！広告が永続的に削除されました。'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('購入に失敗しました。'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _restorePurchases() async {
    setState(() {
      _isLoading = true;
    });

    final success = await IAPHelper.restorePurchases();
    
    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('購入履歴を復元しました。'),
          backgroundColor: Colors.green,
        ),
      );
      await _checkPurchaseStatus();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('復元に失敗しました。'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
          maxWidth: MediaQuery.of(context).size.width * 0.9,
        ),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            // ヘッダー
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple, Colors.blue],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.star,
                    color: Colors.white,
                    size: 48,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Premium版',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // 機能説明
            if (!_isPurchased) ...[
              Text(
                '広告を永続的に削除',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              _buildFeatureItem('✅ 全ての広告を完全削除'),
              _buildFeatureItem('✅ 一度購入で永続利用'),
              _buildFeatureItem('✅ 全ての機能を無制限利用'),
              
              SizedBox(height: 24),
              
              // 価格と購入ボタン
              Text(
                _productPrice,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _purchasePremium,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text(
                          '購入する',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              
              SizedBox(height: 12),
              
              TextButton(
                onPressed: _isLoading ? null : _restorePurchases,
                child: Text('購入履歴を復元'),
              ),
            ] else ...[
              // 購入済みの場合
              Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 64,
              ),
              SizedBox(height: 16),
              Text(
                'Premium版を購入済みです！',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              SizedBox(height: 16),
              Text(
                '広告は表示されません',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
            ],
            
            SizedBox(height: 16),
            
              // 閉じるボタン
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('閉じる'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(text, style: TextStyle(fontSize: 16))),
        ],
      ),
    );
  }
}
