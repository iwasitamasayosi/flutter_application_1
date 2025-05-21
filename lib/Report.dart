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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this, initialIndex: 1);
    fetchData();
  }

  Future<void> fetchData() async {
    final incomeSnapshot =
        await FirebaseFirestore.instance.collection('income').get();
    final expenseSnapshot =
        await FirebaseFirestore.instance.collection('expenditure').get();

    setState(() {
      incomeList = incomeSnapshot.docs;
      expenseList = expenseSnapshot.docs;

      totalIncome = incomeList.fold(0, (sum, doc) => sum + (doc['money'] as int));
      totalExpense = expenseList.fold(0, (sum, doc) => sum + (doc['money'] as int));
    });
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
                // 収入リスト
                ListView(
                  children: incomeList.map((document) {
                    return ListTile(
                      title: Text('内容：${document['elements']}'),
                      subtitle: Text('${document['money']}円'),
                    );
                  }).toList(),
                ),
                // 支出リスト
                ListView(
                  children: expenseList.map((document) {
                    return ListTile(
                      title: Text('内容：${document['elements']}'),
                      subtitle: Text('${document['money']}円'),
                    );
                  }).toList(),
                ),
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


