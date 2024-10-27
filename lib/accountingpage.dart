import 'package:flutter/material.dart'; // 导入Flutter材料设计库
import 'dart:async'; // 导入异步编程支持
import 'package:shared_preferences/shared_preferences.dart'; // 导入本地存储库
import 'dart:convert'; // 导入JSON编解码支持
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // 导入颜色选择器库
import 'dart:math' as math;

// 记账页面
class AccountingPage extends StatefulWidget {
  @override
  AccountingPageState createState() =>
      AccountingPageState(); // 创建AccountingPageState实例
}

class AccountingPageState extends State<AccountingPage> {
  late ThemeProvider themeProvider;
  // 表单的全局键，用于验证表单
  final _formKey = GlobalKey<FormState>(); // 表单的全局键，用于验证表单
  // 控制器，用于获取用户输入的金额、类别和备注
  final _amountController = TextEditingController(); // 控制器，用于获取用户输入的金额
  final categoryController = TextEditingController(); // 控制器，用于获取用户输入的类别
  final _noteController = TextEditingController(); // 控制器，用于获取用输入的备注
  // 存储记账记录的列表
  List<Map<String, String>> records = []; // 存储记账记录的列表
  // 标记是否正在加载数据
  bool _isLoading = true; // 标记是否正在加载数据
  // 交易类型，默认为支出
  String _transactionType = '支出'; // 交易类型，默认为支出
  List<String> selectedCategories = []; // 新增：用于存储多个选中的类别
  List<Map<String, dynamic>> categories = [
    {'emoji': '🥗', 'label': '吃饭', 'color': Colors.green},
    {'emoji': '🏠', 'label': '住宿', 'color': Colors.blue},
    {'emoji': '🚗', 'label': '交通', 'color': Colors.red},
    {'emoji': '🛒', 'label': '购物', 'color': Colors.orange},
    {'emoji': '🎉', 'label': '娱乐', 'color': Colors.purple},
  ];
  bool _isGridView = true; // 新增：用于跟踪当前是否为网格视图
  // 在 AccountingPageState 类中添加一个新的状态变量
  bool _isDeleteMode = false;
  // 在 AccountingPageState 类中添加新的状态变量
  bool _isAscending = true; // true 表示正序（旧到新），false 表示倒序（新到旧）

  @override
  void initState() {
    super.initState();
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.addListener(_onCategoriesChanged);
    _loadRecords();
    _loadCategories();
  }

  @override
  void dispose() {
    // 移除监听器
    themeProvider.removeListener(_onCategoriesChanged);
    super.dispose();
  }

  void _onCategoriesChanged() {
    _loadCategories();
  }

  // 从本地存储加载记账记录
  Future<void> _loadRecords() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? recordsString = prefs.getString('accountingRecords');
      if (!mounted) return;
      setState(() {
        records = recordsString != null
            ? (jsonDecode(recordsString) as List<dynamic>)
                .map((item) => Map<String, String>.from(item))
                .toList()
            : [];
        _isLoading = false;
      });
    } catch (e) {
      print('加载记录时出错: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // 保存记账记录到本地存储
  Future<void> _saveRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance(); // 获取本地存储实例
    await prefs.setString(
        'accountingRecords', jsonEncode(records)); // 保存记账记录到本地存储
  }

  // 添加新记账记录
  void _addRecord() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        records.add({
          'amount': _amountController.text,
          'categories': jsonEncode(selectedCategories),
          'note': _noteController.text,
          'type': _transactionType,
        });
        _amountController.clear();
        _noteController.clear();

        // 移除临时类别
        categories.removeWhere((category) => category['isTemporary'] == true);

        // 从 selectedCategories 中移除不再存在于 categories 中的类别
        selectedCategories.removeWhere((categoryString) {
          return !categories.any((category) =>
              '${category['emoji']}${category['label']}' == categoryString);
        });
      });
      _saveRecords();
      // 更新 ThemeProvider 中的类别列表
      themeProvider.setCategories(categories);
    }
  }

  void _loadCategories() {
    if (!mounted) return;
    setState(() {
      // 只加非临时类别
      categories = themeProvider.categories
          .where((category) => category['isTemporary'] != true)
          .toList();
    });
  }

  void _addCustomCategory() async {
    if (!mounted) return;
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        String emoji = '😀';
        String label = '';
        Color color = Colors.blue;
        return AlertDialog(
          title: Text('添加自定义类别'),
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
      result['isTemporary'] = true; // 标记为临时类别
      setState(() {
        categories.add(result); // 添加到类别列表
        selectedCategories
            .add('${result['emoji']}${result['label']}'); // 添加到选中的类别
      });
      // 不需要同步到 ThemeProvider，因为这是临时类别
    }
  }

  // 新增：切换视图模式的方法
  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  // 添加排序方法
  void _toggleSortOrder() {
    setState(() {
      _isAscending = !_isAscending;
      records = records.reversed.toList();
    });
    _saveRecords();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final warmColor = _getWarmColor(themeColor, textColor);
    final coldColor = _getColdColor(themeColor, textColor);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? Center(child: CircularProgressIndicator()) // 显示加载中的进度条
          : Column(
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey, // 表单的全局键，用于验证表单
                      child: Column(
                        children: [
                          // 金额输入框
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _amountController,
                                  decoration: InputDecoration(
                                    labelText: '金额',
                                    labelStyle: TextStyle(
                                      color: const Color.fromARGB(
                                          255, 100, 100, 100),
                                    ),
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: const Color.fromARGB(
                                            255, 214, 214, 214),
                                        width: 1.5,
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: themeColor,
                                        width: 2.0,
                                      ),
                                    ),
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return '请输入金额';
                                    }
                                    return null;
                                  },
                                  cursorColor:
                                      const Color.fromARGB(255, 214, 214, 214),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _buildTransactionTypeCheckbox(
                                        '收入', warmColor),
                                    _buildTransactionTypeCheckbox(
                                        '支出', coldColor),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16),
                          // 类别选择
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                ...categories.map((category) {
                                  String categoryString =
                                      '${category['emoji']}${category['label']}';
                                  bool isSelected = selectedCategories
                                      .contains(categoryString);
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 6.0),
                                    child: FilterChip(
                                      label: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            categoryString,
                                            style: TextStyle(fontSize: 12),
                                          ),
                                          if (isSelected) SizedBox(width: 3),
                                          if (isSelected)
                                            Icon(Icons.check, size: 12),
                                        ],
                                      ),
                                      materialTapTargetSize:
                                          MaterialTapTargetSize
                                              .shrinkWrap, // 减小点击区域
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4), // 减小内边距
                                      selected: isSelected,
                                      onSelected: (bool selected) {
                                        setState(() {
                                          if (selected) {
                                            selectedCategories
                                                .add(categoryString);
                                          } else {
                                            selectedCategories
                                                .remove(categoryString);
                                          }
                                        });
                                      },
                                      backgroundColor: category['color']
                                          .withOpacity(0.1), // 减小不选中时的透明度
                                      selectedColor: category['color']
                                          .withOpacity(0.3), // 减小选中时的透明度
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8), // 减小圆角
                                        side: BorderSide(
                                          color: Theme.of(context)
                                              .cardColor, // 设置边框颜色与卡片颜色相同
                                          width: 0, // 设置边框宽度
                                        ),
                                      ),
                                      showCheckmark: false,
                                    ),
                                  );
                                }),
                                IconButton(
                                  icon: Icon(Icons.add),
                                  onPressed: _addCustomCategory,
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          Row(
                            children: [
                              // 备注输入框
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _noteController, // 控制器用于获取用户输入的备注
                                  decoration: InputDecoration(
                                    labelText: '备注', // 设置labelText
                                    labelStyle: TextStyle(
                                      color: const Color.fromARGB(
                                          255, 100, 100, 100),
                                    ), // 设置labelText的颜色
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: const Color.fromARGB(
                                            255, 214, 214, 214), // 设置横线颜色
                                        width: 1.5, // 设置横线粗细
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: themeColor, // 设置获取焦点时的横线颜色
                                        width: 2.0, // 设置获取焦点时的横线粗细
                                      ),
                                    ),
                                  ),
                                  cursorColor: const Color.fromARGB(
                                      255, 214, 214, 214), // 设置获取点时的横线颜色
                                ),
                              ),
                              SizedBox(width: 25),
                              Expanded(
                                flex: 0,
                                child:
                                    // 添加记按钮
                                    ElevatedButton(
                                  onPressed: _addRecord, // 添加记
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: themeColor, // 设置按钮背景颜色
                                    foregroundColor: textColor,
                                  ),
                                  child: Text('📝'),
                                ),
                              ),
                              SizedBox(width: 5),
                            ],
                          ),
                          SizedBox(height: 8), // 与下一个输入框的间隔
                        ],
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                // 新增：视切换图标
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: Icon(_isAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                      onPressed: _toggleSortOrder,
                      tooltip: _isAscending ? '切换为倒序' : '切换为正序',
                    ),
                    IconButton(
                      icon:
                          Icon(_isGridView ? Icons.view_list : Icons.grid_view),
                      onPressed: _toggleViewMode,
                      tooltip: _isGridView ? '切换到列表视图' : '切换到网格视图',
                    ),
                    IconButton(
                      icon: Icon(_isDeleteMode
                          ? Icons.delete_forever
                          : Icons.delete_outline),
                      onPressed: () {
                        setState(() {
                          _isDeleteMode = !_isDeleteMode;
                        });
                      },
                      tooltip: _isDeleteMode ? '退出删除模式' : '进入删除模式',
                    ),
                  ],
                ),
                SizedBox(height: 8),
                // 账单列表
                Expanded(
                  child: _isGridView
                      ? LayoutBuilder(
                          builder: (context, constraints) {
                            return GridView.extent(
                              maxCrossAxisExtent: constraints.maxWidth / 2,
                              childAspectRatio: 1.5,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                              padding: EdgeInsets.all(16),
                              children: List.generate(records.length, (index) {
                                return LayoutBuilder(
                                  builder: (context, constraints) {
                                    return _buildRecordItem(
                                        context, index, constraints);
                                  },
                                );
                              }),
                            );
                          },
                        )
                      : ListView.builder(
                          itemCount: records.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) =>
                                  _buildRecordItem(context, index, constraints),
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  // 新增：构建记录项的方法，用于网格和列表视图
  Widget _buildRecordItem(
      BuildContext context, int index, BoxConstraints constraints) {
    final themeColor = Theme.of(context).primaryColor;
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final warmColor = _getWarmColor(themeColor, textColor);
    final coldColor = _getColdColor(themeColor, textColor);

    List<String> recordCategories = [];
    try {
      recordCategories =
          (jsonDecode(records[index]['categories'] ?? '[]') as List)
              .cast<String>();
    } catch (e) {
      print('Error decoding categories: $e');
    }

    if (_isGridView) {
      return Stack(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        records[index]['type'] == '收入'
                            ? Icons.north_east
                            : Icons.south_west,
                        color: records[index]['type'] == '收入'
                            ? warmColor
                            : coldColor,
                        size: 20,
                      ),
                      Text(
                        '${records[index]['amount']}',
                        style: TextStyle(
                          color: records[index]['type'] == '收入'
                              ? warmColor
                              : coldColor,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: recordCategories.map((categoryString) {
                              var category = categories.firstWhere(
                                (c) =>
                                    '${c['emoji']}${c['label']}' ==
                                    categoryString,
                                orElse: () => {
                                  'emoji': '🏷️',
                                  'label': categoryString,
                                  'color': Colors.grey
                                },
                              );
                              return Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (category['color'] as Color)
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                    '${category['emoji']} ${category['label']}',
                                    style: TextStyle(fontSize: 10)),
                              );
                            }).toList(),
                          ),
                          if (records[index]['note']?.isNotEmpty ?? false) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.note, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${records[index]['note']}',
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 2,
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey[600]),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isDeleteMode)
            Positioned(
              right: 4,
              bottom: 4,
              child: IconButton(
                icon: Icon(Icons.remove_circle, color: Colors.red),
                onPressed: () => _deleteRecord(index),
                iconSize: 20,
              ),
            ),
        ],
      );
    } else {
      // 列表视的布局（保持原来的样式）
      return Card(
        child: Stack(
          children: [
            ListTile(
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    records[index]['type'] == '收入'
                        ? Icons.north_east
                        : Icons.south_west,
                    color:
                        records[index]['type'] == '收入' ? warmColor : coldColor,
                  ),
                ],
              ),
              title: Row(
                children: [
                  Text(
                    '${records[index]['amount']}',
                    style: TextStyle(
                      color: records[index]['type'] == '收入'
                          ? warmColor
                          : coldColor,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.category,
                        size: 16,
                        color: const Color.fromARGB(255, 214, 214, 214),
                      ),
                      SizedBox(width: 4),
                      Expanded(
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: recordCategories.map((categoryString) {
                            var category = categories.firstWhere(
                              (c) =>
                                  '${c['emoji']}${c['label']}' ==
                                  categoryString,
                              orElse: () => {
                                'emoji': '🏷️',
                                'label': categoryString,
                                'color': Colors.grey
                              },
                            );
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: (category['color'] as Color)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                  '${category['emoji']} ${category['label']}',
                                  style: TextStyle(fontSize: 10)),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  if (records[index]['note']?.isNotEmpty ?? false) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${records[index]['note']}',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_isDeleteMode)
              Positioned(
                right: 4,
                bottom: 4,
                child: IconButton(
                  icon: Icon(Icons.remove_circle, color: Colors.red),
                  onPressed: () => _deleteRecord(index),
                  iconSize: 20,
                ),
              ),
          ],
        ),
      );
    }
  }

  // 在类的其他地方添加这些辅助方法
  Color _getWarmColor(Color color1, Color color2) {
    return _isWarmer(color1, color2) ? color1 : color2;
  }

  Color _getColdColor(Color color1, Color color2) {
    return _isWarmer(color1, color2) ? color2 : color1;
  }

  bool _isWarmer(Color color1, Color color2) {
    // 简单地比较红色和蓝色分
    return (color1.red - color1.blue) > (color2.red - color2.blue);
  }

  // 添加颜色选择器方法
  Future<Color?> showColorPicker(
      BuildContext context, Color initialColor) async {
    if (!mounted) return null;
    return showDialog<Color>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('选择颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: (Color color) {
                initialColor = color;
              },
            ),
          ),
          actions: <Widget>[
            ElevatedButton(
              child: const Text('确定'),
              onPressed: () {
                Navigator.of(context).pop(initialColor);
              },
            ),
          ],
        );
      },
    );
  }

  // 关于交易类型的复选框
  Widget _buildTransactionTypeCheckbox(String type, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Checkbox(
          value: _transactionType == type,
          onChanged: (bool? value) {
            setState(() {
              if (value == true) {
                _transactionType = type;
              } else {
                _transactionType = '';
              }
            });
          },
          activeColor: color,
        ),
        Text(type,
            style: TextStyle(
                color: _transactionType == type ? color : Colors.grey)),
      ],
    );
  }

  // 添加这个辅助方法来生成随机颜色
  Color _getRandomColor() {
    return Color((math.Random().nextDouble() * 0xFFFFFF).toInt())
        .withOpacity(1.0);
  }

  // 添加删除记录的方法
  void _deleteRecord(int index) {
    setState(() {
      records.removeAt(index);
    });
    _saveRecords(); // 保存更改到本地存储
  }
}
