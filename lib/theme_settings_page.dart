import 'package:flutter/material.dart'; // 导入Flutter材料设计库
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // 导入颜色选择器库
import 'package:provider/provider.dart'; // 导入状态管理库
import '../providers/theme_provider.dart'; // 导入主题提供者
import 'package:image_picker/image_picker.dart'; // 添加这行
import 'dart:io';

// 定义一个有状态的主题设置页面小部件
class ThemeSettingsPage extends StatefulWidget {
  @override
  ThemeSettingsPageState createState() => ThemeSettingsPageState(); // 创建主题设置页面的状态
}

// 定义主题设置页面的状态类
class ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late Color primaryColor; // 主题主色
  late Color scaffoldBackgroundColor; // 脚手架背景色
  late Color cardColor; // 卡片颜色
  late Color themeTextColor; // 主题文本颜色
  String? backgroundImage; // 添加这一行
  late List<Map<String, dynamic>> categories;
  late ThemeProvider themeProvider;
  bool _isEditMode = false;
  bool _isDeleteMode = false;

  @override
  void initState() {
    super.initState();
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _loadCurrentTheme();
    _loadCategories();
  }

  // 加载当前主题颜色
  void _loadCurrentTheme() {
    final theme = themeProvider.themeData;
    setState(() {
      primaryColor = theme.primaryColor;
      scaffoldBackgroundColor = theme.scaffoldBackgroundColor;
      cardColor = theme.cardTheme.color ?? theme.cardColor;
      themeTextColor = theme.appBarTheme.foregroundColor ?? theme.primaryColor;
    });
  }

  void _loadCategories() {
    setState(() {
      categories = themeProvider.categories;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('设置')),
      backgroundColor: scaffoldBackgroundColor,
      body: Container(
        decoration: backgroundImage != null
            ? BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(backgroundImage!)),
                  fit: BoxFit.cover,
                ),
              )
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: ListView(
            children: [
              _buildColorPicker('主题色Ⅰ', primaryColor, (color) => setState(() => primaryColor = color)),
              _buildColorPicker('主题色Ⅱ', themeTextColor, (color) => setState(() => themeTextColor = color)),
              _buildColorPicker('背景色', scaffoldBackgroundColor, (color) => setState(() => scaffoldBackgroundColor = color)),
              _buildColorPicker('卡片颜色', cardColor, (color) => setState(() => cardColor = color)),
              Divider(),
              ListTile(
                title: Text('常用标签'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.edit),
                      color: _isEditMode ? Theme.of(context).primaryColor : null,
                      onPressed: () {
                        setState(() {
                          _isEditMode = !_isEditMode;
                          _isDeleteMode = false;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete),
                      color: _isDeleteMode ? Theme.of(context).primaryColor : null,
                      onPressed: () {
                        setState(() {
                          _isDeleteMode = !_isDeleteMode;
                          _isEditMode = false;
                        });
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () {
                        _addCategory();
                        setState(() {
                          _isEditMode = false;
                          _isDeleteMode = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              _buildCategoryList(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveTheme, // 保存主题
        backgroundColor: primaryColor,
        child: Icon(Icons.save, color: themeTextColor),
      ),
    );
  }

  // 构建颜色选择器
  Widget _buildColorPicker(String label, Color color, ValueChanged<Color> onColorChanged) {
    if (label == '背景色') {
      return ListTile(
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () => _showColorPicker(label, color, onColorChanged),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey),
                ),
              ),
            ),
            SizedBox(width: 8),
            IconButton(
              icon: Icon(Icons.image),
              onPressed: _pickBackgroundImage,
            ),
          ],
        ),
      );
    }
    return ListTile(
      title: Text(label),
      trailing: GestureDetector(
        onTap: () => _showColorPicker(label, color, onColorChanged),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  // 显示颜色选择器对话框
  Future<void> _showColorPicker(String label, Color initialColor, ValueChanged<Color> onColorChanged) async {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color selectedColor = initialColor;
        return AlertDialog(
          title: Text('选择颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('确定'),
              onPressed: () {
                onColorChanged(selectedColor);
                print('$label 颜色已更改为: ${selectedColor.value.toRadixString(16)}');
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickBackgroundImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      setState(() {
        backgroundImage = image.path;
      });
    }
  }

  // 保存主题
  void _saveTheme() {
    final newTheme = ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardTheme: CardTheme(
        color: cardColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: themeTextColor,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: primaryColor,
        selectedItemColor: themeTextColor,
        unselectedItemColor: themeTextColor.withOpacity(0.6),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: themeTextColor),
        bodyMedium: TextStyle(color: themeTextColor),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardColor,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
      ),
    );
    themeProvider.setTheme(newTheme);
    themeProvider.setBackgroundImage(backgroundImage); // 添加这行
    themeProvider.setCategories(categories);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('主题已保存')));
  }

  Widget _buildCategoryList() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.center,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: categories.map((category) {
            return GestureDetector(
              onTap: () {
                if (_isEditMode) {
                  _editCategory(category);
                } else if (_isDeleteMode) {
                  _deleteCategory(category);
                }
              },
              child: Chip(
                avatar: Text(category['emoji']),
                label: Text(category['label']),
                backgroundColor: (category['color'] as Color).withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: Theme.of(context).cardColor,
                    width: 1,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _editCategory(Map<String, dynamic> category) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        String emoji = category['emoji'];
        String label = category['label'];
        Color color = category['color'];
        return AlertDialog(
          title: Text('编辑类别'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Emoji'),
                onChanged: (value) => emoji = value,
                controller: TextEditingController(text: emoji),
              ),
              TextField(
                decoration: InputDecoration(labelText: '标签'),
                onChanged: (value) => label = value,
                controller: TextEditingController(text: label),
              ),
              ElevatedButton(
                child: Text('选择颜色'),
                onPressed: () async {
                  final Color? newColor = await showColorPicker(context, color);
                  if (newColor != null) {
                    color = newColor;
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('取消'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: Text('保存'),
              onPressed: () {
                Navigator.of(context).pop({
                  'emoji': emoji,
                  'label': label,
                  'color': color,
                });
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        category['emoji'] = result['emoji'];
        category['label'] = result['label'];
        category['color'] = result['color'];
      });
      _saveCategories();
    }
  }

  void _deleteCategory(Map<String, dynamic> category) {
    setState(() {
      categories.remove(category);
    });
    _saveCategories();
  }

  void _addCategory() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        String emoji = '😀';
        String label = '';
        Color color = Colors.blue;
        return AlertDialog(
          title: Text('添加新类别'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(labelText: 'Emoji'),
                onChanged: (value) => emoji = value,
              ),
              TextField(
                decoration: InputDecoration(labelText: '标签'),
                onChanged: (value) => label = value,
              ),
              ElevatedButton(
                child: Text('选择颜色'),
                onPressed: () async {
                  final Color? newColor = await showColorPicker(context, color);
                  if (newColor != null) {
                    color = newColor;
                  }
                },
              ),
            ],
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
                  'label': label,
                  'color': color,
                });
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        categories.add(result);
      });
      _saveCategories();
    }
  }

  void _saveCategories() {
    themeProvider.setCategories(categories);
  }

  Future<Color?> showColorPicker(BuildContext context, Color initialColor) {
    return showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        Color selectedColor = initialColor;
        return AlertDialog(
          title: Text('选择颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) => selectedColor = color,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('确定'),
              onPressed: () => Navigator.of(context).pop(selectedColor),
            ),
          ],
        );
      },
    );
  }
}
