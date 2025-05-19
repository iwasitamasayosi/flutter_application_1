import 'package:flutter/material.dart';
import 'package:flutter_application_1/final_exam.dart';
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
      title: '支出記入画面',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Expenditure(),
    );
  }
}

class Expenditure extends StatefulWidget {
  @override
  Expenditure_screen createState() => Expenditure_screen();
}

class Expenditure_screen extends State<Expenditure> {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Future<void> _saveIncomeData() async {
    final String content = _contentController.text;
    final int? amount = int.tryParse(_amountController.text);

    if (content.isNotEmpty && amount != null) {
      await FirebaseFirestore.instance
        .collection('expenditure')
        .add({
          'elements': content,
          'money': amount,
        });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('支出データを保存しました')),
      );

      _contentController.clear();
      _amountController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('正しい内容と金額を入力してください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("支出追加画面")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(labelText: '支出の内容'),
            ),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(labelText: '金額'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveIncomeData,
              child: Text('保存する'),
            ),
            TextButton(
              child: Text("ホーム画面に戻る"),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => final_exam()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
