import 'package:flutter/material.dart';
import 'database_helper.dart';

class HistoryScreen extends StatefulWidget {
  @override
  _HistoryScreenState createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _expenses = [];

  @override
  void initState() {
    super.initState();
    _loadExpenses();
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
      appBar: AppBar(title: Text('家計簿履歴')),
      body: _expenses.isEmpty
          ? Center(child: Text('まだ登録されていません'))
          : ListView.builder(
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
    );
  }
} 