import 'package:flutter/material.dart'; // 导入Flutter材料设计库
import 'package:shared_preferences/shared_preferences.dart'; // 导入本地存储库
import 'dart:convert'; // 导入JSON编解码支持
import 'dart:io'; // 添加这一行
import 'package:intl/intl.dart'; // 导入国际化日期格式化库
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart'; // 改用 provider 包
import './providers/theme_provider.dart';

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
  String? selectedEmoji;
  List<Map<String, dynamic>> temporaryEmojis = [];
  late ThemeProvider themeProvider;

  // 添加新的状态变量
  bool _isReversed = false;
  bool _showDeleteButtons = false;

  // 选择图片
  Future<void> _pickImage() async {
    final List<XFile> images = await _picker.pickMultiImage();
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
    temporaryEmojis = []; // 重置临时emoji列表
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
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
    if (_diaryController.text.isNotEmpty && selectedEmoji != null) {
      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(now);
      setState(() {
        diaries.add({
          'date': formattedDate,
          'content': _diaryController.text,
          'mood': selectedEmoji!,
          'imagePaths': jsonEncode(_selectedImagePaths),
        });
        _saveDiaries();
        _diaryController.clear();
        _selectedImagePaths = [];
        
        // 如果使用的是临时emoji，则移除它
        if (temporaryEmojis.any((e) => e['emoji'] == selectedEmoji)) {
          temporaryEmojis.removeWhere((e) => e['emoji'] == selectedEmoji);
        }
        selectedEmoji = null;
      });
    }
  }

  // 添加删除日记方法
  void _deleteDiary(int index) {
    setState(() {
      diaries.removeAt(index);
      _saveDiaries();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // 替换原来的心情选择器
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...themeProvider.diaryEmojis.map((emoji) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedEmoji = selectedEmoji == emoji['emoji'] ? null : emoji['emoji'];
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedEmoji == emoji['emoji'] 
                                ? Theme.of(context).primaryColor 
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          emoji['emoji'],
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                }),
                ...temporaryEmojis.map((emoji) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedEmoji = selectedEmoji == emoji['emoji'] ? null : emoji['emoji'];
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedEmoji == emoji['emoji'] 
                                ? Theme.of(context).primaryColor 
                                : Colors.transparent,
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          emoji['emoji'],
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                  );
                }),
                // 添加临时emoji的按钮
                IconButton(
                  icon: Icon(Icons.add_circle_outline),
                  onPressed: _addTemporaryEmoji,
                ),
              ],
            ),
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
          //SizedBox(height:10),
          // 在日记列表前添加操作按钮行
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.image),
                        onPressed: _pickImage,
                      ),
                    ),
                    if (_selectedImagePaths.isNotEmpty)
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _selectedImagePaths.length,
                          itemBuilder: (context, index) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: GestureDetector(
                                onTap: () => _showFullImage(context, _selectedImagePaths, index),
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
                  ],
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _isReversed = !_isReversed;
                      });
                    },
                    icon: Icon(_isReversed ? Icons.arrow_upward : Icons.arrow_downward),
                    label: Text(_isReversed ? '正序' : '倒序'),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _showDeleteButtons = !_showDeleteButtons;
                      });
                    },
                    icon: Icon(_showDeleteButtons ? Icons.check : Icons.delete_outline),
                    label: Text(_showDeleteButtons ? '完成' : '删除'),
                  ),
                ],
              ),
            ],
          ),
          // 修改日记列表部分
          Expanded(
            child: ListView.builder(
              itemCount: diaries.length,
              itemBuilder: (context, index) {
                final diary = _isReversed 
                    ? diaries[diaries.length - 1 - index]
                    : diaries[index];
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
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            leading: Text(diary['mood'] ?? '😐', style: TextStyle(fontSize: 24)),
                            title: Text(diary['content'] ?? ''),
                            subtitle: Text(formattedDate),
                          ),
                          if (imagePaths.isNotEmpty)
                            SizedBox(
                              height: 100,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: imagePaths.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: GestureDetector(
                                      onTap: () => _showFullImage(context, imagePaths, index),
                                      child: Image.file(
                                        File(imagePaths[index]),
                                        height: 100,
                                        width: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                        ],
                      ),
                      if (_showDeleteButtons)
                        Positioned(
                          right: 8,
                          bottom: 8,
                          child: IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: Colors.red),
                            onPressed: () => _deleteDiary(_isReversed 
                                ? diaries.length - 1 - index 
                                : index),
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

  // 修改查看大图方法
  void _showFullImage(BuildContext context, List<String> imagePaths, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            // 图片查看器
            PageView.builder(
              controller: PageController(initialPage: initialIndex),
              itemCount: imagePaths.length,
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.file(
                      File(imagePaths[index]),
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
            // 关闭钮
            Positioned(
              right: 10,
              top: 10,
              child: IconButton(
                icon: Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 添加临时表情的方法
  void _addTemporaryEmoji() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        String emoji = '😊';
        return AlertDialog(
          title: Text('添加临时表情'),
          content: TextField(
            decoration: InputDecoration(labelText: 'Emoji'),
            onChanged: (value) => emoji = value,
          ),
          actions: [
            TextButton(
              child: Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('添加'),
              onPressed: () {
                Navigator.of(context).pop({
                  'emoji': emoji,
                });
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        temporaryEmojis.add(result);
        selectedEmoji = result['emoji'];
      });
    }
  }
}



