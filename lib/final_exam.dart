import 'package:flutter/material.dart';
import 'package:flutter_application_1/Comparison.dart';
import 'package:flutter_application_1/Income_Screen.dart';
import 'package:flutter_application_1/Expenditure_screen.dart';
import 'package:flutter_application_1/Report.dart';

class final_exam extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "家 計 簿",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'ようこそ！家計簿アプリへ',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              _buildElevatedButton(
                context,
                text: '収入を追加',
                icon: Icons.add_circle_outline,
                page: MyFirestorePage(),
                color: Colors.green,
              ),
              const SizedBox(height: 20),
              _buildElevatedButton(
                context,
                text: '支出を追加',
                icon: Icons.remove_circle_outline,
                page: ExpenditurePage(),
                color: Colors.redAccent,
              ),
              const SizedBox(height: 20),
              _buildElevatedButton(
                context,
                text: '収支の確認',
                icon: Icons.bar_chart,
                page: Report_screen(),
                color: Colors.orange,
              ),
              const SizedBox(height: 20),
              _buildElevatedButton(
                context,
                text: '収支の比較',
                icon: Icons.compare_arrows,
                page: Comparison_screen(),
                color: Colors.blue,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElevatedButton(
      BuildContext context, {
        required String text,
        required IconData icon,
        required Widget page,
        required Color color,
      }) {
    return SizedBox(
      width: 250,
      height: 60,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(fontSize: 18, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          elevation: 8,
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => page),
          );
        },
      ),
    );
  }
}