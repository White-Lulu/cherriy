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
  // 修改状态变量，将 bool 改为 int
  // bool _isGridView = true; // 删除这行
  int _viewMode = 0; // 0: 列表视图, 1: 2列网格, 2: 3列网格
  // 在 AccountingPageState 类中添加一个新的状态变量
  bool _isDeleteMode = false;
  // 在 AccountingPageState 类中添加新的状态变量
  bool _isAmountAscending = true;
  bool _isTimeAscending = true;
  // 在 AccountingPageState 类中添加新的状态变量
  List<String> selectedFilterCategories = []; // 用于存储筛选选中的类别
  // 在 AccountingPageState 类中添加的状态变量
  String _sortType = 'time'; // 'time', 'amount'
  // 在 AccountingPageState 类中添加新的状态变量
  String? selectedTransactionType;

  // 添加 FocusNode
  final FocusNode _amountFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();

  // 添加一个新的状态变量用于存储筛选后的记录
  List<Map<String, String>> filteredRecords = [];
  bool isFiltered = false;

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
    // 在 dispose 中释放 FocusNode
    _amountFocusNode.dispose();
    _noteFocusNode.dispose();
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
          'timestamp': DateTime.now().toIso8601String(),
        });
        
        // 清除输入
        _amountController.clear();
        _noteController.clear();
        
        // 清除选中的类别
        selectedCategories.clear();  // 添加这行，清除已选中的类别
        
        // 移除临时类别
        categories.removeWhere((category) => category['isTemporary'] == true);
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
        String emoji = '';  // 初始化为空字符串
        String label = '';
        Color color = Theme.of(context).primaryColor;  // 使用主题色作为默认颜色
        
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
                decoration: InputDecoration(labelText: '类别名称'),
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
              child: Text('确定'),
              onPressed: () {
                if (label.isNotEmpty) {
                  Navigator.of(context).pop({
                    'emoji': emoji,
                    'label': label,
                    'color': color,
                    'isTemporary': true,
                  });
                }
              },
            ),
          ],
        );
      },
    );

    if (result != null) {
      setState(() {
        categories.add(result);
        // 添加到选中的类别时，只使用emoji和label的组合
        selectedCategories.add('${result['emoji']}${result['label']}');
      });
    }
  }

  // 新增：切换视图模式的方法
  void _toggleViewMode() {
    setState(() {
      _viewMode = (_viewMode + 1) % 3; // 在0、1、2之间循环
    });
  }

  // 添加排序方法
  void toggleSortOrder() {
    setState(() {
      _isAmountAscending = !_isAmountAscending;
      _isTimeAscending = !_isTimeAscending;
      records = records.reversed.toList();
    });
    _saveRecords();
  }

  // 添加筛选方法
  void _showFilterBottomSheet() {  
    final themeColor = Theme.of(context).primaryColor;
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final warmColor = _getWarmColor(themeColor, textColor);
    final coldColor = _getColdColor(themeColor, textColor);
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Container(
              padding: EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('筛选',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedFilterCategories.clear();
                            selectedTransactionType = null;
                          });
                          Navigator.pop(context);
                          _applyFilter();
                        },
                        child: Text('清除筛选'),
                      ),
                    ],
                  ),
                  Divider(),
                  Text('收支类型',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      FilterChip(
                        label: Text('收入'),
                        selected: selectedTransactionType == '收入',
                        onSelected: (bool selected) {
                          setState(() {
                            // 如果已经选中了"收入"，再次点击就取消选择
                            if (selectedTransactionType == '收入') {
                              selectedTransactionType = null;
                            } else {
                              // 否则选择"收入"
                              selectedTransactionType = '收入';
                            }
                          });
                        },
                        backgroundColor: warmColor.withOpacity(0.1),
                        selectedColor: warmColor.withOpacity(0.3),
                      ),
                      SizedBox(width: 8),
                      FilterChip(
                        label: Text('支出'),
                        selected: selectedTransactionType == '支出',
                        onSelected: (bool selected) {
                          setState(() {
                            // 如果已经选中了"支出"，再次点击就取消选择
                            if (selectedTransactionType == '支出') {
                              selectedTransactionType = null;
                            } else {
                              // 否则选择"支出"
                              selectedTransactionType = '支出';
                            }
                          });
                        },
                        backgroundColor: coldColor.withOpacity(0.1),
                        selectedColor: coldColor.withOpacity(0.3),
                      ),
                    ],
                  ),
                  Divider(),
                  Text('类别',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      String categoryString =
                          '${category['emoji']}${category['label']}';
                      bool isSelected =
                          selectedFilterCategories.contains(categoryString);
                      return FilterChip(
                        label: Text(categoryString),
                        selected: isSelected,
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              selectedFilterCategories.add(categoryString);
                            } else {
                              selectedFilterCategories.remove(categoryString);
                            }
                          });
                        },
                        backgroundColor: category['color'].withOpacity(0.1),
                        selectedColor: category['color'].withOpacity(0.3),
                        checkmarkColor: category['color'],
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // 确保在关时不会触发键盘
                        FocusScope.of(context).unfocus();
                        Navigator.pop(context);
                        _applyFilter();
                      },
                      child: Text('应用筛选'),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 添加筛选应用方法
  void _applyFilter() {
    setState(() {
      if (selectedFilterCategories.isEmpty && selectedTransactionType == null) {
        isFiltered = false;
        filteredRecords.clear();
        _loadRecords();
      } else {
        isFiltered = true;
        filteredRecords = records.where((record) {
          bool matchesType = selectedTransactionType == null ||
              record['type'] == selectedTransactionType;

          List<String> recordCategories = [];
          try {
            recordCategories =
                (jsonDecode(record['categories'] ?? '[]') as List).cast<String>();
          } catch (e) {
            print('Error decoding categories: $e');
          }

          bool matchesCategories = selectedFilterCategories.isEmpty ||
              selectedFilterCategories
                  .any((filterCategory) => recordCategories.contains(filterCategory));

          return matchesType && matchesCategories;
        }).toList();
      }
    });
  }

  // 添加按金额排序的方法
  void _toggleSortByAmount() {
    setState(() {
      if (_sortType != 'amount') {
        _sortType = 'amount';
        _isAmountAscending = true;
      } else {
        _isAmountAscending = !_isAmountAscending;
      }
      _sortRecords();
    });
  }

  // 修改原有的时间排序方法
  void _toggleSortByTime() {
    setState(() {
      if (_sortType != 'time') {
        _sortType = 'time';
        _isTimeAscending = true;
      } else {
        _isTimeAscending = !_isTimeAscending;
      }
      _sortRecords();
    });
  }

  // 添加排序记录的方法
  void _sortRecords() {
    records.sort((a, b) {
      if (_sortType == 'amount') {
        double amountA = double.parse(a['amount'] ?? '0');
        double amountB = double.parse(b['amount'] ?? '0');
        return _isAmountAscending
            ? amountA.compareTo(amountB)
            : amountB.compareTo(amountA);
      } else {
        DateTime timeA =
            DateTime.parse(a['timestamp'] ?? DateTime.now().toIso8601String());
        DateTime timeB =
            DateTime.parse(b['timestamp'] ?? DateTime.now().toIso8601String());
        return _isTimeAscending
            ? timeA.compareTo(timeB)
            : timeB.compareTo(timeA);
      }
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
                                child: GestureDetector(
                                  onTap: () {
                                    if (_amountFocusNode.hasFocus) {
                                      _amountFocusNode.unfocus();
                                    } else {
                                      FocusScope.of(context)
                                          .requestFocus(_amountFocusNode);
                                    }
                                  },
                                  child: TextFormField(
                                    controller: _amountController,
                                    focusNode: _amountFocusNode,
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
                                    cursorColor: const Color.fromARGB(
                                        255, 214, 214, 214),
                                  ),
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
                                child: GestureDetector(
                                  onTap: () {
                                    if (_noteFocusNode.hasFocus) {
                                      _noteFocusNode.unfocus();
                                    } else {
                                      FocusScope.of(context)
                                          .requestFocus(_noteFocusNode);
                                    }
                                  },
                                  child: TextFormField(
                                    controller: _noteController,
                                    focusNode: _noteFocusNode,
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
                      icon: Icon(Icons.filter_list),
                      onPressed: _showFilterBottomSheet,
                      tooltip: '筛选账单',
                      color: selectedFilterCategories.isNotEmpty
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    IconButton(
                      icon: Icon(Icons.attach_money),
                      onPressed: _toggleSortByAmount,
                      tooltip: _sortType == 'amount'
                          ? (_isAmountAscending ? '金额从低到高' : '金额从高到低')
                          : '按金额排序',
                      color: _sortType == 'amount'
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    IconButton(
                      icon: Icon(_isTimeAscending
                          ? Icons.arrow_upward
                          : Icons.arrow_downward),
                      onPressed: _toggleSortByTime,
                      tooltip: _sortType == 'time'
                          ? (_isTimeAscending ? '从旧到新' : '从新到旧')
                          : '按时间排序',
                      color: _sortType == 'time'
                          ? Theme.of(context).primaryColor
                          : null,
                    ),
                    IconButton(
                      icon: Icon(_viewMode == 0 
                          ? Icons.grid_view_sharp  // 列表视图时显示2列网格图标
                          : _viewMode == 1 
                              ? Icons.grid_3x3     // 2列网格时显示3列网格图标
                              : Icons.view_list),  // 3列网格时显示列表图标
                      onPressed: _toggleViewMode,
                      tooltip: _viewMode == 0 
                          ? '切换到2列网格' 
                          : _viewMode == 1 
                              ? '切换到3列网格' 
                              : '切换到列表视图',
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
                  child: _viewMode == 0
                      ? ListView.builder(
                          // 列表视图的现有代码保持不变
                          itemCount: isFiltered ? filteredRecords.length : records.length,
                          itemBuilder: (context, index) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: LayoutBuilder(
                              builder: (context, constraints) => _buildRecordItem(
                                  context, 
                                  index, 
                                  constraints, 
                                  isFiltered ? filteredRecords : records),
                            ),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            return GridView.extent(
                              maxCrossAxisExtent: _viewMode == 1 
                                  ? constraints.maxWidth / 2  // 2列网格
                                  : constraints.maxWidth / 3, // 3列网格
                              childAspectRatio: _viewMode == 1 ? 2 : 1.2, // 根据模式设置比例
                              crossAxisSpacing: 6,
                              mainAxisSpacing: 10,
                              padding: EdgeInsets.all(0),
                              children: List.generate(
                                isFiltered ? filteredRecords.length : records.length,
                                (index) {
                                  return LayoutBuilder(
                                    builder: (context, constraints) {
                                      return _buildRecordItem(
                                          context, 
                                          index, 
                                          constraints, 
                                          isFiltered ? filteredRecords : records);
                                    },
                                  );
                                },
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  // 新增：构建记录项的方法，用于网格和列表视图
  Widget _buildRecordItem(
      BuildContext context, int index, BoxConstraints constraints, List<Map<String, String>> displayRecords) {
    final themeColor = Theme.of(context).primaryColor;
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final warmColor = _getWarmColor(themeColor, textColor);
    final coldColor = _getColdColor(themeColor, textColor);

    List<String> recordCategories = [];
    try {
      recordCategories = (jsonDecode(displayRecords[index]['categories'] ?? '[]') as List).cast<String>();
    } catch (e) {
      print('Error decoding categories: $e');
    }

    // 修改类别显示的处理逻辑
    Widget buildCategoryItem(String categoryString) {
      var category = categories.firstWhere(
        (c) => '${c['emoji']}${c['label']}' == categoryString,
        orElse: () {
          // 如果是临时类别，直接使用categoryString作为显示文本
          return {
            'emoji': '',  // 移除🏷
            'label': categoryString,
            'color': themeColor,  // 使用主题色作为默认颜色
            'isTemporary': true
          };
        },
      );

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: (category['color'] as Color).withOpacity(0.2),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          category['isTemporary'] == true 
              ? categoryString  // 临时类别直接显示完整文本
              : '${category['emoji']} ${category['label']}',  // 永久类别显示emoji和标签
          style: TextStyle(fontSize: 10),
        ),
      );
    }

    if (_viewMode == 0) {
      // 列表视的布局（保持原来的样式）
      return Card(
        child: Stack(
          children: [
            ListTile(
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    displayRecords[index]['type'] == '收入'
                        ? Icons.north_east
                        : Icons.south_west,
                    color:
                        displayRecords[index]['type'] == '收入' ? warmColor : coldColor,
                  ),
                ],
              ),
              title: Row(
                children: [
                  Text(
                    '${displayRecords[index]['amount']}',
                    style: TextStyle(
                      color: displayRecords[index]['type'] == '收入'
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
                            return buildCategoryItem(categoryString);
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                  if (displayRecords[index]['note']?.isNotEmpty ?? false) ...[
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${displayRecords[index]['note']}',
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
    } else {
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
                        displayRecords[index]['type'] == '收入'
                            ? Icons.north_east
                            : Icons.south_west,
                        color: displayRecords[index]['type'] == '收入'
                            ? warmColor
                            : coldColor,
                        size: 20,
                      ),
                      Text(
                        '${displayRecords[index]['amount']}',
                        style: TextStyle(
                          color: displayRecords[index]['type'] == '收入'
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
                              return buildCategoryItem(categoryString);
                            }).toList(),
                          ),
                          if (displayRecords[index]['note']?.isNotEmpty ?? false) ...[
                            SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.note, size: 16, color: Colors.grey),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    '${displayRecords[index]['note']}',
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
  Color getRandomColor() {
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
