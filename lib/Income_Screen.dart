import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

Future<void> main() async {
  // Firebase初期化
  WidgetsFlutterBinding.ensureInitialized();
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
        primarySwatch: Colors.lightBlue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.lightBlue,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.grey.shade400),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.0),
            borderSide: BorderSide(color: Colors.lightBlue, width: 2.0),
          ),
          labelStyle: TextStyle(color: Colors.grey.shade700),
          contentPadding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: Colors.lightBlue,
            padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 24.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            textStyle: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: Colors.lightBlue.shade700,
          ),
        ),
      ),
      home: MyFirestorePage(),
    );
  }
}

class MyFirestorePage extends StatefulWidget {
  @override
  _IncomeScreenState createState() => _IncomeScreenState();
}

class _IncomeScreenState extends State<MyFirestorePage> { 
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _memoController = TextEditingController();

  String? _selectedCategory;
  DateTime? _selectedDate;

  final List<String> _categories = ['給料', 'ボーナス', '副業', 'おこづかい', '臨時収入', 'その他'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now(); 
  }

  @override
  void dispose() {
    _amountController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: '収入日を選択', 
      cancelText: 'キャンセル',
      confirmText: '選択',
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.lightBlue,
              onPrimary: Colors.white, 
              onSurface: Colors.black, 
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.lightBlue,
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _saveIncomeData() async {
    final int? amount = int.tryParse(_amountController.text);

    if (_selectedCategory == null || amount == null || _selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('カテゴリ、金額、日付をすべて入力してください', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('income').add({
        'elements': _selectedCategory,
        'money': amount,
        'date': Timestamp.fromDate(_selectedDate!),
        'memo': _memoController.text.isEmpty ? null : _memoController.text, 
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('収入データを保存しました！', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.green, 
          duration: Duration(seconds: 2),
        ),
      );

      setState(() {
        _selectedCategory = null; // 今日の日付にリセット
      });
      _amountController.clear();
      _memoController.clear();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('データの保存中にエラーが発生しました: $e', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.redAccent,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("収入追加"),
        centerTitle: true,
        elevation: 4.0, 
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: InputDecoration(
                labelText: '収入のカテゴリ',
                prefixIcon: Icon(Icons.category, color: Colors.lightBlue),
              ),
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
              hint: Text('カテゴリを選択してください'),
            ),
            SizedBox(height: 20),

            TextFormField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: '金額',
                hintText: '例: 50000',
                prefixIcon: Icon(Icons.attach_money, color: Colors.lightBlue),
              ),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 20),

            TextFormField(
              controller: _memoController,
              decoration: InputDecoration(
                labelText: 'メモ（任意）',
                hintText: '例: 6月分の給料',
                prefixIcon: Icon(Icons.edit_note, color: Colors.lightBlue),
              ),
              keyboardType: TextInputType.text,
              maxLines: 3, 
            ),
            SizedBox(height: 20),

            Card(
              elevation: 2.0,
              margin: EdgeInsets.zero,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today, color: Colors.lightBlue),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _selectedDate == null
                            ? '日付が選択されていません'
                            : '選択された日付: ${DateFormat('yyyy年MM月dd日').format(_selectedDate!)}', 
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade800),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _pickDate,
                      icon: Icon(Icons.edit),
                      label: Text('日付を選択'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            ElevatedButton(
              onPressed: _saveIncomeData,
              child: Text('収入を保存する'),
            ),
          ],
        ),
      ),
    );
  }
}