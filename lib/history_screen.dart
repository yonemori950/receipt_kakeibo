import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'database_helper.dart';

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

  @override
  void initState() {
    super.initState();
    _loadExpenses();
    _loadBannerAd();
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

  void _showExpenseDetail(Map<String, dynamic> expense) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ハンドル
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            SizedBox(height: 20),
            // タイトル
            Text(
              '支出詳細',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            // 詳細情報
            _buildDetailRow('💰 金額', expense['amount']),
            _buildDetailRow('📅 日付', expense['date']),
            _buildDetailRow('🏪 店舗名', expense['store']),
            SizedBox(height: 20),
            // アクションボタン
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _deleteExpense(expense['id']);
                    },
                    icon: Icon(Icons.delete),
                    label: Text('削除'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('閉じる'),
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('家計簿履歴'),
        actions: [
          if (_expenses.isNotEmpty)
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: _loadExpenses,
              tooltip: '更新',
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _expenses.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.receipt_long,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'まだ登録されていません',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'レシートを撮影して登録してみましょう',
                            style: TextStyle(
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.only(bottom: 60), // バナー広告の高さ分の余白
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
                              title: Text(
                                '💴 ${item['amount']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                '📅 ${item['date']}　🏪 ${item['store']}',
                                style: TextStyle(fontSize: 14),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.info_outline),
                                    onPressed: () => _showExpenseDetail(item),
                                    tooltip: '詳細を見る',
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete),
                                    onPressed: () => _deleteExpense(item['id']),
                                    tooltip: '削除',
                                  ),
                                ],
                              ),
                              onTap: () => _showExpenseDetail(item),
                            ),
                          ),
                        );
                      },
                    ),
            ),
            // バナー広告をSafeAreaの中に明示的に置く
            if (_isAdLoaded)
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