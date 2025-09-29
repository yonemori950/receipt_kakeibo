import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'database_helper.dart';
import 'history_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'ads_helper.dart';
import 'iap_helper.dart';
import 'widgets/conditional_ad_banner.dart';
import 'widgets/premium_button.dart';
import 'widgets/conditional_ad_padding.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

String extractAmount(String text) {
  final yenPattern = RegExp(r'(¥|￥)?\s?(\d{1,3}(,\d{3})+|\d+)(円)?');
  final match = yenPattern.firstMatch(text);
  return match?.group(0) ?? '未検出';
}

String extractDate(String text) {
  final datePattern = RegExp(r'\d{4}[-/.年]\d{1,2}[-/.月]\d{1,2}');
  final match = datePattern.firstMatch(text);
  return match?.group(0) ?? '未検出';
}

String extractStoreName(String text) {
  // 簡易版：1行目 or 最上部に出てくる大きな文字を仮の店名とする
  final lines = text.split('\n');
  for (String line in lines) {
    if (line.length > 4 && !line.contains(RegExp(r'\d'))) {
      return line.trim();
    }
  }
  return '未検出';
}

Future<void> requestPermissions() async {
  await Permission.camera.request();
  await Permission.photos.request();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 広告表示が必要な場合のみAdMobを初期化
  final shouldShowAds = await AdsHelper.shouldShowAds();
  if (shouldShowAds) {
    await MobileAds.instance.initialize();
  }
  
  runApp(MaterialApp(
    home: OCRScreen(),
    debugShowCheckedModeBanner: false,
  ));
}

class OCRScreen extends StatefulWidget {
  @override
  _OCRScreenState createState() => _OCRScreenState();
}

class _OCRScreenState extends State<OCRScreen> {
  String extractedText = '';
  String extractedAmount = '';
  String extractedDate = '';
  String extractedStoreName = '';
  File? _image;
  final dbHelper = DatabaseHelper();
  final TextEditingController _dateController = TextEditingController();
  final TextEditingController _storeController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  
  // AdMobリワード広告
  RewardedAd? _rewardedAd;
  
  @override
  void initState() {
    super.initState();
    requestPermissions();
    _initializePayment();
    _loadRewardedAd();
  }

  void _initializePayment() {
    IAPHelper.listenToPurchaseUpdates((purchaseDetails) {
      if (purchaseDetails.status == PurchaseStatus.purchased) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Premium版の購入が完了しました！'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    });
  }


  Future<void> _loadRewardedAd() async {
    final shouldShowAds = await AdsHelper.shouldShowAds();
    if (!shouldShowAds) return;
    
    String adUnitId;
    if (Platform.isAndroid) {
      adUnitId = 'ca-app-pub-8148356110096114/8146446657';
    } else {
      adUnitId = 'ca-app-pub-8148356110096114/6921813131';
    }

    RewardedAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              ad.dispose();
              _loadRewardedAd(); // 次の広告を読み込み
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              ad.dispose();
              _loadRewardedAd(); // 次の広告を読み込み
            },
          );
        },
        onAdFailedToLoad: (error) {
          print('Rewarded ad failed to load: $error');
        },
      ),
    );
  }

  Future<void> _showRewardedAd() async {
    final shouldShowAds = await AdsHelper.shouldShowAds();
    if (!shouldShowAds) return;
    
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // ユーザーが報酬を獲得した時の処理
          print('User earned reward: ${reward.amount} ${reward.type}');
          
          // 24時間広告を無効化
          AdsHelper.disableAdsFor24Hours();
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('24時間広告を非表示にしました！'),
              backgroundColor: Colors.green,
            ),
          );
        },
      );
    } else {
      print('Rewarded ad not ready yet');
    }
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    IAPHelper.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String rawText = recognizedText.text;

      setState(() {
        _image = File(image.path);
        extractedText = rawText;

        // 抽出したテキストから情報を取り出す
        _dateController.text = extractDate(extractedText);
        _storeController.text = extractStoreName(extractedText);
        _amountController.text = extractAmount(extractedText);
      });
    }
  }

  Future<void> _pickImageFromGallery() async {
    final ImagePicker _picker = ImagePicker();
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.japanese);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String rawText = recognizedText.text;

      setState(() {
        _image = File(image.path);
        extractedText = rawText;

        // 抽出したテキストから情報を取り出す
        _dateController.text = extractDate(extractedText);
        _storeController.text = extractStoreName(extractedText);
        _amountController.text = extractAmount(extractedText);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('レシート読み取りOCR'),
        actions: [
          PremiumButton(),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    // ボタンを縦に配置して重なりを防ぐ
                    Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _pickImage,
                            icon: Icon(Icons.camera_alt),
                            label: Text('カメラで撮影'),
                          ),
                        ),
                        SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _pickImageFromGallery,
                            icon: Icon(Icons.photo_library),
                            label: Text('ギャラリーから選択'),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    _image != null ? Image.file(_image!, height: 200) : Container(),
                    SizedBox(height: 16),
                    if (extractedText.isNotEmpty) ...[
                      TextField(
                        controller: _dateController,
                        decoration: InputDecoration(labelText: '日付'),
                      ),
                      TextField(
                        controller: _storeController,
                        decoration: InputDecoration(labelText: '店舗名'),
                      ),
                      TextField(
                        controller: _amountController,
                        decoration: InputDecoration(labelText: '金額'),
                        keyboardType: TextInputType.number,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () async {
                          if (_amountController.text.isNotEmpty && _dateController.text.isNotEmpty) {
                            // データベースに保存
                            await dbHelper.insert({
                              'date': _dateController.text,
                              'store': _storeController.text,
                              'amount': _amountController.text,
                            });

                            // リワード広告を表示
                            _showRewardedAd();

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('保存しました！')),
                            );
                          }
                        },
                        child: Text('登録'),
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HistoryScreen()),
                          );
                        },
                        child: Text('履歴を見る'),
                      ),
                      SizedBox(height: 16),
                    ],
                    if (extractedText.isNotEmpty)
                      Text(extractedText),
                    // 広告表示に応じたパディング
                    ConditionalAdPadding(
                      child: SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ),
            // 条件付きバナー広告
            ConditionalAdBanner(
              adUnitId: Platform.isAndroid 
                ? 'ca-app-pub-8148356110096114/3236336102'
                : 'ca-app-pub-8148356110096114/3236336102',
            ),
          ],
        ),
      ),
    );
  }
}
