import 'package:flutter/material.dart'; // 导入Flutter材料设计库
import 'package:shared_preferences/shared_preferences.dart'; // 导入本地存储库
import 'dart:convert'; // 导入JSON编解码支持
import 'package:intl/intl.dart'; // 导入国际化日期格式化库

// 日记页面
class DiaryPage extends StatefulWidget {
  @override
  DiaryPageState createState() => DiaryPageState();
}

class DiaryPageState extends State<DiaryPage> {
  // 日记内容输入控制器
  final _diaryController = TextEditingController();
  // 存储日记条目的列表
  List<Map<String, String>> diaries = [];
  // 当前选择的心情
  String _selectedMood = '😊';
  // 可选的心情列表
  final List<String> _moods = ['😊', '😐', '😢', '😎', '😴','🤣','🥰',];

  @override
  void initState() {
    super.initState();
    _loadDiaries();  // 初始化时加载日记
  }

  // 从本地存储加载日记
  void _loadDiaries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDiaries = prefs.getString('diaries');
    setState(() {
      diaries = savedDiaries != null
          ? List<Map<String, String>>.from(
              (jsonDecode(savedDiaries) as List).map((item) => Map<String, String>.from(item))
            )
          : [];
    });
    }

  // 保存日记到本地存储
  void _saveDiaries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(diaries.map((diary) => 
      Map<String, String>.from(diary)
    ).toList());
    await prefs.setString('diaries', jsonString);
  }

  // 添加新的日记条目
  void _addDiary() {
    if (_diaryController.text.isNotEmpty) {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      setState(() {
        diaries.add({
          'date': formattedDate,
          'content': _diaryController.text,
          'mood': _selectedMood,
        });
        _saveDiaries();
        _diaryController.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 心情选择器
          Row(
            children: _moods.map((mood) {
              return IconButton(
                icon: Text(mood, style: TextStyle(fontSize: 24)),
                onPressed: () {
                  setState(() {
                    _selectedMood = mood;
                  });
                },
              );
            }).toList(),
          ),
          // 日记输入框
          TextField(
            controller: _diaryController,
            decoration: InputDecoration(
              labelText: '今日日记',
              labelStyle: TextStyle(
                color: const Color.fromARGB(255, 100, 100, 100),
              ),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: const Color.fromARGB(255, 214, 214, 214),
                  width: 1.5,
                ),
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black,
                  width: 2.0,
                ),
              ),
              suffixIcon: IconButton(
                icon: Icon(
                  Icons.save,
                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black,
                ),
                onPressed: _addDiary,
              ),
            ),
            cursorColor: const Color.fromARGB(255, 214, 214, 214),
            maxLines: 3,
          ),
          SizedBox(height:10),
          // 日记列表
          Expanded(
            child: ListView.builder(
              itemCount: diaries.length,
              itemBuilder: (context, index) {
                final diary = diaries[index];
                final date = diary['date'] as String;
                final formattedDate = date.length > 19 ? date.substring(0, 19) : date;
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Text(diary['mood'] ?? '😐', style: TextStyle(fontSize: 24)),
                    title: Text(diary['content'] ?? ''),
                    subtitle: Text(formattedDate),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}



