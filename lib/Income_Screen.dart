import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_application_1/final_exam.dart';

class Income_screen extends StatelessWidget {
  final TextEditingController _contentController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  Income_screen({super.key});

  void _saveIncome(BuildContext context) async {
    String content = _contentController.text;
    String amount = _amountController.text;

    if (content.isNotEmpty && amount.isNotEmpty) {
      try {
        await FirebaseFirestore.instance.collection('incomes').add({
          'content': content,
          'amount': int.tryParse(amount) ?? 0,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('収入が保存されました')),
        );

        _contentController.clear();
        _amountController.clear();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存に失敗しました: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('すべての項目を入力してください')),
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
          children: [
            TextFormField(
              controller: _contentController,
              decoration: InputDecoration(labelText: '収入の内容'),
            ),
            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(labelText: '金額'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => _saveIncome(context),
              child: Text("保存"),
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
