import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  // Fireabse初期化
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
  if (selectedMonth == null) return;

  final filteredIncome = incomeList.where((doc) {
    final date = (doc['date'] as Timestamp).toDate();
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    return key == selectedMonth;
  }).toList();

  final filteredExpense = expenseList.where((doc) {
    final date = (doc['date'] as Timestamp).toDate();
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    return key == selectedMonth;
  }).toList();

  setState(() {
    totalIncome = filteredIncome.fold(0, (sum, doc) => sum + (doc['money'] as int));
    totalExpense = filteredExpense.fold(0, (sum, doc) => sum + (doc['money'] as int));
  });
}

  Future<void> fetchData() async {
  final incomeSnapshot = await FirebaseFirestore.instance.collection('income').get();
  final expenseSnapshot = await FirebaseFirestore.instance.collection('expenditure').get();

  incomeList = incomeSnapshot.docs;
  expenseList = expenseSnapshot.docs;

  // 月一覧を取得
  Set<String> months = {};
  for (var doc in [...incomeList, ...expenseList]) {
    Timestamp timestamp = doc['date'];
    DateTime date = timestamp.toDate();
    String monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
    months.add(monthKey);
  }

  setState(() {
    availableMonths = months.toList()..sort();
    selectedMonth ??= availableMonths.isNotEmpty ? availableMonths.last : null;
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

  Widget buildMonthlyCategoryList(List<DocumentSnapshot> dataList) {
    if (selectedMonth == null) return Center(child: Text('月を選択してください'));

    final filteredDocs = dataList.where((doc) {
      final date = (doc['date'] as Timestamp).toDate();
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
      return key == selectedMonth;
    }).toList();

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
            return ListTile(
              title: Text('内容：${doc['elements']}'),
              subtitle: Text('${doc['money']}円'),
            );
          }).toList(),
        );
      }).toList(),
    );
  }


  Widget buildCategoryList(List<DocumentSnapshot> dataList) {
  Map<String, List<DocumentSnapshot>> categoryMap = {};
  for (var doc in dataList) {
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
          return ListTile(
            title: Text('内容：${doc['elements']}'),
            subtitle: Text('${doc['money']}円'),
          );
        }).toList(),
      );
    }).toList(),
  );
}


  @override
  Widget build(BuildContext context) {
    int balance = totalIncome - totalExpense;

    return Scaffold(
      appBar: AppBar(title: Text('収支レポート')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('収入合計：${totalIncome}円', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('支出合計：${totalExpense}円', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text('収支：${balance}円', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: balance >= 0 ? Colors.green : Colors.red)),
              ],
            ),
          ),

          DropdownButton<String>(
            value: selectedMonth,
            hint: Text('月を選択'),
            items: availableMonths.map((month) {
              return DropdownMenuItem(
                value: month,
                child: Text(month),
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
               buildMonthlyCategoryList(incomeList),
               buildMonthlyCategoryList(expenseList),
              ],
            ),
          ),
          ElevatedButton(
            child: Text('収支を再取得'),
            onPressed: fetchData,
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


