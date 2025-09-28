import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'database_helper.dart';
import 'payment_manager.dart';
import 'premium_dialog.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _expenses = [];
  
  // AdMobバナー広告
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _shouldShowAds = true;

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _initializeAds();
  }

  Future<void> _initializeAds() async {
    final shouldShow = await PaymentManager.shouldShowAds();
    setState(() {
      _shouldShowAds = shouldShow;
    });
    
    if (_shouldShowAds) {
      _loadBannerAd();
    }
  }

  void _loadBannerAd() {
    String adUnitId;
    if (Platform.isAndroid) {
      adUnitId = 'ca-app-pub-8148356110096114/3236336102';
    } else {
      adUnitId = 'ca-app-pub-8148356110096114/6921813131';
    }

    _bannerAd = BannerAd(
      adUnitId: adUnitId,
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          print('Ad failed to load: ' + error.toString());
          ad.dispose();
        },
      ),
    );
    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  Future<void> _loadExpenses() async {
    final allRows = await dbHelper.queryAllRows();
    setState(() {
      _expenses = allRows.reversed.toList();
    });
  }

  Future<void> _deleteExpense(int id) async {
    await dbHelper.delete(id);
    await _loadExpenses();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('削除しました')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('家計簿履歴'),
        actions: [
          if (_shouldShowAds)
            IconButton(
              icon: Icon(Icons.star),
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => PremiumDialog(),
                );
                if (result == true) {
                  _initializeAds(); // 広告状態を更新
                }
              },
              tooltip: 'Premium版を購入',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _expenses.isEmpty
                  ? Center(child: Text('まだ登録されていません'))
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: _shouldShowAds ? 60 : 0), // バナー広告の高さ分の余白
                      itemCount: _expenses.length,
                      itemBuilder: (context, index) {
                        final item = _expenses[index];
                        return Dismissible(
                          key: ValueKey(item['id']),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: EdgeInsets.only(right: 20),
                            child: Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) => _deleteExpense(item['id']),
                          child: Card(
                            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            child: ListTile(
                              title: Text('💴 ${item['amount']}'),
                              subtitle: Text('📅 ${item['date']}　🏪 ${item['store']}'),
                              trailing: IconButton(
                                icon: Icon(Icons.delete),
                                onPressed: () => _deleteExpense(item['id']),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // バナー広告をSafeAreaの中に明示的に置く（広告が有効な場合のみ）
            if (_shouldShowAds && _isAdLoaded)
              Container(
                width: double.infinity,
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
          ],
        ),
      ),
    );
  }
} 