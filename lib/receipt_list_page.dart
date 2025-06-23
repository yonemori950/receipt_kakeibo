import 'package:flutter/material.dart';
import 'database_helper_enhanced.dart';
import 'receipt_model.dart';

class ReceiptListPage extends StatefulWidget {
  @override
  _ReceiptListPageState createState() => _ReceiptListPageState();
}

class _ReceiptListPageState extends State<ReceiptListPage> {
  late Future<List<Receipt>> _receiptList;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  void _refresh() {
    setState(() {
      _receiptList = DatabaseHelper().getReceipts();
    });
  }

  Future<void> _deleteReceipt(int id) async {
    try {
      await DatabaseHelper().deleteReceipt(id);
      _refresh(); // Refresh the list after deletion
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('削除しました'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('削除に失敗しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showDeleteConfirmation(Receipt receipt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('削除しますか？'),
        content: Text('${receipt.store} を削除します。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false), 
            child: Text('キャンセル')
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: Text('削除'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _deleteReceipt(receipt.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('家計簿履歴'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refresh,
          ),
        ],
      ),
      body: FutureBuilder<List<Receipt>>(
        future: _receiptList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(
                    'エラーが発生しました',
                    style: TextStyle(fontSize: 18, color: Colors.red),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: Text('再試行'),
                  ),
                ],
              ),
            );
          }

          final receipts = snapshot.data ?? [];
          if (receipts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '登録されたレシートがありません',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'レシートを撮影して登録してください',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: receipts.length,
            itemBuilder: (context, index) {
              final receipt = receipts[index];
              return Dismissible(
                key: ValueKey(receipt.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  child: Icon(Icons.delete, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text('削除しますか？'),
                      content: Text('${receipt.store} を削除します。'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false), 
                          child: Text('キャンセル')
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true), 
                          child: Text('削除'),
                          style: TextButton.styleFrom(foregroundColor: Colors.red),
                        ),
                      ],
                    ),
                  );
                  return confirm ?? false;
                },
                onDismissed: (direction) async {
                  await _deleteReceipt(receipt.id);
                },
                child: Card(
                  margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue,
                      child: Text(
                        '¥',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      '${receipt.store} - ¥${receipt.amount}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('📅 ${receipt.date}'),
                        if (receipt.createdAt != null)
                          Text(
                            '登録: ${DateTime.parse(receipt.createdAt!).toString().substring(0, 16)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _showDeleteConfirmation(receipt),
                    ),
                    onLongPress: () => _showDeleteConfirmation(receipt),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
} 