import 'package:flutter/material.dart';
import 'package:flutter_application_1/HomePage.dart';
import 'package:flutter_application_1/Income_Screen.dart';

class final_exam extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title : Text("家計簿")
      ),
      body : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('ようこそ！家計簿アプリへ', style: TextStyle(fontSize: 20)),
            SizedBox(height: 20),
            ElevatedButton(
              child: Text('収入を追加'),
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                  // （2） 実際に表示するページ(ウィジェット)を指定する
                  builder: (context) => Income_screen()
                ));
              },
            ),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/income'),
              child: Text('支出を追加'),
            ),
            //Image.asset('assets/images/c_img.jpg'), // 画像を表示
            SizedBox(height: 20), // 画像とボタンの間にスペースを追加
            TextButton(
              child: Text("最初の画面に戻る"),
              // （1） 前の画面に戻る
              onPressed: (){
                Navigator.push(context, MaterialPageRoute(
                  // （2） 実際に表示するページ(ウィジェット)を指定する
                  builder: (context) => HomePage()
                ));
              },
            ),
          ],
        ),
      )
    );
  }
}