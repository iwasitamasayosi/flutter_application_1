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
      title: '収支レポート',
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

  // New state variables for content selection
  String selectedContentTypeLeft = 'income'; // 'income', 'expense', 'balance'
  String selectedContentTypeRight = 'expense'; // 'income', 'expense', 'balance'

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

  /// Firestoreから収入と支出のデータを取得し、利用可能な月を更新します。
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
        availableMonths.insert(0, 'All'); // 'All' for '全期間'
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

  /// 指定された月のカテゴリリストを構築します。
  /// contentTypeによって表示するデータを切り替えます。
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
      // For balance, we aggregate both income and expenditure and treat them as one list
      // This will show individual income and expense items under their categories.
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
        // Calculate category total based on whether it's income or expense
        int categoryTotal = items.fold(0, (sum, doc) {
          int amount = doc['money'] as int;
          // If we are showing 'balance', expenses should be negative for correct aggregation
          // Check the collection ID to determine if it's an expense
          if (contentType == 'balance' && doc.reference.parent.id == 'expenditure') {
            return sum - amount;
          }
          return sum + amount;
        });

        return ExpansionTile(
          title: Text('$category：${categoryTotal}円'),
          children: items.map((doc) {
            // Fix: Check if 'memo' key exists using .containsKey()
            final memo = (doc.data() as Map<String, dynamic>).containsKey('memo')
                ? doc['memo'] as String
                : '';
            final date = (doc['date'] as Timestamp).toDate();
            final formattedDate = '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
            final int amount = doc['money'] as int;
            // Fix: Access parent.id directly as it's guaranteed not to be null here
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
    } else { // contentType == 'balance'
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
      // Fix: Access parent.id directly as it's guaranteed not to be null here
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
    final totalLeft = calculateTotal(selectedMonthLeft, selectedContentTypeLeft);

    // 右側の合計を計算
    final totalRight = calculateTotal(selectedMonthRight, selectedContentTypeRight);

    return Scaffold(
      appBar: AppBar(title: const Text('収支レポート比較')),
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // 左側パネル
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        DropdownButton<String>(
                          value: selectedContentTypeLeft,
                          items: const [
                            DropdownMenuItem(value: 'income', child: Text('収入')),
                            DropdownMenuItem(value: 'expense', child: Text('支出')),
                            DropdownMenuItem(value: 'balance', child: Text('収支')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedContentTypeLeft = value!;
                            });
                          },
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
                        Expanded(child: buildMonthlyCategoryList(selectedMonthLeft, selectedContentTypeLeft)),
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
                        DropdownButton<String>(
                          value: selectedContentTypeRight,
                          items: const [
                            DropdownMenuItem(value: 'income', child: Text('収入')),
                            DropdownMenuItem(value: 'expense', child: Text('支出')),
                            DropdownMenuItem(value: 'balance', child: Text('収支')),
                          ],
                          onChanged: (value) {
                            setState(() {
                              selectedContentTypeRight = value!;
                            });
                          },
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
                        Expanded(child: buildMonthlyCategoryList(selectedMonthRight, selectedContentTypeRight)),
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