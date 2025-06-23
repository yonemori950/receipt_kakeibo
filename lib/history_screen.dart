import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> _expenses = [];
  BannerAd? _bannerAd;
  RewardedAd? _rewardedAd;
  bool _isAdLoaded = false;
  bool _isRewardedAdLoaded = false;
  int _registrationCount = 0;
  static const int REWARD_INTERVAL = 3; // 3回ごとにリワード広告

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _loadBannerAd();
    _loadRewardedAd();
    _loadRegistrationCount();
  }

  Future<void> _loadRegistrationCount() async {
    final prefs = await SharedPreferences.getInstance();
    final count = prefs.getInt('registration_count') ?? 0;
    setState(() {
      _registrationCount = count;
    });
  }

  void _loadRewardedAd() {
    String adUnitId;
    if (Platform.isAndroid) {
      adUnitId = 'ca-app-pub-3940256099942544/5224354917'; // テスト用ID
    } else {
      adUnitId = 'ca-app-pub-3940256099942544/1712485313'; // iOSテスト用ID
    }

    RewardedAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          setState(() {
            _rewardedAd = ad;
            _isRewardedAdLoaded = true;
          });
        },
        onAdFailedToLoad: (error) {
          // エラー時は静かに処理
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd == null || !_isRewardedAdLoaded) {
      return;
    }

    try {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadRewardedAd();
        },
      );
      
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 リワードを獲得しました！'),
            backgroundColor: Colors.green,
          ),
        );
      });
    } catch (e) {
      // エラー時は静かに処理
    }
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-3940256099942544/6300978111', // テスト用ID
      size: AdSize.banner,
      request: AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
        },
      ),
    );

    _bannerAd!.load();
  }

  Future<void> _loadExpenses() async {
    final dbHelper = DatabaseHelper();
    final expenses = await dbHelper.queryAllRows();
    setState(() {
      _expenses = expenses.reversed.toList();
    });
  }

  Future<void> _deleteExpense(int id) async {
    final dbHelper = DatabaseHelper();
    await dbHelper.delete(id);
    _loadExpenses();
  }

  void _showRewardedAdAndNavigateBack() {
    if (_isRewardedAdLoaded && _rewardedAd != null) {
      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (ad) {
          ad.dispose();
          _loadRewardedAd();
          Navigator.of(context).pop();
        },
        onAdFailedToShowFullScreenContent: (ad, error) {
          ad.dispose();
          _loadRewardedAd();
          Navigator.of(context).pop();
        },
      );
      
      _rewardedAd!.show(onUserEarnedReward: (ad, reward) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 リワードを獲得しました！'),
            backgroundColor: Colors.green,
          ),
        );
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('家計簿履歴'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            print('🏠 ホーム画面に戻ります');
            // リワード広告を表示してから戻る
            _showRewardedAdAndNavigateBack();
          },
        ),
        actions: [
          // 登録カウントを表示
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                '登録回数: $_registrationCount',
                style: TextStyle(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _expenses.isEmpty
                ? Center(child: Text('まだ登録されていません'))
                : ListView.builder(
                    itemCount: _expenses.length,
                    itemBuilder: (context, index) {
                      final item = _expenses[index];
                      return Card(
                        margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        child: ListTile(
                          title: Text('💴 ${item['amount']}'),
                          subtitle: Text('📅 ${item['date']}　🏪 ${item['store']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () => _deleteExpense(item['id']),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          // バナー広告
          if (_isAdLoaded)
            Container(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
    super.dispose();
  }
} 