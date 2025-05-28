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
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  DateTime? _selectedDate;
  String? _selectedCategory;

  final List<String> _categories = ['食費', '交通費', '娯楽', '日用品', '医療', 'その他'];

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveIncomeData() async {
    final int? amount = int.tryParse(_amountController.text);

    if (amount != null && _selectedDate != null && _selectedCategory != null) {
      await FirebaseFirestore.instance
          .collection('expenditure')
          .add({
            'money': amount,
            'date': Timestamp.fromDate(_selectedDate!),
            'elements': _selectedCategory,
            'memo': _memoController.text, 
          });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('支出データを保存しました')),
      );

      _amountController.clear();
      _memoController.clear();
      setState(() {
        _selectedDate = null;
        _selectedCategory = null;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('金額、日付、カテゴリをすべて入力してください')),
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
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(labelText: 'カテゴリを選択'),
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
            TextFormField(
              controller: _memoController,
              decoration: InputDecoration(labelText: 'メモ（任意）'),
              keyboardType: TextInputType.text,
            ),
            SizedBox(height: 10),
            Row(
              children: [
                Text(
                  _selectedDate == null
                      ? '日付が選択されていません'
                      : '選択された日付: ${_selectedDate!.toLocal().toString().split(' ')[0]}',
                ),
                Spacer(),
                TextButton(
                  onPressed: _pickDate,
                  child: Text('日付を選択'),
                ),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveIncomeData,
              child: Text('保存する'),
            ),
          ],
        ),
      ),
    );
  }
}



