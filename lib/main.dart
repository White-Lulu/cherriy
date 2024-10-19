import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

void main() {
  runZonedGuarded(() {
    WidgetsFlutterBinding.ensureInitialized();
    runApp(MyApp());
  }, (error, stackTrace) {
    print('错误: $error');
    print('堆栈跟踪: $stackTrace');
  });
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF4A90E2),
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: AppBarTheme(
          backgroundColor: Color(0xFF4A90E2),
          elevation: 0,
        ),
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: Colors.white,
          selectedItemColor: Color(0xFF4A90E2),
          unselectedItemColor: Colors.grey[600],
          elevation: 8,
        ),
        cardTheme: CardTheme(
          color: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          filled: true,
          fillColor: Colors.grey[200],
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF4A90E2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  HomePageState createState() => HomePageState();
}

class HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    AccountingPage(),
    TodoPage(),
    TimeManagementPage(),
    DiaryPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Personal Manager'),
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
        backgroundColor: Colors.blue,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
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

// 记账
class AccountingPage extends StatefulWidget {
  @override
  AccountingPageState createState() => AccountingPageState();
}

class AccountingPageState extends State<AccountingPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  final _noteController = TextEditingController();
  List<Map<String, String>> records = [];
  bool _isLoading = true;
  String _transactionType = '支出';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedRecords = prefs.getString('accountingRecords');
    if (savedRecords != null) {
      setState(() {
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

  Future<void> _saveRecords() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('accountingRecords', jsonEncode(records));
  }

  void _addRecord() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        records.add({
          'amount': _amountController.text,
          'category': _categoryController.text,
          'note': _noteController.text,
          'type': _transactionType,
        });
        _amountController.clear();
        _categoryController.clear();
        _noteController.clear();
      });
      _saveRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
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
                      SizedBox(height: 16), // 添加间距
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
                      SizedBox(height: 16), // 添加间距
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
                      SizedBox(height: 16), // 添加间距
                      TextFormField(
                        controller: _noteController,
                        decoration: InputDecoration(labelText: '备注'),
                      ),
                  
                      SizedBox(height:24),  // 在按钮之前增加更多间距
                      ElevatedButton(
                        onPressed: _addRecord,
                        child: Text('添加记录'),
                      ),
                    ],
                  ),
                    ),
                  ),
                 ),
                SizedBox(height: 16),
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

// Todo
class TodoPage extends StatefulWidget {
  @override
  TodoPageState createState() => TodoPageState();
}

class TodoPageState extends State<TodoPage> {
  final _todoController = TextEditingController();
  List<Map<String, dynamic>> todos = [];

  @override
  void initState() {
    super.initState();
    _loadTodos();  // 加载代办数  
  }

  void _loadTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedTodos = prefs.getString('todoList');
    if (savedTodos != null) {
      setState(() {
        todos = List<Map<String, dynamic>>.from(jsonDecode(savedTodos));
      });
    }
  }

  void _saveTodos() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('todoList', jsonEncode(todos));
  }

  void _addTodo() {
    if (_todoController.text.isNotEmpty) {
      setState(() {
        todos.add({'task': _todoController.text, 'completed': false});
        _saveTodos();  // 保存代办事项
        _todoController.clear();
      });
    }
  }

  void _toggleComplete(int index) {
    setState(() {
      todos[index]['completed'] = !todos[index]['completed'];
      _saveTodos();  // 更新状态后保存数据
    });
  }

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
              labelText: '代办事项',
              suffixIcon: IconButton(
                icon: Icon(Icons.add),
                onPressed: _addTodo,
              ),
              ),
              ),
            ),
          ),
          SizedBox(height: 16),
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
                        Checkbox(
                          value: todos[index]['completed'],
                          onChanged: (value) => _toggleComplete(index),
                        ),
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

// 时间管理
class TimeManagementPage extends StatefulWidget {
  @override
  TimeManagementPageState createState() => TimeManagementPageState();
}

class TimeManagementPageState extends State<TimeManagementPage> {
  int _remainingTime = 25 * 60; // 25分钟
  bool _isRunning = false;
  Timer? _timer;

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer?.cancel();
          _isRunning = false;
        }
      });
    });
  }

  void _resetTimer() {
    setState(() {
      _timer?.cancel();
      _remainingTime = 25 * 60;
      _isRunning = false;
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF4A90E2), Color(0xFF63B8FF)],
        ),
      ),
      child: Center(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
            children: [
              Text(
            _formatTime(_remainingTime),
            style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: _isRunning ? null : _startTimer,
                child: Text('开始'),
              ),
              SizedBox(width: 20),
              ElevatedButton(
                onPressed: _resetTimer,
                child: Text('重置'),
              ),
            ],
          ),
            ],
          ),
          ),
        ),
      ),
    );
  }
}

// 日记
class DiaryPage extends StatefulWidget {
  @override
  DiaryPageState createState() => DiaryPageState();
}

class DiaryPageState extends State<DiaryPage> {
  final _diaryController = TextEditingController();
  List<Map<String, String>> diaries = []; // 修改为 List<Map<String, String>>
  String _selectedMood = '😊';
  final List<String> _moods = ['😊', '😐', '😢', '😡', '😴'];

  @override
  void initState() {
    super.initState();
    _loadDiaries();  // 初始化加载日记
  }

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

  void _saveDiaries() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String jsonString = jsonEncode(diaries.map((diary) => 
    Map<String, String>.from(diary)
  ).toList());
  await prefs.setString('diaries', jsonString);
}

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
