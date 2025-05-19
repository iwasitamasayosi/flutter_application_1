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

class Report extends State<Report_screen> {
  List<DocumentSnapshot> incomeList = [];
  List<DocumentSnapshot> expenseList = [];

  Future<void> fetchData() async {
    final incomeSnapshot =
        await FirebaseFirestore.instance.collection('income').get();
    final expenseSnapshot =
        await FirebaseFirestore.instance.collection('expenditure').get();

    setState(() {
      incomeList = incomeSnapshot.docs;
      expenseList = expenseSnapshot.docs;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              ElevatedButton(
                child: Text('収支を取得'),
                onPressed: fetchData,
              ),
              Text('【収入】', style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
                children: incomeList.map((document) {
                  return ListTile(
                    title: Text('内容：${document['elements']}'),
                    subtitle: Text('${document['money']}円'),
                  );
                }).toList(),
              ),
              Text('【支出】', style: TextStyle(fontWeight: FontWeight.bold)),
              Column(
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
      ),
    );
  }
}
