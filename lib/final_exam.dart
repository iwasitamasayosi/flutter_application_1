import 'package:flutter/material.dart';
import 'package:flutter_application_1/Comparison.dart';
import 'package:flutter_application_1/Income_Screen.dart';
import 'package:flutter_application_1/Expenditure_screen.dart';
import 'package:flutter_application_1/Report.dart';

class final_exam extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("家計簿")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ようこそ！家計簿アプリへ', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('収入を追加'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyFirestorePage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('支出を追加'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ExpenditurePage()),
                );
              },
            ),
            ElevatedButton(
              child: Text('収支の確認'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Report_screen()),
                );
              },
            ),
            ElevatedButton(
              child: Text('収支の比較'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => Comparison_screen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
