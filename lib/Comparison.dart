import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

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
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: Comparison_screen(),
    );
  }
}

class Comparison_screen extends StatefulWidget {
  @override
  Comparison createState() => Comparison();
}

class Comparison extends State<Comparison_screen> {
  List<DocumentSnapshot> incomeList = [];
  List<DocumentSnapshot> expenseList = [];
  List<String> availableMonths = [];

  String? selectedMonthLeft;
  String? selectedMonthRight;

  // 表示内容を左右で連動させるための単一のState変数
  String selectedContentType = 'income';

  @override
  void initState() {
    super.initState();
    // データの取得と月の初期設定
    fetchData().then((_) {
      setState(() {
        // '全期間'をデフォルトとして設定
        selectedMonthLeft = availableMonths.isNotEmpty ? availableMonths.first : null;
        selectedMonthRight = availableMonths.isNotEmpty ? availableMonths.first : null;
      });
    });
  }

  Future<void> fetchData() async {
    try {
      final incomeSnapshot = await FirebaseFirestore.instance.collection('income').get();
      final expenseSnapshot = await FirebaseFirestore.instance.collection('expenditure').get();

      incomeList = incomeSnapshot.docs;
      expenseList = expenseSnapshot.docs;

      Set<String> months = {};
      // 収入と支出の両方から月を抽出
      for (var doc in [...incomeList, ...expenseList]) {
        Timestamp timestamp = doc['date'];
        DateTime date = timestamp.toDate();
        // 'YYYY-MM'形式で月キーを作成
        String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
        months.add(monthKey);
      }

      setState(() {
        // 月をソートし、'全期間'オプションを追加
        availableMonths = months.toList()..sort();
        availableMonths.insert(0, 'All');
      });
    } catch (e) {
      // エラーハンドリング
      debugPrint('データの取得中にエラーが発生しました: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('データの読み込みに失敗しました: $e')),
        );
      }
    }
  }

  Widget buildMonthlyCategoryList(String? currentSelectedMonth, String contentType) {
    if (currentSelectedMonth == null) {
      return const Center(child: Text('月を選択してください'));
    }

    List<DocumentSnapshot> docsToDisplay = [];

    if (contentType == 'income') {
      docsToDisplay = incomeList;
    } else if (contentType == 'expense') {
      docsToDisplay = expenseList;
    } else if (contentType == 'balance') {
      docsToDisplay = [...incomeList, ...expenseList];
    }

    // 選択された月でデータをフィルタリング
    final filteredDocs = currentSelectedMonth == 'All'
        ? docsToDisplay
        : docsToDisplay.where((doc) {
            final date = (doc['date'] as Timestamp).toDate();
            final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            return key == currentSelectedMonth;
          }).toList();

    // カテゴリごとにデータを集計
    Map<String, List<DocumentSnapshot>> categoryMap = {};
    for (var doc in filteredDocs) {
      String category = doc['elements'] ?? '未分類';
      categoryMap.putIfAbsent(category, () => []).add(doc);
    }

    if (filteredDocs.isEmpty) {
      return const Center(child: Text('データがありません'));
    }

    return ListView(
      children: categoryMap.entries.map((entry) {
        String category = entry.key;
        List<DocumentSnapshot> items = entry.value;
        int categoryTotal = items.fold(0, (sum, doc) {
          int amount = doc['money'] as int;
          if (contentType == 'balance' && doc.reference.parent.id == 'expenditure') {
            return sum - amount;
          }
          return sum + amount;
        });

        return ExpansionTile(
          title: Text('$category：${categoryTotal}円'),
          children: items.map((doc) {
            final memo = (doc.data() as Map<String, dynamic>).containsKey('memo')
                ? doc['memo'] as String
                : '';
            final date = (doc['date'] as Timestamp).toDate();
            final formattedDate = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
            final int amount = doc['money'] as int;
            final String type = doc.reference.parent.id == 'income' ? '収入' : '支出';
            final Color amountColor = (type == '収入') ? Colors.green : Colors.red;

            return ListTile(
              title: Text('内容：${doc['elements']} (${formattedDate})'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${type}：${amount}円', style: TextStyle(color: amountColor, fontWeight: FontWeight.bold)),
                  if (memo.isNotEmpty)
                    Text('メモ：$memo', style: TextStyle(color: Colors.grey[700])),
                ],
              ),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  /// 指定された月の合計金額を計算します。
  int calculateTotal(String? selectedMonth, String contentType) {
    if (selectedMonth == null) return 0;

    List<DocumentSnapshot> targetList;

    if (contentType == 'income') {
      targetList = incomeList;
    } else if (contentType == 'expense') {
      targetList = expenseList;
    } else {
      targetList = [...incomeList, ...expenseList];
    }

    final filteredDocs = selectedMonth == 'All'
        ? targetList
        : targetList.where((doc) {
            final date = (doc['date'] as Timestamp).toDate();
            final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            return key == selectedMonth;
          }).toList();

    int total = 0;
    for (var doc in filteredDocs) {
      int amount = doc['money'] as int;
      if (doc.reference.parent.id == 'income') {
        total += amount;
      } else if (doc.reference.parent.id == 'expenditure') {
        total -= amount;
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    // 左側の合計を計算
    final totalLeft = calculateTotal(selectedMonthLeft, selectedContentType);
    // 右側の合計を計算
    final totalRight = calculateTotal(selectedMonthRight, selectedContentType);

    return Scaffold(
      appBar: AppBar(title: const Text('収支レポート比較')),
      body: Column(
        children: [
          // 左右共通の表示内容選択ドロップダウン
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButton<String>(
              value: selectedContentType,
              items: const [
                DropdownMenuItem(value: 'income', child: Text('収入を表示')),
                DropdownMenuItem(value: 'expense', child: Text('支出を表示')),
                DropdownMenuItem(value: 'balance', child: Text('収支を表示')),
              ],
              onChanged: (value) {
                setState(() {
                  selectedContentType = value!;
                });
              },
            ),
          ),
          Expanded(
            child: Row(
              children: [
                // 左側パネル
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // 表示内容に応じたタイトル
                        Text(
                          selectedContentType == 'income'
                              ? '収入'
                              : selectedContentType == 'expense'
                                  ? '支出'
                                  : '収支',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: selectedContentType == 'income' ? Colors.blue : selectedContentType == 'expense' ? Colors.red : Colors.green[700],
                          ),
                        ),
                        DropdownButton<String>(
                          value: selectedMonthLeft,
                          hint: const Text('月を選択'),
                          items: availableMonths.map((month) {
                            return DropdownMenuItem(
                              value: month,
                              child: Text(month == 'All' ? '全期間' : month),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedMonthLeft = value;
                            });
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            '合計：${totalLeft}円',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(),
                        Expanded(child: buildMonthlyCategoryList(selectedMonthLeft, selectedContentType)),
                      ],
                    ),
                  ),
                ),
                // 区切り線
                const VerticalDivider(width: 1, thickness: 1, color: Colors.grey),
                // 右側パネル
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // 表示内容に応じたタイトル
                        Text(
                          selectedContentType == 'income'
                              ? '収入'
                              : selectedContentType == 'expense'
                                  ? '支出'
                                  : '収支',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: selectedContentType == 'income' ? Colors.blue : selectedContentType == 'expense' ? Colors.red : Colors.green[700],
                          ),
                        ),
                        DropdownButton<String>(
                          value: selectedMonthRight,
                          hint: const Text('月を選択'),
                          items: availableMonths.map((month) {
                            return DropdownMenuItem(
                              value: month,
                              child: Text(month == 'All' ? '全期間' : month),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedMonthRight = value;
                            });
                          },
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Text(
                            '合計：${totalRight}円',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Divider(),
                        Expanded(child: buildMonthlyCategoryList(selectedMonthRight, selectedContentType)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: fetchData,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text(
                '収支を再取得',
                style: TextStyle(fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}