import 'package:flutter/material.dart';

class ThirdPage extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title : Text("ページ(3)")
      ),
      body : Center(
        child: TextButton(
          child: Text("最初のページに戻る"),
          // （1） 前の画面に戻る
          onPressed: (){
            //1ページ前に戻す場合
            //Navigator.pop(context);
            //最初のページに戻す場合
            Navigator.popUntil(context, (route) => route.isFirst);
          },
        ),
      )
    );
  }
}