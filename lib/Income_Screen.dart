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
  final TextEditingController _memoController = TextEditingController();

  String? _selectedCategory;
  DateTime? _selectedDate;

  final List<String> _categories = ['給料', 'ボーナス', '副業', 'おこづかい','臨時収入','その他'];

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

    if (_selectedCategory != null && amount != null && _selectedDate != null) {
      await FirebaseFirestore.instance.collection('income').add({
        'elements': _selectedCategory,
        'money': amount,
        'date': Timestamp.fromDate(_selectedDate!), 
        'memo': _memoController.text, 
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('収入データを保存しました')),
      );

      setState(() {
        _selectedCategory = null;
        _selectedDate = null;
      });
      _amountController.clear();
      _memoController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('カテゴリ、金額、日付をすべて入力してください')),
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


