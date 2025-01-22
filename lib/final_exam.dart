import 'package:flutter/material.dart';
import 'package:flutter_application_1/HomePage.dart';

class final_exam extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title : Text("期末試験専用画面")
      ),
      body : Center(
        child: TextButton(
          child: Text("最初の画面に戻る"),
          // （1） 前の画面に戻る
          onPressed: (){
            Navigator.push(context, MaterialPageRoute(
              // （2） 実際に表示するページ(ウィジェット)を指定する
              builder: (context) => HomePage()
            ));
          },
        ),
      )
    );
  }
}