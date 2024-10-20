import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import 'package:provider/provider.dart';
import 'providers/theme_provider.dart';
import 'theme_settings_page.dart';
import 'time_management_page.dart'; // 确保这行导入存在

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
      title: 'Personal Manager',
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
        title: Text('Personal Manager'),
        actions: [
          IconButton(
            icon: Icon(Icons.settings),
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
        // 移除这些颜色设置，��主题控制颜色
        // backgroundColor: Colors.blue,
        // selectedItemColor: Colors.white,
        // unselectedItemColor: Colors.white70,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: '记账'),
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: '代办'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: '时间管理'),
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
    // 获取主题颜色
    final themeColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;

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
                      // 交易类型下拉选择框
                      DropdownButtonFormField<String>(
                        value: _transactionType,
                        items: ['收入', '支出'].map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _transactionType = newValue!;
                          });
                        },
                        decoration: InputDecoration(labelText: '类型'),
                      ),
                      SizedBox(height: 16),
                      // 金额输入框
                      TextFormField(
                        controller: _amountController,
                        decoration: InputDecoration(labelText: '金额'),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入金额';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      // 类别输入框
                      TextFormField(
                        controller: _categoryController,
                        decoration: InputDecoration(labelText: '类别'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return '请输入类别';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      // 备注输入框
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(labelText: '备注'),
                      ),
                      SizedBox(height:24),
                      // 添加记录按钮
                      ElevatedButton(
                        onPressed: _addRecord,
                        child: Text('添加记录'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: themeColor,
                          foregroundColor: textColor,
                        ),
                      ),
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
                            leading: Icon(
                            records[index]['type'] == '收入' ? Icons.arrow_upward : Icons.arrow_downward,
                            color: records[index]['type'] == '收入' ? Colors.green : Colors.red,
                          ),
                          title: Text('金额: ${records[index]['amount']}'),
                          subtitle: Text('类别: ${records[index]['category']}\n备注: ${records[index]['note']}'),
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child:
                TextField(
                  controller: _todoController,
                  decoration: InputDecoration(
                    labelText: '待办事项',
                    suffixIcon: IconButton(
                      icon: Icon(Icons.add),
                      onPressed: _addTodo,
                    ),
                  ),
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
                        ),
                        // 删除按钮
                        IconButton(
                          icon: Icon(Icons.delete),
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
  final List<String> _moods = ['😊', '😐', '😢', '😡', '😴'];

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
      setState(() {
        diaries.add({
          'date': DateTime.now().toString(),
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
              suffixIcon: IconButton(
                icon: Icon(Icons.save),
                onPressed: _addDiary,
              ),
            ),
            maxLines: 3,
          ),
          // 日记列表
          Expanded(
            child: ListView.builder(
              itemCount: diaries.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: ListTile(
                    leading: Text(diaries[index]['mood'] ?? '😐', style: TextStyle(fontSize: 24)),
                    title: Text(diaries[index]['content'] ?? ''),
                    subtitle: Text(diaries[index]['date'] ?? ''),
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

