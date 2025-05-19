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
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: Report_screen(),
    );
  }
}

class Report_screen extends StatefulWidget {
  @override
  Report createState() => Report();
}

class Report extends State<Report_screen> {

  // 作成したドキュメント一覧
  List<DocumentSnapshot> documentList = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          children: <Widget>[
            ElevatedButton(
              child: Text('ドキュメント一覧取得'),
              onPressed: () async {
                // コレクション内のドキュメント一覧を取得
                final snapshot =
                    await FirebaseFirestore.instance.collection('income').get();
                // 取得したドキュメント一覧をUIに反映
                setState(() {
                  documentList = snapshot.docs;
                });
              },
            ),
            // コレクション内のドキュメント一覧を表示
            Column(
              children: documentList.map((document) {
                return ListTile(
                  title: Text('内容：${document['elements']}'),
                  subtitle: Text('${document['money']}円'),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}