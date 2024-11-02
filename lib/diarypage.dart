import 'package:flutter/material.dart'; // 导入Flutter材料设计库
import 'package:shared_preferences/shared_preferences.dart'; // 导入本地存储库
import 'dart:convert'; // 导入JSON编解码支持
import 'dart:io'; // 添加这一行
import 'package:intl/intl.dart'; // 导入国际化日期格式化库
import 'package:image_picker/image_picker.dart';

// 日记页面
class DiaryPage extends StatefulWidget {
  @override
  DiaryPageState createState() => DiaryPageState();
}

class DiaryPageState extends State<DiaryPage> {
  // 日记内容输入控制器
  final _diaryController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedImagePaths = [];

  // 存储日记条目的列表
  List<Map<String, String>> diaries = [];
  // 当前选择的心情
  String _selectedMood = '😊';
  // 可选的心情列表
  final List<String> _moods = ['😊', '😐', '😢', '😎', '😴','🤣','🥰',];

  // 选择图片
  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage() ?? [];
    if (images.isNotEmpty) {
      setState(() {
        _selectedImagePaths.addAll(images.map((image) => image.path));
      });
    }
  }

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

  // 修改添加日记的方法
  void _addDiary() {
    if (_diaryController.text.isNotEmpty) {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      setState(() {
        diaries.add({
          'date': formattedDate,
          'content': _diaryController.text,
          'mood': _selectedMood,
          'imagePaths': jsonEncode(_selectedImagePaths), // 将图片路径列表转换为JSON字符串
        });
        _saveDiaries();
        _diaryController.clear();
        _selectedImagePaths = []; // 清除已选择的图片
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
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.image),
                onPressed: _pickImage,
              ),
              if (_selectedImagePaths.isNotEmpty)
                Expanded(
                  child: Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _selectedImagePaths.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: GestureDetector(
                            onTap: () => _showFullImage(context, _selectedImagePaths[index]),
                            child: Image.file(
                              File(_selectedImagePaths[index]),
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
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
                List<String> imagePaths = [];
                try {
                  imagePaths = List<String>.from(jsonDecode(diary['imagePaths'] ?? '[]'));
                } catch (e) {
                  print('Error decoding image paths: $e');
                }

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        leading: Text(diary['mood'] ?? '😐', style: TextStyle(fontSize: 24)),
                        title: Text(diary['content'] ?? ''),
                        subtitle: Text(formattedDate),
                      ),
                      if (imagePaths.isNotEmpty)
                        Container(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: imagePaths.length,
                            itemBuilder: (context, imageIndex) {
                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: GestureDetector(
                                  onTap: () => _showFullImage(context, imagePaths[imageIndex]),
                                  child: Image.file(
                                    File(imagePaths[imageIndex]),
                                    height: 200,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 添加查看大图方法
  void _showFullImage(BuildContext context, String imagePath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          body: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Center(
              child: InteractiveViewer(
                panEnabled: true,
                boundaryMargin: EdgeInsets.all(20),
                minScale: 0.5,
                maxScale: 4,
                child: Image.file(File(imagePath)),
              ),
            ),
          ),
        ),
      ),
    );
  }
}



