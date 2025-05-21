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
      title: '収入記入画面',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyFirestorePage(),
    );
  }
}

class MyFirestorePage extends StatefulWidget {
  @override
  Income_screen createState() => Income_screen();
}

class Income_screen extends State<MyFirestorePage> {
  final TextEditingController _amountController = TextEditingController();
  String? _selectedCategory;

  final List<String> _categories = ['給料', 'ボーナス', '副業', 'おこづかい','臨時収入'];

  Future<void> _saveIncomeData() async {
    final int? amount = int.tryParse(_amountController.text);

    if (_selectedCategory != null && amount != null) {
      await FirebaseFirestore.instance.collection('income').add({
        'elements': _selectedCategory,
        'money': amount,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('収入データを保存しました')),
      );

      setState(() {
        _selectedCategory = null;
      });
      _amountController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('カテゴリと正しい金額を入力してください')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("収入追加画面")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(labelText: '収入のカテゴリ'),
              items: _categories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                });
              },
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

