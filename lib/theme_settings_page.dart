import 'package:flutter/material.dart'; // Material Design 组件库
import 'package:provider/provider.dart'; // 状态管理库
import '../providers/theme_provider.dart'; // 自定义主题状态管理
import 'package:image_picker/image_picker.dart'; // 图片选择器
import 'dart:io'; // 文件操作
import '../utils/color_picker_utils.dart'; // 颜色选择器工具类

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
        backgroundColor: primaryColor, // 使用主题色作为按钮背景色
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
                backgroundColor: (category['color'] as Color).withOpacity(0.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: _deleteModes[type]!
                        ? WarmColorScorer.getTotalScore(
                                    Theme.of(context).primaryColor) >
                                WarmColorScorer.getTotalScore(Theme.of(context)
                                    .textTheme
                                    .bodyMedium!
                                    .color!)
                            ? Theme.of(context).primaryColor
                            : Theme.of(context).textTheme.bodyMedium!.color!
                        : _editModes[type]!
                            ? WarmColorScorer.getTotalScore(
                                        Theme.of(context).primaryColor) >
                                    WarmColorScorer.getTotalScore(
                                        Theme.of(context)
                                            .textTheme
                                            .bodyMedium!
                                            .color!)
                                ? Theme.of(context).textTheme.bodyMedium!.color!
                                : Theme.of(context).primaryColor
                            : Theme.of(context).cardColor,
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
        return StatefulBuilder(
          builder: (context, setDialogState) {
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
                  SizedBox(height: 10),
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: GestureDetector(
                      onTap: () async {
                        final Color? newColor =
                            await ColorPickerUtils.showColorPicker(
                          context,
                          color,
                          onColorChanged: (Color newColor) {
                            setDialogState(() {
                              color = newColor;
                            });
                          },
                        );
                        if (newColor != null) {
                          setDialogState(() {
                            color = newColor;
                          });
                        }
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: color, // 现在应该可以看到颜色变化了
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: const Color.fromARGB(255, 214, 214, 214),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '选择颜色',
                          style: TextStyle(
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ),
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
                ? WarmColorScorer.getTotalScore(
                            Theme.of(context).primaryColor) >
                        WarmColorScorer.getTotalScore(
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
                ? WarmColorScorer.getTotalScore(
                            Theme.of(context).primaryColor) >
                        WarmColorScorer.getTotalScore(
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

  void _addCategory(bool isTodoCategory) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        String emoji = '📝';
        String label = '';
        Color colorrr = themeProvider.themeData.primaryColor;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isTodoCategory ? '添加待办分类' : '添加记账分类'),
              titlePadding: EdgeInsets.only(
                  left: 24, top: 24, right: 24, bottom: 0), // 调整标题padding
              contentPadding: EdgeInsets.only(
                  left: 24, top: 6, right: 24, bottom: 20), // 调整内容padding
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Emoji',
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
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                                  Colors.black,
                          width: 2.0,
                        ),
                      ),
                    ),
                    cursorColor: const Color.fromARGB(255, 214, 214, 214),
                    onChanged: (value) => emoji = value,
                  ),
                  SizedBox(height: 7),
                  TextField(
                    decoration: InputDecoration(
                      labelText: '标签',
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
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color ??
                                  Colors.black,
                          width: 2.0,
                        ),
                      ),
                    ),
                    cursorColor: const Color.fromARGB(255, 214, 214, 214),
                    onChanged: (value) => label = value,
                  ),
                  SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(
                        onTap: () async {
                          final Color? newColor =
                              await ColorPickerUtils.showColorPicker(
                            context,
                            colorrr,
                            onColorChanged: (Color color) {
                              setDialogState(() {
                                colorrr = color;
                              });
                            },
                          );
                          if (newColor != null) {
                            setDialogState(() {
                              colorrr = newColor;
                            });
                          }
                        },
                        child: Container(
                          width: 80,
                          height: 35,
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorrr,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Center(
                              child: Text(
                            '选择颜色',
                            style: TextStyle(color: Colors.black, fontSize: 15),
                          )),
                        ),
                      ),
                      SizedBox(width: 10),
                      TextButton(
                        child: Text(
                          '取消',
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      TextButton(
                        child: Text(
                          '添加',
                          style: TextStyle(color: Colors.black),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop({
                            'emoji': emoji,
                            'label': label,
                            'color': colorrr,
                            'id': DateTime.now().toString(),
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
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

  Widget _buildEmojiActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            Icons.edit,
            color: _editModes['diary']! ? Theme.of(context).primaryColor : null,
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
            color: _deleteModes['diary']! ? Colors.red : null,
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
      builder: (BuildContext context) {
        String emoji = '😊';
        return AlertDialog(
          title: Text('添加新表情'),
          titlePadding: EdgeInsets.only(
              left: 24, top: 24, right: 24, bottom: 0), // 调整标题padding
          contentPadding: EdgeInsets.only(
              left: 24, top: 6, right: 24, bottom: 14), // 调整内容padding
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Emoji',
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
                      color: Theme.of(context).textTheme.bodyMedium?.color ??
                          Colors.black,
                      width: 2.0,
                    ),
                  ),
                ),
                cursorColor: const Color.fromARGB(255, 214, 214, 214),
                onChanged: (value) => emoji = value,
              ),
              SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    child: Text(
                      '取消',
                      style: TextStyle(color: Colors.black,fontSize: 15),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  TextButton(
                    child: Text(
                      '添加',
                      style: TextStyle(color: Colors.black,fontSize: 15),
                    ),
                    onPressed: () {
                      Navigator.of(context).pop({
                        'emoji': emoji,
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (result != null) {
      final newEmojis = [...themeProvider.diaryEmojis, result];
      themeProvider.setDiaryEmojis(newEmojis);
    }
  }

  Widget _buildEmojiList(List<Map<String, dynamic>> emojis) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      child: Wrap(
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
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: _editModes['diary']!
                      ? Theme.of(context).primaryColor
                      : _deleteModes['diary']!
                          ? Colors.red
                          : Colors.transparent,
                  width: 1,
                ),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                emoji['emoji'],
                style: TextStyle(fontSize: 24),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _editEmoji(Map<String, dynamic> emoji) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        String newEmoji = emoji['emoji'];
        return AlertDialog(
          title: Text('编辑表情'),
          content: TextField(
            decoration: InputDecoration(labelText: 'Emoji'),
            controller: TextEditingController(text: newEmoji),
            onChanged: (value) => newEmoji = value,
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
                  'emoji': newEmoji,
                });
              },
            ),
          ],
        );
      },
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
