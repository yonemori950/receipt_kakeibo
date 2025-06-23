import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'dart:io' show Platform;
import 'database_helper.dart';
import 'history_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  // AdMobの初期化
  await MobileAds.instance.initialize();
  
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
  
  // AdMobバナー広告
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  
  // AdMobリワード広告
  RewardedAd? _rewardedAd;
  bool _isRewardedAdReady = false;

  @override
  void initState() {
    super.initState();
    requestPermissions();
    _loadBannerAd();
    _loadRewardedAd();
  }

  void _loadBannerAd() {
    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-8148356110096114/3236336102',
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

  void _loadRewardedAd() {
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
          setState(() {
            _isRewardedAdReady = true;
          });
          
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
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  void _showRewardedAd() {
    if (_rewardedAd != null) {
      _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          // ユーザーが報酬を獲得した時の処理
          print('User earned reward: ${reward.amount} ${reward.type}');
        },
      );
    } else {
      print('Rewarded ad not ready yet');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    _rewardedAd?.dispose();
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
      appBar: AppBar(title: Text('レシート読み取りOCR')),
      body: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.camera_alt),
                        label: Text('カメラで撮影'),
                      ),
                      ElevatedButton.icon(
                        onPressed: _pickImageFromGallery,
                        icon: Icon(Icons.photo_library),
                        label: Text('ギャラリーから選択'),
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

                          // 登録カウントをインクリメント
                          final prefs = await SharedPreferences.getInstance();
                          final currentCount = prefs.getInt('registration_count') ?? 0;
                          final newCount = currentCount + 1;
                          await prefs.setInt('registration_count', newCount);

                          // 登録完了のSnackBarを表示
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('登録完了！履歴画面に移動します'),
                              duration: Duration(seconds: 2),
                            ),
                          );

                          // 履歴画面に遷移
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => HistoryScreen()),
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
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(extractedText),
                    ),
                  )
                ],
              ),
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
}
