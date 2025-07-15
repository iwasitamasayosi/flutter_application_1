import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
  late TabController _tabController; // このTabControllerは今回は使わないですが、残しておきます。
  String? selectedMonth;
  List<String> availableMonths = [];

  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  Map<DateTime, List<int>> dailyBalances = {}; // 日ごとの収支を保持するマップ

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // タブは使わないが初期化は必要
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

  void calculateDailyBalances() {
    dailyBalances.clear();
    for (var doc in incomeList) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      dailyBalances.putIfAbsent(normalizedDate, () => [0, 0])[0] +=
          (doc['money'] as int); // 収入
    }
    for (var doc in expenseList) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      dailyBalances.putIfAbsent(normalizedDate, () => [0, 0])[1] +=
          (doc['money'] as int); // 支出
    }
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
      calculateDailyBalances(); // 日ごとの収支を計算
    });

    updateTotals();
  }

  // --- 編集機能の追加部分 ---
  Future<void> _showEditDialog(
      DocumentSnapshot doc, String collectionName) async {
    TextEditingController elementsController =
        TextEditingController(text: doc['elements'] ?? '');
    TextEditingController moneyController =
        TextEditingController(text: (doc['money'] ?? 0).toString());
    TextEditingController memoController = TextEditingController(
        text: (doc.data() as Map<String, dynamic>).containsKey('memo')
            ? doc['memo']
            : '');
    DateTime selectedDateInDialog = (doc['date'] as Timestamp).toDate();

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
                          '日付: ${DateFormat('yyyy年MM月dd日').format(selectedDateInDialog)}'),
                      trailing: Icon(Icons.calendar_today),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context,
                          initialDate: selectedDateInDialog,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2101),
                        );
                        if (picked != null && picked != selectedDateInDialog) {
                          setDialogState(() {
                            selectedDateInDialog = picked;
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
                        'date': Timestamp.fromDate(selectedDateInDialog),
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

  Widget buildCombinedMonthlyList() {
    // selectedMonthがnullの場合のハンドリング
    if (selectedMonth == null && availableMonths.isNotEmpty) {
      selectedMonth = availableMonths.first;
    }

    if (selectedMonth == null) {
      return Center(child: Text('月を選択してください'));
    }

    // 収入と支出のデータを結合
    List<DocumentSnapshot> combinedList = [...incomeList, ...expenseList];

    // 選択された月にフィルタリング
    final filteredDocs = selectedMonth == 'All'
        ? combinedList
        : combinedList.where((doc) {
            final date = (doc['date'] as Timestamp).toDate();
            final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            return key == selectedMonth;
          }).toList();

    if (filteredDocs.isEmpty) {
      return Center(child: Text('データがありません'));
    }

    // 日付でグループ化
    Map<DateTime, List<DocumentSnapshot>> dailyMap = {};
    for (var doc in filteredDocs) {
      DateTime date = (doc['date'] as Timestamp).toDate();
      DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      dailyMap.putIfAbsent(normalizedDate, () => []).add(doc);
    }

    // 日付の新しい順にソート
    final sortedDates = dailyMap.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // 新しい日付が上に来るように降順ソート

    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        DateTime date = sortedDates[index];
        List<DocumentSnapshot> items = dailyMap[date]!;
        String formattedDate = DateFormat('yyyy年MM月dd日').format(date);

        // その日の合計収支を計算
        int dailyIncomeSum = items
            .where((doc) => incomeList.contains(doc))
            .fold(0, (sum, doc) => sum + (doc['money'] as int));
        int dailyExpenseSum = items
            .where((doc) => expenseList.contains(doc))
            .fold(0, (sum, doc) => sum + (doc['money'] as int));
        int dailyBalance = dailyIncomeSum - dailyExpenseSum;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ExpansionTile(
            title: Text(
              '$formattedDate',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '収支: ${dailyBalance}円',
              style: TextStyle(
                color: dailyBalance >= 0 ? Colors.green[700] : Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            children: items.map((doc) {
              final isIncome = incomeList.contains(doc);
              final money = doc['money'] as int;
              final moneyText = isIncome ? '＋${money}円' : 'ー${money}円';
              final moneyColor = isIncome ? Colors.blue : Colors.red;

              return ListTile(
                title: Text('${doc['elements']}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(moneyText, style: TextStyle(color: moneyColor)),
                    if ((doc.data() as Map<String, dynamic>).containsKey('memo') &&
                        (doc['memo'] as String).isNotEmpty)
                      Text('メモ：${doc['memo']}',
                          style: TextStyle(color: Colors.grey[700], fontSize: 12)),
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () => _showEditDialog(
                      doc, isIncome ? 'income' : 'expenditure'),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    int balance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(title: Text('収支確認画面')),
      body: Row(
        children: [
          // 左側のカレンダー部分
          Expanded(
            flex: 2,
            child: Column(
              children: [
                TableCalendar(
                  firstDay: DateTime.utc(2000, 1, 1),
                  lastDay: DateTime.utc(2050, 12, 31),
                  focusedDay: _focusedDay,
                  calendarFormat: _calendarFormat,
                  selectedDayPredicate: (day) {
                    return isSameDay(_selectedDay, day);
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                  onFormatChanged: (format) {
                    if (_calendarFormat != format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    }
                  },
                  onPageChanged: (focusedDay) {
                    _focusedDay = focusedDay;
                    final newMonthKey =
                        '${focusedDay.year}-${focusedDay.month.toString().padLeft(2, '0')}';
                    if (availableMonths.contains(newMonthKey)) {
                      setState(() {
                        selectedMonth = newMonthKey;
                        updateTotals();
                      });
                    } else if (availableMonths.contains('All') &&
                        newMonthKey != 'All') {
                      // 新しい月が利用可能な月に含まれていない場合、'All'に設定
                      setState(() {
                        selectedMonth = 'All';
                        updateTotals();
                      });
                    }
                  },
                  calendarBuilders: CalendarBuilders(
                    markerBuilder: (context, date, events) {
                      final normalizedDate =
                          DateTime(date.year, date.month, date.day);
                      if (dailyBalances.containsKey(normalizedDate)) {
                        final dailyIncome = dailyBalances[normalizedDate]![0];
                        final dailyExpense = dailyBalances[normalizedDate]![1];
                        final dailyBalance = dailyIncome - dailyExpense;

                        return Positioned(
                          bottom: 1,
                          child: Text(
                            '$dailyBalance',
                            style: TextStyle(
                              fontSize: 10,
                              color:
                                  dailyBalance >= 0 ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }
                      return null;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('収入合計：${totalIncome}円',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('支出合計：${totalExpense}円',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      Text('収支：${balance}円',
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: balance >= 0 ? Colors.green : Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // 右側の選択月の収支情報
          Expanded(
            flex: 3,
            child: Column(
              children: [
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
                      if (value != 'All' && value != null) {
                        final parts = value.split('-');
                        _focusedDay = DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
                      } else {
                        _focusedDay = DateTime.now();
                      }
                      updateTotals();
                    });
                  },
                ),
                // タブバーは今回使用しないため削除またはコメントアウト
                // TabBar(
                //   controller: _tabController,
                //   tabs: [
                //     Tab(text: '収入'),
                //     Tab(text: '支出'),
                //   ],
                //   labelColor: Colors.blue,
                //   unselectedLabelColor: Colors.grey,
                // ),
                Expanded(
                  child: buildCombinedMonthlyList(), // 結合されたリストを表示
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