import 'package:flutter/material.dart';
import 'package:flutter_application_1/final_exam.dart';

class Income_screen extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title : Text("収入追加画面")
      ),
      body : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: '収入の内容'),
            ),
            TextFormField(
              decoration: InputDecoration(labelText: '金額'),
            ), // 画像とボタンの間にスペースを追加
            TextButton(
              child: Text("ホーム画面に戻る"),
              // （1） 前の画面に戻る
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                  // （2） 実際に表示するページ(ウィジェット)を指定する
                  builder: (context) => final_exam()
                ));
              },
            ),
          ],
        ),
      )
    );
  }
}