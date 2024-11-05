import 'package:flutter/material.dart'; // 导入Flutter材料设计库
import 'dart:async'; // 导入异步编程支持
import 'package:shared_preferences/shared_preferences.dart'; // 导入本地存储库
import 'dart:convert'; // 导入JSON编解码支持
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart'; // 导入颜色选择器库
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import '../widgets/category_dialog.dart';

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
  //bool _isLoading = true; // 标记是否正在加载数据
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
  // 在 AccountingPageState 类中添加的状态变量
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

  // 添加处理图表数据的变量
  List<FlSpot> _expenseSpots = [];
  List<FlSpot> _incomeSpots = [];
  List<FlSpot> _netIncomeSpots = [];
  double _maxY = 0;
  double _minY = 0;

  // 添加新的状态变量
  bool _isChartExpanded = true;

  // 添加保存视图模式的方法
  Future<void> _saveViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('accountingViewMode', _viewMode);
  }

  // 添加加载视图模式的方法
  Future<void> _loadViewMode() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _viewMode = prefs.getInt('accountingViewMode') ?? 0; // 默认列表视图
    });
  }

  // 添加保存图表折叠状态的方法
  Future<void> _saveChartExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('accountingChartExpanded', _isChartExpanded);
  }

  // 添加加载图表折叠状态的方法
  Future<void> _loadChartExpandedState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isChartExpanded = prefs.getBool('accountingChartExpanded') ?? true;
    });
  }

  // 在 AccountingPageState 类中添加新的变量
  List<FlSpot> _expenseSpotsReal = [];
  List<FlSpot> _expenseSpotsFuture = [];
  List<FlSpot> _incomeSpotsReal = [];
  List<FlSpot> _incomeSpotsFuture = [];
  List<FlSpot> _netIncomeSpotsReal = [];
  List<FlSpot> _netIncomeSpotsFuture = [];

  @override
  void initState() {
    super.initState();
    themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.addListener(_onCategoriesChanged);
    _loadViewMode(); // 加载保存的视图模式
    _loadChartExpandedState(); // 加载图表折叠状态
    _loadRecords().then((_) {
      if (mounted) {
        _updateChartData();
      }
    });
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
    try {
      final prefs = await SharedPreferences.getInstance();

      // 添加测试数据（如果记录为空的话）
      if (prefs.getString('accountingRecords') == null) {
        final now = DateTime.now();
        final testRecords = [
          {
            'amount': '100',
            'categories': '["🥗吃饭"]',
            'note': '午餐',
            'type': '支出',
            'timestamp': now.subtract(Duration(days: 3)).toIso8601String(),
          },
          {
            'amount': '200',
            'categories': '["🏠住宿"]',
            'note': '房租',
            'type': '支出',
            'timestamp': now.subtract(Duration(days: 2)).toIso8601String(),
          },
          {
            'amount': '1000',
            'categories': '["💰工资"]',
            'note': '工资',
            'type': '收入',
            'timestamp': now.subtract(Duration(days: 1)).toIso8601String(),
          },
          {
            'amount': '50',
            'categories': '["🥗吃饭"]',
            'note': '今日晚餐',
            'type': '支出',
            'timestamp': now.toIso8601String(),
          },
        ];

        await prefs.setString('accountingRecords', jsonEncode(testRecords));
      }

      final String? recordsString = prefs.getString('accountingRecords');
      if (!mounted) return;

      setState(() {
        records = recordsString != null
            ? (jsonDecode(recordsString) as List<dynamic>)
                .map((item) => Map<String, String>.from(item))
                .toList()
            : [];
        _updateChartData();
      });
    } catch (e) {
      print('加载记录时出错: $e');
    }
  }

  // 保存记账记录到本地存储
  Future<void> _saveRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance(); // 获取本地存储实例
    await prefs.setString(
        'accountingRecords', jsonEncode(records)); // 保存记账记录到本地存储
  }

  // 添加新记记录
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
        selectedCategories.clear(); // 添加这行，清除已选中的类别

        // 移除临时类别
        categories.removeWhere((category) => category['isTemporary'] == true);
      });

      _saveRecords();
      // 更新 ThemeProvider 中的类别列表
      themeProvider.setCategories(categories);
      _updateChartData();
    }
  }

  void _loadCategories() {
    if (!mounted) return;
    setState(() {
      // 只加非临时类
      categories = themeProvider.categories
          .where((category) => category['isTemporary'] != true)
          .toList();
    });
  }

  void _addCustomCategory() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) => CategoryDialog(
        title: '添加临时标签',
        initialEmoji: '',
        initialLabel: '',
        initialColor: Theme.of(context).primaryColor,
        isEditing: false,
      ),
    );

    if (result != null) {
      setState(() {
        categories.add({
          ...result,
          'isTemporary': true,
        });
        selectedCategories.add('${result['emoji']}${result['label']}');
      });
    }
  }

  // 新增：切换视图模式的方法
  void _toggleViewMode() {
    setState(() {
      _viewMode = (_viewMode + 1) % 3;
      _saveViewMode(); // 保存新的视图模式
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
    final warmColor = ColorScorer.getWarmColor(themeColor, textColor);
    final coldColor = ColorScorer.getColdColor(themeColor, textColor);
    FocusScope.of(context).unfocus();

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      backgroundColor: themeColor.withOpacity(0.8),
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
                      Text('筛选', style: TextStyle(color: textColor,fontSize: 20)),
                      Spacer(),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            selectedFilterCategories.clear();
                            selectedTransactionType = null;
                          });
                          Navigator.pop(context);
                          _applyFilter();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: themeColor,
                        ),
                        child: Text('清除',
                            style: TextStyle(color: textColor, fontSize: 14)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _applyFilter();
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: textColor,
                        ),
                        child: Text('应用',
                            style: TextStyle(color: textColor,fontSize: 14),
                      ),
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.withOpacity(0.8), thickness: 1),
                  Text('收支', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8),
                  Row(
                    children: [
                      FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('收入', style: TextStyle(fontSize: 12)),
                            if (selectedTransactionType == '收入') ...[
                              SizedBox(width: 4),
                              Icon(Icons.check, size: 12),
                            ],
                          ],
                        ),
                        selected: selectedTransactionType == '收入',
                        onSelected: (bool selected) {
                          setState(() {
                            selectedTransactionType = selected ? '收入' : null;
                          });
                        },
                        backgroundColor: warmColor.withOpacity(0.7),
                        selectedColor: warmColor.withOpacity(0.8),
                        labelStyle: TextStyle(
                          color: const Color.fromARGB(153, 3, 0, 0),
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.transparent),
                        ),
                        showCheckmark: false,
                      ),
                      SizedBox(width: 8),
                      FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('支出', style: TextStyle(fontSize: 12)),
                            if (selectedTransactionType == '支出') ...[
                              SizedBox(width: 4),
                              Icon(Icons.check, size: 12),
                            ],
                          ],
                        ),
                        selected: selectedTransactionType == '支出',
                        onSelected: (bool selected) {
                          setState(() {
                            selectedTransactionType = selected ? '支出' : null;
                          });
                        },
                        backgroundColor: coldColor.withOpacity(0.7),
                        selectedColor: coldColor.withOpacity(0.8),
                        labelStyle: TextStyle(
                          color: const Color.fromARGB(153, 3, 0, 0),
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.transparent),
                        ),
                        showCheckmark: false,
                      ),
                    ],
                  ),
                  Divider(color: Colors.grey.withOpacity(0.8), thickness: 1),
                  Text('标签', style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      String categoryString =
                          '${category['emoji']}${category['label']}';
                      return FilterChip(
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(categoryString),
                            if (selectedFilterCategories
                                .contains(categoryString)) ...[
                              SizedBox(width: 4),
                              Icon(Icons.check, size: 12),
                            ],
                          ],
                        ),
                        selected:
                            selectedFilterCategories.contains(categoryString),
                        onSelected: (bool selected) {
                          setState(() {
                            if (selected) {
                              selectedFilterCategories.add(categoryString);
                            } else {
                              selectedFilterCategories.remove(categoryString);
                            }
                          });
                        },
                        backgroundColor: category['color'].withOpacity(0.7),
                        selectedColor: category['color'].withOpacity(0.8),
                        labelStyle: TextStyle(
                          color: const Color.fromARGB(153, 3, 0, 0),
                          fontSize: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.transparent),
                        ),
                        showCheckmark: false,
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 16),
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
                (jsonDecode(record['categories'] ?? '[]') as List)
                    .cast<String>();
          } catch (e) {
            print('Error decoding categories: $e');
          }

          bool matchesCategories = selectedFilterCategories.isEmpty ||
              selectedFilterCategories.any((filterCategory) =>
                  recordCategories.contains(filterCategory));

          return matchesType && matchesCategories;
        }).toList();
      }
    });
  }

  // 修改排序记录的方法
  void _sortRecords() {
    // 确定要排序的列表
    List<Map<String, String>> listToSort =
        isFiltered ? filteredRecords : records;

    listToSort.sort((a, b) {
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

    setState(() {
      // 如果是筛选状态，更新筛选后的列表
      if (isFiltered) {
        filteredRecords = List.from(listToSort);
      } else {
        records = List.from(listToSort);
        _saveRecords(); // 只有在排序原始记录时才存
      }
    });
  }

  // 修改按金额排序的方法
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

  // 修改按时间排序的方法
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

  // 添加图表数据的方法
  void _updateChartData() {
    // 初始化数据映射
    Map<DateTime, double> expenseByDate = {};
    Map<DateTime, double> incomeByDate = {};
    Map<DateTime, double> netIncomeByDate = {};

    // 获取今天的日期（去除时分秒）
    DateTime today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );

    // 创建包含5天的日期列（前3天、今天和明天）
    List<DateTime> dates = [
      today.subtract(Duration(days: 3)),
      today.subtract(Duration(days: 2)),
      today.subtract(Duration(days: 1)),
      today,
      today.add(Duration(days: 1)),
    ];

    // 初始化所有日期的数据为0
    for (DateTime date in dates) {
      expenseByDate[date] = 0;
      incomeByDate[date] = 0;
      netIncomeByDate[date] = 0;
    }

    // 累加每天的数据
    for (var record in records) {
      try {
        // 解析时间戳并转换为本地时间
        DateTime recordDate =
            DateTime.parse(record['timestamp'] ?? '').toLocal();
        // 只保留年月日
        recordDate =
            DateTime(recordDate.year, recordDate.month, recordDate.day);

        // 检查日期是否在我们关心的范围内
        DateTime matchingDate = dates.firstWhere(
          (date) =>
              date.year == recordDate.year &&
              date.month == recordDate.month &&
              date.day == recordDate.day,
          orElse: () => dates[0], // 返回默认日期而不是 null
        );

        if (dates.contains(matchingDate)) {
          // 只在日期在范围内时处理
          // 解析金额
          double amount = double.tryParse(record['amount'] ?? '0') ?? 0;

          // 根据类型更新对应的数据
          if (record['type'] == '支出') {
            expenseByDate[matchingDate] =
                (expenseByDate[matchingDate] ?? 0) + amount;
            netIncomeByDate[matchingDate] =
                (netIncomeByDate[matchingDate] ?? 0) - amount;
          } else if (record['type'] == '收入') {
            incomeByDate[matchingDate] =
                (incomeByDate[matchingDate] ?? 0) + amount;
            netIncomeByDate[matchingDate] =
                (netIncomeByDate[matchingDate] ?? 0) + amount;
          }
        }
      } catch (e) {
        print('Error processing record: $e');
      }
    }

    setState(() {
      _expenseSpots = [];
      _incomeSpots = [];
      _netIncomeSpots = [];

      // 先生成前4天的实际数据点
      for (int i = 0; i < 4; i++) {
        DateTime date = dates[i];
        _expenseSpots.add(FlSpot(i.toDouble(), expenseByDate[date] ?? 0));
        _incomeSpots.add(FlSpot(i.toDouble(), incomeByDate[date] ?? 0));
        _netIncomeSpots.add(FlSpot(i.toDouble(), netIncomeByDate[date] ?? 0));
      }

      // 计算并添加预测值
      double predictedExpense = _predictNextValue(_expenseSpots);
      double predictedIncome = _predictNextValue(_incomeSpots);
      double predictedNetIncome = _predictNextValue(_netIncomeSpots);

      print(
          '预测值: 支出=$predictedExpense, 收入=$predictedIncome, 净收入=$predictedNetIncome'); // 添加调试输出

      // 添加预测的第5天数据
      _expenseSpots.add(FlSpot(4, predictedExpense));
      _incomeSpots.add(FlSpot(4, predictedIncome));
      _netIncomeSpots.add(FlSpot(4, predictedNetIncome));

      // 计算最大最小值
      List<double> allValues = [
        ..._expenseSpots.map((spot) => spot.y),
        ..._incomeSpots.map((spot) => spot.y),
        ..._netIncomeSpots.map((spot) => spot.y),
      ];

      if (allValues.isEmpty || allValues.every((value) => value == 0)) {
        _maxY = 100; // 设置默认最大值
        _minY = -100; // 修改默认最小值为负数
      } else {
        _maxY = allValues.reduce(math.max) * 1.1;
        _minY = allValues.reduce(math.min) * 1.5; // 将系数从0.9改为1.2，使最小值范围更大

        if (_maxY == _minY) {
          _maxY += 1;
          _minY -= 1;
        }
      }

      // 分割现有数据和预测数据（今天的索引是3）
      _expenseSpotsReal = _expenseSpots.sublist(0, 4); // 0到今
      _expenseSpotsFuture = _expenseSpots.sublist(3); // 今天到明天
      _incomeSpotsReal = _incomeSpots.sublist(0, 4);
      _incomeSpotsFuture = _incomeSpots.sublist(3);
      _netIncomeSpotsReal = _netIncomeSpots.sublist(0, 4);
      _netIncomeSpotsFuture = _netIncomeSpots.sublist(3);
    });
  }

  // 修改图表相关的Widget构建
  Widget _buildChart() {
    if (_expenseSpots.isEmpty) return SizedBox.shrink();
    final themeColor = Theme.of(context).primaryColor;
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final warmColor = ColorScorer.getWarmColor(themeColor, textColor);
    final coldColor = ColorScorer.getColdColor(themeColor, textColor);
    final chartColor = ColorScorer.lerpColorWithBias(warmColor, coldColor);

    return Column(
      children: [
        Row(
          children: [
            Text('  净收入 :',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color.fromARGB(255, 129, 129, 129))),
            Text(' ${_netIncomeSpots.last.y.toStringAsFixed(2)}',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: chartColor)),
            Spacer(),
            // 添加图例
            Row(
              children: [
                Container(
                  margin: EdgeInsets.only(right: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 2,
                        color: warmColor,
                      ),
                      SizedBox(width: 4),
                      Text('收入',
                          style: TextStyle(fontSize: 12, color: warmColor)),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 10),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 2,
                        color: coldColor,
                      ),
                      SizedBox(width: 4),
                      Text('支出',
                          style: TextStyle(fontSize: 12, color: coldColor)),
                    ],
                  ),
                ),
                Container(
                  margin: EdgeInsets.only(right: 0),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 2,
                        color: chartColor,
                      ),
                      SizedBox(width: 4),
                      Text('净收入',
                          style: TextStyle(fontSize: 12, color: chartColor)),
                    ],
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Icon(
                  _isChartExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  _isChartExpanded = !_isChartExpanded;
                  _saveChartExpandedState();
                });
              },
              tooltip: _isChartExpanded ? '收起图表' : '展开图表',
            ),
          ],
        ),
        AnimatedContainer(
          duration: Duration(milliseconds: 280),
          height: _isChartExpanded ? 170 : 0,
          child: SingleChildScrollView(
            physics: NeverScrollableScrollPhysics(),
            child: Container(
              height: 180,
              padding: EdgeInsets.only(left: 12, right: 17, top: 5, bottom: 0),
              child: LineChart(
                LineChartData(
                  minY: _minY,
                  maxY: _maxY,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    horizontalInterval:
                        math.max((_maxY - _minY) / 10, 0.1), // 添加最小值限制
                    verticalInterval: 1,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1.2,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.withOpacity(0.2),
                        strokeWidth: 1.2,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: math.max((_maxY - _minY) / 5, 0.1),
                        getTitlesWidget: (value, meta) {
                          // 如果是最小值，则不显示
                          if (value == _minY || value == _maxY) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toStringAsFixed(0),
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        getTitlesWidget: (value, meta) {
                          if (value % 1 != 0) return Text('');
                          final index = value.toInt();
                          if (index < 0 || index >= 5) return Text('');

                          final today = DateTime.now();
                          final date =
                              today.add(Duration(days: index - 3)); // 3天前到明天

                          String dateText = '${date.month}/${date.day}';

                          return Padding(
                            padding: const EdgeInsets.only(
                                left: 10, right: 10, top: 10, bottom: 10),
                            child: Text(
                              dateText, // 给text加上边界
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 11,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  lineBarsData: [
                    // 支出曲线
                    LineChartBarData(
                      spots: _expenseSpots, // 使用所有5个点
                      color: coldColor,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      isCurved: true,
                    ),
                    // 收入曲线
                    LineChartBarData(
                      spots: _incomeSpots,
                      color: warmColor,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      isCurved: true,
                    ),
                    // 净收入曲线
                    LineChartBarData(
                      spots: _netIncomeSpots,
                      color: chartColor,
                      barWidth: 2,
                      dotData: FlDotData(show: false),
                      isCurved: true,
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                      getTooltipItems: (List<LineBarSpot> touchedSpots) {
                        return touchedSpots.map((spot) {
                          String title = spot.barIndex == 0
                              ? '支出: '
                              : spot.barIndex == 1
                                  ? '收入: '
                                  : '净收入: ';
                          return LineTooltipItem(
                            '$title${spot.y.toStringAsFixed(2)}',
                            TextStyle(color: Colors.white, fontSize: 12),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border(
                      left: BorderSide(
                        color: Colors.grey.withOpacity(0.5), // 左边框颜色
                        width: 1.5, // 左边框宽度
                      ),
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.5), // 下边框颜色
                        width: 1.5, // 下边框宽度
                      ),
                      top: BorderSide(
                        color: Colors.grey.withOpacity(0.2), // 上边框颜色（更淡）
                        width: 1, // 上边框宽度（更细）
                      ),
                      right: BorderSide(
                        color: Colors.grey.withOpacity(0.2), // 右边框颜色（更淡）
                        width: 1, // 右边框宽度（更细）
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final warmColor = ColorScorer.getWarmColor(themeColor, textColor);
    final coldColor = ColorScorer.getColdColor(themeColor, textColor);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child //: _isLoading
          //? Center(child: CircularProgressIndicator()) // 显示加载中的进度条
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
                                  color:
                                      const Color.fromARGB(255, 100, 100, 100),
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
                        ),
                        Expanded(
                          flex: 2,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildTransactionTypeCheckbox('收入', warmColor),
                              _buildTransactionTypeCheckbox('支出', coldColor),
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
                            bool isSelected =
                                selectedCategories.contains(categoryString);
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
                                    if (isSelected) Icon(Icons.check, size: 12),
                                  ],
                                ),
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap, // 减小点击区域
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4), // 减小内边距
                                selected: isSelected,
                                onSelected: (bool selected) {
                                  setState(() {
                                    if (selected) {
                                      selectedCategories.add(categoryString);
                                    } else {
                                      selectedCategories.remove(categoryString);
                                    }
                                  });
                                },
                                backgroundColor: category['color']
                                    .withOpacity(0.8), // 减小不选中时的透明度
                                selectedColor: category['color']
                                    .withOpacity(1.0), // 减小选中时的透明度
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(8), // 减小圆角
                                  side: BorderSide(color: Colors.transparent),
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
                                  color:
                                      const Color.fromARGB(255, 100, 100, 100),
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
                                  255, 214, 214, 214), // 设置获点时的横线颜色
                            ),
                          ),
                        ),
                        SizedBox(width: 25),
                        Expanded(
                          flex: 0,
                          child:
                              // 添加记录按钮
                              ElevatedButton(
                            onPressed: _addRecord, // 添加记录
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
                    SizedBox(height: 8), // 下一个输入框的间隔
                  ],
                ),
              ),
            ),
          ),
          SizedBox(height: 8),
          _buildChart(), // 图表
          SizedBox(height: 8),
          // 新增：视图切换图标
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
                    ? (_isTimeAscending ? '从旧到新' : '从新到')
                    : '按时间排序',
                color:
                    _sortType == 'time' ? Theme.of(context).primaryColor : null,
              ),
              IconButton(
                icon: Icon(_viewMode == 0
                    ? Icons.grid_view_sharp // 列表视图时显示2网格图标
                    : _viewMode == 1
                        ? Icons.grid_3x3 // 2列网格时显示3列网格图标
                        : Icons.view_list), // 3列网格时显示列表图标
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
                tooltip: _isDeleteMode ? '退出删除模式' : '入删除模式',
              ),
            ],
          ),
          SizedBox(height: 8),
          // 账单列
          Expanded(
            child: _viewMode == 0
                ? ListView.builder(
                    // 列表视图的现有代码保持不变
                    itemCount:
                        isFiltered ? filteredRecords.length : records.length,
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
                            ? constraints.maxWidth / 2 // 2列网格
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
  Widget _buildRecordItem(BuildContext context, int index,
      BoxConstraints constraints, List<Map<String, String>> displayRecords) {
    final themeColor = Theme.of(context).primaryColor;
    final textColor =
        Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final warmColor = ColorScorer.getWarmColor(themeColor, textColor);
    final coldColor = ColorScorer.getColdColor(themeColor, textColor);

    List<String> recordCategories = [];
    try {
      recordCategories =
          (jsonDecode(displayRecords[index]['categories'] ?? '[]') as List)
              .cast<String>();
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
            'emoji': '', // 移除emoji
            'label': categoryString,
            'color': themeColor, // 使用主题色作为默认颜色
            'isTemporary': true
          };
        },
      );

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: (category['color'] as Color).withOpacity(0.8),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          category['isTemporary'] == true
              ? categoryString // 临时类别直接显示完整文本
              : '${category['emoji']} ${category['label']}', // 永久类别显示emoji和标签
          style: TextStyle(
            fontSize: 10,
            color:
                displayRecords[index]['type'] == '收入' ? warmColor : coldColor,
          ),
        ),
      );
    }

    if (_viewMode == 0) {
      // 列表视的布局保持原来的样式）
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
                    color: displayRecords[index]['type'] == '收入'
                        ? warmColor
                        : coldColor,
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
                          if (displayRecords[index]['note']?.isNotEmpty ??
                              false) ...[
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

  // 加颜色选器方法
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
    _updateChartData();
  }

  // 添加这个辅助方法
  List<int>? _getDashArray({required int index}) {
    return [3, 3]; // 只对最后一段应用虚线
  }

  // 添加预测下一个值的方法
  double _predictNextValue(List<FlSpot> spots) {
    if (spots.isEmpty) return 0;
    if (spots.length == 1) return spots[0].y;

    // 使用简单线性回归预测
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;
    int n = spots.length;

    for (int i = 0; i < n; i++) {
      sumX += spots[i].x;
      sumY += spots[i].y;
      sumXY += spots[i].x * spots[i].y;
      sumX2 += spots[i].x * spots[i].x;
    }

    double slope = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
    double intercept = (sumY - slope * sumX) / n;

    return slope * n + intercept;
  }
}
