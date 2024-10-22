import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'theme_settings_page.dart';
import 'time_management_page.dart'; // 确保这行导入存在
import 'package:intl/intl.dart';

// 主函数，应用程序的入口点
void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(
      ChangeNotifierProvider(
        create: (context) => ThemeProvider(ThemeData.light()),
        child: MyApp(),
      ),
    );
  }, (error, stackTrace) {
    print('错误: $error');
    print('堆栈跟踪: $stackTrace');
  });
}

// MyApp 类，定义应用程序的整体结构和主题
class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState();
}


class MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      title: 'Cherriy (o^^o)♪',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      home: MyHomePage(),
    );
  }
}

// HomePage 类，定义应用序的主页面
class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState();
}

class MyHomePageState extends State<MyHomePage> {
  // 当前选中的底部导航栏索引
  int _currentIndex = 0;
  // 定义页面列表
  final List<Widget> _pages = [
    AccountingPage(),
    TodoPage(),
    TimeManagementPage(), // 确保这里使用的是 TimeManagementPage
    DiaryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cherriy (o^^o)♪'),
        actions: [
          IconButton(
            icon: Icon(Icons.palette),
            onPressed: () {
              // 导航到主题设置页面
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ThemeSettingsPage()),
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        // 移除这些颜色设置，主题控制颜色
        // backgroundColor: Colors.blue,
        // selectedItemColor: Colors.white,
        // unselectedItemColor: Colors.white70,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: '记账'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: '代办'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: '计时'),
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '日记'),
        ],
      ),
    );
  }
}

// 记账页面
class AccountingPage extends StatefulWidget {
  @override
  AccountingPageState createState() => AccountingPageState();
}

class AccountingPageState extends State<AccountingPage> {
  // 表单的全局键，用于验证表单
  final _formKey = GlobalKey<FormState>();
  // 控制器，用于获取用户输入的金额、类别和备注
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  // 存储记账记录的列表
  List<Map<String, String>> records = [];
  // 标记是否正在加载数据
  bool _isLoading = true;
  // 交易类型，默认为支出
  String _transactionType = '支出';

  @override
  void initState() {
    super.initState();
    // 初始化时加载记录
    _loadRecords();
  }

  // 从本地存储加载记账记录
  Future<void> _loadRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedRecords = prefs.getString('accountingRecords');
    if (savedRecords != null) {
      setState(() {
        // 解码JSON并转换为List<Map<String, String>>
        records = (jsonDecode(savedRecords) as List<dynamic>)
            .map((item) => Map<String, String>.from(item))
            .toList();
        _isLoading = false;
      });
    } else { 
      setState(() {
        _isLoading = false;
      });
    }
  }

  // 保存记账记录到本地存储
  Future<void> _saveRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('accountingRecords', jsonEncode(records));
  }

  // 添加新记账记录
  void _addRecord() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        records.add({
          'amount': _amountController.text,
          'category': _categoryController.text,
          'note': _noteController.text,
          'type': _transactionType,
        });
        // 清空输入框
        _amountController.clear();
        _categoryController.clear();
        _noteController.clear();
      });
      _saveRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    // 获取主题颜色 (声明常量)
    final themeColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final warmColor = _getWarmColor(Theme.of(context).primaryColor, textColor);
    final coldColor = _getColdColor(Theme.of(context).primaryColor, textColor);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                 Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: 
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // 金额输入框                         
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(
                          labelText: '金额',
                          labelStyle: TextStyle(
                          color: const Color.fromARGB(255, 100, 100, 100), ),// 设置labelText的颜色
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color:const Color.fromARGB(255, 214, 214, 214), // 设置横线颜色
                              width:1.5, // 设置横线粗细
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: themeColor, // 设置获取焦点时的横线颜色
                              width:2.0, // 设置获取焦点时的横线粗细
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
                       cursorColor:  const Color.fromARGB(255, 214, 214, 214), // 设置获取焦点时的横线颜色
                      ),
                      SizedBox(height: 16),
                      // 类别输入框
                      TextFormField(
                        controller: _categoryController,
                        decoration: InputDecoration(
                          labelText: '类别',
                          labelStyle: TextStyle(
                          color: const Color.fromARGB(255, 100, 100, 100), ),// 设置labelText的颜色
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: const Color.fromARGB(255, 214, 214, 214),
                              width:1.5, // 设置横线粗细
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: themeColor, // 设置获取焦点时的横线颜色
                              width:2.0, // 设置获取焦点时的横线粗细
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入类别';
                          }
                          return null;
                        },
                       cursorColor:  const Color.fromARGB(255, 214, 214, 214), // 设置获取焦点时的横线颜色
                      ),
                      SizedBox(height: 16),
                      // 备注输入框
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(
                          labelText: '备注',
                          labelStyle: TextStyle(
                          color: const Color.fromARGB(255, 100, 100, 100), ),// 设置labelText的颜色
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: const Color.fromARGB(255, 214, 214, 214), // 设置横线颜色
                              width:1.5, // 设置横线粗细
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              color: themeColor, // 设置获取焦点时的横线颜色
                              width:2.0, // 设置获取焦点时的横线粗细
                            ),
                          ),
                        ),  
                       cursorColor:  const Color.fromARGB(255, 214, 214, 214), // 设置获取焦点时的横线颜色
                      ),
                      SizedBox(height:28),
                      // 交易类型选择按钮
                      Row(
                        children: [
                          // 交易类型选择按钮
                          Expanded(
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _transactionType = _transactionType == '收入' ? '' : '收入';
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _transactionType == '收入' ? Icons.check_box : Icons.check_box_outline_blank,
                                          color: _transactionType == '收入' ? warmColor : Colors.grey,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '收入',
                                          style: TextStyle(
                                            color: _transactionType == '收入' ? warmColor : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(width: 5),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        _transactionType = _transactionType == '支出' ? '' : '支出';
                                      });
                                    },
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          _transactionType == '支出' ? Icons.check_box : Icons.check_box_outline_blank,
                                          color: _transactionType == '支出' ? coldColor : Colors.grey,
                                        ),
                                        SizedBox(width: 8),
                                        Text(
                                          '支出',
                                          style: TextStyle(
                                            color: _transactionType == '支出' ? coldColor : Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 20),
                          // 添加记录按钮
                          ElevatedButton(
                            onPressed: _addRecord,  
                            style: ElevatedButton.styleFrom(
                              backgroundColor: themeColor,
                              foregroundColor: textColor,
                            ),
                            child: Text('添加记录'),
                          ),
                          SizedBox(width:25)
                        ],
                      ),
                      SizedBox(height: 8), // 与下一个输入框的间隔
                    ],
                  ),
                    ),
                  ),
                 ),
                SizedBox(height: 16),
                // 显示记账记录列表
                Expanded(
                  child: ListView.builder(
                    itemCount: records.length, 
                    itemBuilder: (context, index) {
                      return Card(
                        child: ListTile(
                          leading: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                records[index]['type'] == '收入' ? Icons.north_east : Icons.south_west,
                                color: records[index]['type'] == '收入' ?  warmColor : coldColor,
                              ),
                            ],
                          ),
                          title: Row(
                            children: [
                              Text('${records[index]['amount']}',
                              style: TextStyle(
                                color: records[index]['type'] == '收入' ?  warmColor : coldColor,
                                fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.category, size: 16,
                                    color:const Color.fromARGB(255, 214, 214, 214),
                                    ),
                                  SizedBox(width: 4),
                                  Text('${records[index]['category']}'),
                                ],
                              ),
                              SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.note, size: 16,
                                    color:const Color.fromARGB(255, 214, 214, 214),
                                    ),
                                  SizedBox(width: 4),
                                  Text('${records[index]['note']}'),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
    );
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
}

// Todo 页面
class TodoPage extends StatefulWidget {
  @override
  TodoPageState createState() => TodoPageState();
}

class TodoPageState extends State<TodoPage> {
  // 用于控制输入的待办事项文本
  final _todoController = TextEditingController();
  
  // 存储待办事项的列表
  List<Map<String, dynamic>> todos = [];

  @override
  void initState() {
    super.initState();
    _loadTodos();  // 初始化时加载待办事项
  }

  // 从本地存储加载待办事项
  void _loadTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTodos = prefs.getString('todoList');
    if (savedTodos != null) {
      setState(() {
        todos = List<Map<String, dynamic>>.from(jsonDecode(savedTodos));
      });
    }
  }

  // 保存待办事项到本地存储
  void _saveTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('todoList', jsonEncode(todos));
  }

  // 添加新的待办事项
  void _addTodo() {
    if (_todoController.text.isNotEmpty) {
      setState(() {
        todos.add({'task': _todoController.text, 'completed': false});
        _saveTodos();  // 保存待办事项
        _todoController.clear();
      });
    }
  }

  // 切换待办事项的完成状态
  void _toggleComplete(int index) {
    setState(() {
      todos[index]['completed'] = !todos[index]['completed'];
      _saveTodos();  // 更新状态后保存数据
    });
  }

  // 删除待办事项
  void _deleteTodo(int index) {
    setState(() {
      todos.removeAt(index);
      _saveTodos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TextField(
                controller: _todoController,
                decoration: InputDecoration(
                  labelText: '待办事项',
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
                    icon: Icon(Icons.add),
                    onPressed: _addTodo,
                    color: textColor,
                  ),
                ),
                cursorColor: const Color.fromARGB(255, 214, 214, 214),
              ),
            ),
          ),
          SizedBox(height: 16),
          // 显示待办事项列表
          Expanded(
            child: ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    title: Text(
                      todos[index]['task'],
                      style: TextStyle(
                        decoration: todos[index]['completed']
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 完成状态复选框
                        Checkbox(
                          value: todos[index]['completed'],
                          onChanged: (value) => _toggleComplete(index),
                          activeColor: textColor,
                          checkColor:Theme.of(context).cardColor,
                          side: BorderSide(
                            color: todos[index]['completed'] ? textColor : themeColor,
                            width:1.5,
                          ),
                        ),
                        // 删除按钮
                        IconButton(
                          icon: Icon(
                            Icons.delete,
                            color: const Color.fromARGB(255, 214, 214, 214),
                            ),
                          onPressed: () => _deleteTodo(index),
                        ),
                      ],
                    ),
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
  final List<String> _moods = ['😊', '😐', '😢', '😎', '😴'];

  @override
  void initState() {
    super.initState();
    _loadDiaries();  // 初始化时加载日记
  }

  // 从本地存储加载日记
  void _loadDiaries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedDiaries = prefs.getString('diaries');
    if (savedDiaries != null) {
      setState(() {
        diaries = List<Map<String, String>>.from(
          (jsonDecode(savedDiaries) as List).map((item) => Map<String, String>.from(item))
        );
      });
    }
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

