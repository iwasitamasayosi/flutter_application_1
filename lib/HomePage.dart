import 'package:flutter/material.dart';
import 'package:flutter_application_1/final_exam.dart';
import 'package:flutter_application_1/Firstpage.dart'; // Import SecondPage

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("ホーム"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              child: Text("期末試験専用画面に遷移する"),
              onPressed: () {
                // Navigate to final_exam page
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => final_exam(),
                ));
              },
            ),
            TextButton(
              child: Text("1ページ目に遷移する"),
              onPressed: () {
                // Navigate to SecondPage
                Navigator.push(context, MaterialPageRoute(
                  builder: (context) => FirstPage(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}