import 'package:flutter/material.dart'; // Material Design 组件库
import 'package:provider/provider.dart'; // 状态管理库
import '../providers/theme_provider.dart'; // 自定义主题状态管理
import 'package:image_picker/image_picker.dart'; // 图片选择器
import 'dart:io'; // 文件操作
import '../utils/color_picker_utils.dart'; // 颜色选择器工具类
import '../widgets/category_dialog.dart'; // 分类对话框组件
import '../widgets/emoji_dialog.dart';  // 导入EmojiDialog组件

// 主题设置页面的有状态Widget
class ThemeSettingsPage extends StatefulWidget {
  @override
  ThemeSettingsPageState createState() =>
      ThemeSettingsPageState(); // 创建对应的State类
}

// 主题设置页面的State类，包含页面的主要逻辑和状态
class ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late Color primaryColor; // 主题的主要颜色
  late Color scaffoldBackgroundColor; // 页面背景颜色
  late Color cardColor; // 卡片背景颜色
  late Color themeTextColor; // 文本颜色
  String? backgroundImage; // 背景图片路径
  late List<Map<String, dynamic>> categories; // 分类列表
  late ThemeProvider themeProvider; // 主题提供者实例

  // 编辑模式状态映射，控制不同类型的编辑状态
  Map<String, bool> _editModes = {
    'expense': false, // 支出分类编辑模式
    'todo': false, // 待办分类编辑模式
    'diary': false, // 日记表情编辑模式
  };

  // 删除模式状态映射，控制不同类型的删除状态
  Map<String, bool> _deleteModes = {
    'expense': false, // 支出分类删除模式
    'todo': false, // 待办分类删除模式
    'diary': false, // 日记表情删除模式
  };

  @override
  void initState() {
    super.initState();
    // 初始化主题提供者和加载当前主题设置
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    _loadCurrentTheme();
    _loadCategories();
  }

  // 加载当前主题颜色设置
  void _loadCurrentTheme() {
    final theme = themeProvider.themeData; // 获取当前主题数据
    setState(() {
      primaryColor = theme.primaryColor; // 设置主题色
      // 设置背景色，优先使用背景图片，否则使用颜色
      scaffoldBackgroundColor = backgroundImage != null
          ? theme.scaffoldBackgroundColor
          : (theme.scaffoldBackgroundColor == Colors.transparent
              ? themeProvider.lastBackgroundColor ??
                  Colors.white // 如果是透明色，使用上次保存的背景色
              : theme.scaffoldBackgroundColor);
      cardColor = theme.cardTheme.color ?? theme.cardColor; // 设置卡片颜色
      themeTextColor =
          theme.appBarTheme.foregroundColor ?? theme.primaryColor; // 设置文本颜色
      backgroundImage = themeProvider.backgroundImage; // 设置背景图片路径
    });
  }

  // 加载分类列表
  void _loadCategories() {
    setState(() {
      categories = themeProvider.categories; // 从provider中获取分类列表
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('设置'),
        backgroundColor: primaryColor, // 使用主题色作为导航栏背景色
        foregroundColor: themeTextColor, // 使用主题文本色作为导航栏文本色
      ),
      backgroundColor: scaffoldBackgroundColor, // 设置页面背景色
      body: Container(
        // 如果有背景图片，创建背景图片装饰
        decoration: backgroundImage != null
            ? BoxDecoration(
                image: DecorationImage(
                  image: FileImage(File(backgroundImage!)), // 从文件加载背景图片
                  fit: BoxFit.cover, // 图片填充方式
                ),
              )
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8), // 设置水平内边距
          child: ListView(
            children: [
              // 构建各种颜色选择器
              _buildColorPicker('主题色Ⅰ', primaryColor,
                  (color) => setState(() => primaryColor = color)),
              _buildColorPicker('主题色Ⅱ', themeTextColor,
                  (color) => setState(() => themeTextColor = color)),
              _buildColorPicker('卡片色', cardColor,
                  (color) => setState(() => cardColor = color)),
              _buildColorPicker('背景色', scaffoldBackgroundColor,
                  (color) => setState(() => scaffoldBackgroundColor = color)),

              Divider(color: primaryColor), // 分隔线
              // 记账标签设置区域
              ListTile(
                title: Text('记账标签'),
                trailing: _buildCategoryActions('expense'), // 构建记账标签的操作按钮
              ),
              _buildCategoryList(
                  themeProvider.categories, 'expense'), // 显示记账标签列表

              Divider(color: primaryColor), // 分隔线
              ListTile(
                title: Text('待办标签'),
                trailing: _buildCategoryActions('todo'), // 构建待办事项的操作按钮
              ),
              _buildCategoryList(
                  themeProvider.todoCategories, 'todo'), // 显示待办标签列表

              Divider(color: primaryColor), // 分隔线
              ListTile(
                title: Text('日记表情'),
                trailing: _buildEmojiActions(), // 构建日记表情的操作按钮
              ),
              _buildEmojiList(themeProvider.diaryEmojis), // 显示表情列表
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveTheme, // 点击时保存主题
        backgroundColor: primaryColor, // 使用主题色作为按钮背���色
        child: Icon(Icons.save, color: themeTextColor), // 保存图标，使用主题文本色
      ),
    );
  }

  // 构建颜色选择器组件
  Widget _buildColorPicker(
      String label, Color color, ValueChanged<Color> onColorChanged) {
    // 如果是背景色选择器，添加额外的图片选择按钮
    if (label == '背景色') {
      return ListTile(
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.image),
              onPressed: () async {
                await _pickBackgroundImage();
              },
            ),
            if (backgroundImage != null)
              IconButton(
                icon: Icon(Icons.delete),
                onPressed: () {
                  setState(() {
                    backgroundImage = null;
                    themeProvider.setBackgroundImage(null);
                  });
                },
              ),
            SizedBox(width: 7),
            GestureDetector(
              onTap: () async {
                final Color? newColor = await ColorPickerUtils.showColorPicker(
                  context,
                  color,
                  onColorChanged: (Color newColor) {
                    setState(() {
                      scaffoldBackgroundColor = newColor; // 直接更新背景色
                    });
                  },
                );
                if (newColor != null) {
                  onColorChanged(newColor);
                }
              },
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 0.5),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // 其他颜色选择器
    return ListTile(
      title: Text(label),
      trailing: GestureDetector(
        onTap: () async {
          final Color? newColor = await ColorPickerUtils.showColorPicker(
            context,
            color,
            onColorChanged: (Color newColor) {
              setState(() {
                onColorChanged(newColor); // 实时更新颜色
              });
            },
          );
          if (newColor != null) {
            onColorChanged(newColor);
          }
        },
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey, width: 0.5),
          ),
        ),
      ),
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
      scaffoldBackgroundColor: backgroundImage != null
          ? Colors.transparent
          : scaffoldBackgroundColor,
      cardTheme: CardTheme(
        color: cardColor.withOpacity(cardColor.opacity),
        //圆角
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: themeTextColor,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: primaryColor,
        selectedItemColor: themeTextColor,
        unselectedItemColor: themeTextColor.withOpacity(0.7),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: themeTextColor),
        bodyMedium: TextStyle(color: themeTextColor),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: primaryColor.withOpacity(0.8),
        elevation: 0,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: primaryColor.withOpacity(0.8),
        //圆角
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 0,
      ),
    );
    themeProvider.setTheme(newTheme);
    themeProvider.setBackgroundImage(backgroundImage);
    themeProvider.setCategories(categories);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('主题已保存(o^^o)~')));
  }

  Widget _buildCategoryList(
      List<Map<String, dynamic>> categories, String type) {
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
                if (_editModes[type]!) {
                  _editCategory(category);
                } else if (_deleteModes[type]!) {
                  _deleteCategory(category);
                }
              },
              child: Chip(
                avatar: Text(category['emoji']),
                label: Text(category['label']),
                backgroundColor: (category['color'] as Color).withOpacity(0.9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(7),
                  side: BorderSide(
                    color: _deleteModes[type]!
                        ? ColorScorer.getTotalScore(
                                    Theme.of(context).primaryColor) >
                                ColorScorer.getTotalScore(Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color!)
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).textTheme.bodyMedium!.color!
                        : _editModes[type]!
                            ? ColorScorer.getTotalScore(
                                        Theme.of(context).primaryColor) >
                                    ColorScorer.getTotalScore(
                                        Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .color!)
                                ? Theme.of(context).textTheme.bodyMedium!.color!
                                : Theme.of(context).primaryColor
                            : Theme.of(context).scaffoldBackgroundColor,
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

  // 添加分类
  void _addCategory(bool isTodoCategory) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => CategoryDialog(
        title: isTodoCategory ? '添加待办分类' : '添加记账分类',
      ),
    );

    if (result != null) {
      if (isTodoCategory) {
        final newCategories = [...themeProvider.todoCategories, result];
        themeProvider.setTodoCategories(newCategories);
      } else {
        final newCategories = [...themeProvider.categories, result];
        themeProvider.setCategories(newCategories);
      }
    }
  }

  // 编辑分类
  void _editCategory(Map<String, dynamic> category) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => CategoryDialog(
        title: '编辑类别',
        initialEmoji: category['emoji'],
        initialLabel: category['label'],
        initialColor: category['color'],
        isEditing: true,
      ),
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
      if (categories.contains(category)) {
        categories.remove(category);
        _saveCategories();
      } else if (themeProvider.todoCategories.contains(category)) {
        _deleteTodoCategory(category);
      }
    });
  }

  void _deleteTodoCategory(Map<String, dynamic> category) {
    if (category['id'] == 'none') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('分类不能删除')),
      );
      return;
    }

    final newCategories = themeProvider.todoCategories
        .where((c) => c['id'] != category['id'])
        .toList();
    themeProvider.setTodoCategories(newCategories);
  }

  void _saveCategories() {
    themeProvider.setCategories(categories);
  }

  Widget _buildCategoryActions(String type) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit,
            color: _editModes[type]!
                ? ColorScorer.getTotalScore(
                            Theme.of(context).primaryColor) >
                        ColorScorer.getTotalScore(
                            Theme.of(context).textTheme.bodyMedium!.color!)
                    ? Theme.of(context).textTheme.bodyMedium!.color!
                    : Theme.of(context).primaryColor
                : null,
          ),
          onPressed: () {
            setState(() {
              if (_editModes[type]!) {
                _editModes.forEach((key, value) => _editModes[key] = false);
                _deleteModes.forEach((key, value) => _deleteModes[key] = false);
              } else {
                _editModes.forEach((key, value) => _editModes[key] = false);
                _deleteModes.forEach((key, value) => _deleteModes[key] = false);
                _editModes[type] = true;
              }
            });
          },
        ),
        IconButton(
          icon: Icon(
            Icons.delete,
            color: _deleteModes[type]!
                ? ColorScorer.getTotalScore(
                            Theme.of(context).primaryColor) >
                        ColorScorer.getTotalScore(
                            Theme.of(context).textTheme.bodyMedium!.color!)
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyMedium!.color!
                : null,
          ),
          onPressed: () {
            setState(() {
              _editModes.forEach((key, value) => _editModes[key] = false);
              _deleteModes[type] = !_deleteModes[type]!;
              _deleteModes.forEach((key, value) {
                if (key != type) {
                  _deleteModes[key] = false;
                }
              });
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => _addCategory(type == 'todo'),
        ),
      ],
    );
  }

  Widget _buildEmojiActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit,
            color: _editModes['diary']!
                ? ColorScorer.getTotalScore(
                            Theme.of(context).primaryColor) >
                        ColorScorer.getTotalScore(
                            Theme.of(context).textTheme.bodyMedium!.color!)
                    ? Theme.of(context).textTheme.bodyMedium!.color!
                    : Theme.of(context).primaryColor
                : null,
          ),
          onPressed: () {
            setState(() {
              if (_editModes['diary']!) {
                _editModes.forEach((key, value) => _editModes[key] = false);
                _deleteModes.forEach((key, value) => _deleteModes[key] = false);
              } else {
                _editModes.forEach((key, value) => _editModes[key] = false);
                _deleteModes.forEach((key, value) => _deleteModes[key] = false);
                _editModes['diary'] = true;
              }
            });
          },
        ),
        IconButton(
          icon: Icon(
            Icons.delete,
            color: _deleteModes['diary']!
                ? ColorScorer.getTotalScore(
                            Theme.of(context).primaryColor) >
                        ColorScorer.getTotalScore(
                            Theme.of(context).textTheme.bodyMedium!.color!)
                    ? Theme.of(context).primaryColor
                    : Theme.of(context).textTheme.bodyMedium!.color!
                : null,
          ),
          onPressed: () {
            setState(() {
              _editModes.forEach((key, value) => _editModes[key] = false);
              _deleteModes['diary'] = !_deleteModes['diary']!;
              _deleteModes.forEach((key, value) {
                if (key != 'diary') {
                  _deleteModes[key] = false;
                }
              });
            });
          },
        ),
        IconButton(
          icon: Icon(Icons.add),
          onPressed: () => _addEmoji(),
        ),
      ],
    );
  }

  void _addEmoji() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => EmojiDialog(),
    );

    if (result != null) {
      final newEmojis = [...themeProvider.diaryEmojis, result];
      themeProvider.setDiaryEmojis(newEmojis);
    }
  }

  Widget _buildEmojiList(List<Map<String, dynamic>> emojis) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.center,
        child: Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 8,
        children: emojis.map((emoji) {
          return GestureDetector(
            onTap: () {
              if (_editModes['diary']!) {
                _editEmoji(emoji);
              } else if (_deleteModes['diary']!) {
                _deleteEmoji(emoji);
              }
            },
            child: Container(
              width: 45,
              height: 45,
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _deleteModes['diary']!
                        ? ColorScorer.getTotalScore(
                                    Theme.of(context).primaryColor) >
                                ColorScorer.getTotalScore(Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color!)
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).textTheme.bodyMedium!.color!
                        : _editModes['diary']!
                            ? ColorScorer.getTotalScore(
                                        Theme.of(context).primaryColor) >
                                    ColorScorer.getTotalScore(
                                        Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .color!)
                                ? Theme.of(context).textTheme.bodyMedium!.color!
                                : Theme.of(context).primaryColor
                            : Theme.of(context).scaffoldBackgroundColor,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(13),
              ),  
              child: Center(
                child: Text(
                  emoji['emoji'],
                  style: TextStyle(fontSize: 24),
              ),
            ),
            ),
          );
        }).toList(),
      ),
      ),
    );
  }

  void _editEmoji(Map<String, dynamic> emoji) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => EmojiDialog(
        initialEmoji: emoji['emoji'],
        title: '编辑表情',
      ),
    );

    if (result != null) {
      final index = themeProvider.diaryEmojis.indexOf(emoji);
      final newEmojis = [...themeProvider.diaryEmojis];
      newEmojis[index] = result;
      themeProvider.setDiaryEmojis(newEmojis);
    }
  }

  void _deleteEmoji(Map<String, dynamic> emoji) {
    final newEmojis = themeProvider.diaryEmojis
        .where((e) => e['emoji'] != emoji['emoji'])
        .toList();
    themeProvider.setDiaryEmojis(newEmojis);
  }
}
