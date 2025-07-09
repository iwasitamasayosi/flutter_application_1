import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  // Firebase初期化
  await Firebase.initializeApp();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '収支確認画面',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Report_screen(),
    );
  }
}

class Report_screen extends StatefulWidget {
  @override
  Report createState() => Report();
}

class Report extends State<Report_screen> with SingleTickerProviderStateMixin {
  List<DocumentSnapshot> incomeList = [];
  List<DocumentSnapshot> expenseList = [];
  int totalIncome = 0;
  int totalExpense = 0;
  late TabController _tabController;
  String? selectedMonth;
  List<String> availableMonths = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    fetchData();
  }

  void updateTotals() {
    final List<DocumentSnapshot> filteredIncome = selectedMonth == 'All'
        ? incomeList
        : incomeList.where((doc) {
            final date = (doc['date'] as Timestamp).toDate();
            final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            return key == selectedMonth;
          }).toList();

    final List<DocumentSnapshot> filteredExpense = selectedMonth == 'All'
        ? expenseList
        : expenseList.where((doc) {
            final date = (doc['date'] as Timestamp).toDate();
            final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            return key == selectedMonth;
          }).toList();

    setState(() {
      totalIncome =
          filteredIncome.fold(0, (sum, doc) => sum + (doc['money'] as int));
      totalExpense =
          filteredExpense.fold(0, (sum, doc) => sum + (doc['money'] as int));
    });
  }

  Future<void> fetchData() async {
    final incomeSnapshot =
        await FirebaseFirestore.instance.collection('income').get();
    final expenseSnapshot =
        await FirebaseFirestore.instance.collection('expenditure').get();

    incomeList = incomeSnapshot.docs;
    expenseList = expenseSnapshot.docs;

    Set<String> months = {};
    for (var doc in [...incomeList, ...expenseList]) {
      Timestamp timestamp = doc['date'];
      DateTime date = timestamp.toDate();
      String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      months.add(monthKey);
    }

    setState(() {
      availableMonths = months.toList()..sort();
      availableMonths.insert(0, 'All');
      selectedMonth ??= availableMonths.isNotEmpty ? availableMonths.first : null;
    });

    updateTotals();
  }

  Map<String, List<DocumentSnapshot>> groupByMonth(List<DocumentSnapshot> docs) {
    Map<String, List<DocumentSnapshot>> monthlyMap = {};

    for (var doc in docs) {
      Timestamp timestamp = doc['date'];
      DateTime date = timestamp.toDate();
      String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';

      monthlyMap.putIfAbsent(monthKey, () => []).add(doc);
    }

    return monthlyMap;
  }

  // --- 編集機能の追加部分 ---
  Future<void> _showEditDialog(
      DocumentSnapshot doc, String collectionName) async {
    // memoが存在しない場合やnullの場合でも空文字列として初期化
    TextEditingController elementsController =
        TextEditingController(text: doc['elements'] ?? '');
    TextEditingController moneyController =
        TextEditingController(text: (doc['money'] ?? 0).toString());
    TextEditingController memoController =
        TextEditingController(text: (doc.data() as Map<String, dynamic>).containsKey('memo') ? doc['memo'] : '');
    DateTime selectedDate = (doc['date'] as Timestamp).toDate();

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('編集'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: elementsController,
                      decoration: InputDecoration(labelText: '内容'),
                    ),
                    TextField(
                      controller: moneyController,
                      decoration: InputDecoration(labelText: '金額'),
                      keyboardType: TextInputType.number,
                    ),
                    TextField(
                      controller: memoController,
                      decoration: InputDecoration(labelText: 'メモ (オプション)'),
                    ),
                    ListTile(
                      title: Text(
                          '日付: ${DateFormat('yyyy年MM月dd日').format(selectedDate)}'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != selectedDate) {
                          setDialogState(() {
                            selectedDate = picked;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('キャンセル'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('更新'),
                  onPressed: () async {
                    try {
                      await FirebaseFirestore.instance
                          .collection(collectionName)
                          .doc(doc.id)
                          .update({
                        'elements': elementsController.text,
                        'money': int.parse(moneyController.text),
                        'memo': memoController.text,
                        'date': Timestamp.fromDate(selectedDate),
                      });
                      Navigator.of(context).pop();
                      fetchData(); // 更新後にデータを再取得
                    } catch (e) {
                      print('ドキュメントの更新エラー: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('更新に失敗しました: $e')),
                      );
                    }
                  },
                ),
                TextButton(
                  child: Text('削除', style: TextStyle(color: Colors.red)),
                  onPressed: () async {
                    bool? confirmDelete = await showDialog<bool>(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('確認'),
                          content: Text('この項目を削除してもよろしいですか？'),
                          actions: <Widget>[
                            TextButton(
                              child: Text('キャンセル'),
                              onPressed: () {
                                Navigator.of(context).pop(false);
                              },
                            ),
                            TextButton(
                              child: Text('削除'),
                              onPressed: () {
                                Navigator.of(context).pop(true);
                              },
                            ),
                          ],
                        );
                      },
                    );

                    if (confirmDelete == true) {
                      try {
                        await FirebaseFirestore.instance
                            .collection(collectionName)
                            .doc(doc.id)
                            .delete();
                        Navigator.of(context).pop(); // 編集ダイアログを閉じる
                        fetchData(); // 削除後にデータを再取得
                      } catch (e) {
                        print('ドキュメントの削除エラー: $e');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('削除に失敗しました: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget buildMonthlyCategoryList(
      List<DocumentSnapshot> dataList, String collectionName) {
    if (selectedMonth == null) return Center(child: Text('月を選択してください'));

    final filteredDocs = selectedMonth == 'All'
        ? dataList
        : dataList.where((doc) {
            final date = (doc['date'] as Timestamp).toDate();
            final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            return key == selectedMonth;
          }).toList();

    if (filteredDocs.isEmpty) {
      return Center(child: Text('データがありません'));
    }

    Map<String, List<DocumentSnapshot>> categoryMap = {};
    for (var doc in filteredDocs) {
      String category = doc['elements'] ?? '未分類';
      categoryMap.putIfAbsent(category, () => []).add(doc);
    }

    return ListView(
      children: categoryMap.entries.map((entry) {
        String category = entry.key;
        List<DocumentSnapshot> items = entry.value;
        int total = items.fold(0, (sum, doc) => sum + (doc['money'] as int));

        return ExpansionTile(
          title: Text('$category：${total}円'),
          children: items.map((doc) {
            // ドキュメントから日付を取得し、フォーマット
            Timestamp timestamp = doc['date'];
            DateTime date = timestamp.toDate();
            String formattedDate = DateFormat('yyyy年MM月dd日').format(date);

            return ListTile(
              title: Text('内容：${doc['elements']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('日付：$formattedDate',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  Text('${doc['money']}円'),
                  if (doc.data() != null &&
                      (doc.data() as Map<String, dynamic>).containsKey('memo') &&
                      (doc['memo'] as String).isNotEmpty)
                    Text('メモ：${doc['memo']}',
                        style: TextStyle(color: Colors.grey[700])),
                ],
              ),
              onTap: () => _showEditDialog(doc, collectionName), // onTapを追加
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  Widget buildPieChart(List<DocumentSnapshot> dataList, String? selectedMonth) {
    if (dataList.isEmpty || selectedMonth == null) {
      return Center(child: Text('データがありません'));
    }

    final filteredDocs = selectedMonth == 'All'
        ? dataList
        : dataList.where((doc) {
            final date = (doc['date'] as Timestamp).toDate();
            final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            return key == selectedMonth;
          }).toList();

    if (filteredDocs.isEmpty) {
      return Center(child: Text('選択された月にデータがありません'));
    }

    Map<String, int> categoryTotals = {};
    for (var doc in filteredDocs) {
      String category = doc['elements'] ?? '未分類';
      int amount = doc['money'] as int;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }

    final total = categoryTotals.values.fold(0, (sum, val) => sum + val);

    final sortedEntries = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.brown,
      Colors.indigo,
      Colors.pink,
      Colors.cyan,
    ];

    int colorIndex = 0;

    return PieChart(
      PieChartData(
        sections: sortedEntries.map((entry) {
          final percentage = (entry.value / total * 100).toStringAsFixed(1);
          return PieChartSectionData(
            color: colors[colorIndex++ % colors.length],
            value: entry.value.toDouble(),
            title: '${entry.key}\n$percentage%',
            radius: 60,
            titleStyle: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int balance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(title: Text('収支確認画面')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('収入合計：${totalIncome}円',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('支出合計：${totalExpense}円',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('収支：${balance}円',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: balance >= 0 ? Colors.green : Colors.red)),
              ],
            ),
          ),
          DropdownButton<String>(
            value: selectedMonth,
            hint: Text('月を選択'),
            items: availableMonths.map((month) {
              return DropdownMenuItem(
                value: month,
                child: Text(month == 'All' ? '全期間' : month),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedMonth = value;
                updateTotals();
              });
            },
          ),
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: '収入'),
              Tab(text: '支出'),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.grey,
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                Column(
                  children: [
                    SizedBox(
                        height: 200,
                        child: buildPieChart(incomeList, selectedMonth)),
                    Expanded(child: buildMonthlyCategoryList(incomeList, 'income')),
                  ],
                ),
                Column(
                  children: [
                    SizedBox(
                        height: 200,
                        child: buildPieChart(expenseList, selectedMonth)),
                    Expanded(
                        child: buildMonthlyCategoryList(expenseList, 'expenditure')),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              child: Text('収支を再取得'),
              onPressed: fetchData,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}