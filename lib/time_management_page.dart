import 'package:flutter/material.dart'; // 导入Flutter材料设计库
import 'dart:async'; // 导入异步编程支持
import 'package:shared_preferences/shared_preferences.dart'; // 导入本地存储库
import 'dart:convert'; // 导入JSON编解码支持
import 'dart:math'; 

// 定义一个有状态的时间管理页面小部件
class TimeManagementPage extends StatefulWidget {
  @override
  TimeManagementPageState createState() => TimeManagementPageState(); // 创建时间管理页面的状态
}

// 定义任务类
class Task {
  String name; // 任务名称
  int timeSpent; // 已花费时间（秒）
  bool isCompleted; // 是否完成
  bool isExpanded; // 添加折叠状态

  // 构造函数
  Task(this.name, {this.timeSpent = 0, this.isCompleted = false, this.isExpanded = true});

  // 将任务转换为JSON格式
  Map<String, dynamic> toJson() => {
    'name': name,
    'timeSpent': timeSpent,
    'isCompleted': isCompleted,
    'isExpanded': isExpanded,
  };

  // 从JSON格式创建任务
  Task.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        timeSpent = json['timeSpent'],
        isCompleted = json['isCompleted'],
        isExpanded = json['isExpanded'] ?? true;
}

// 定义时间管理页面的状态类
class TimeManagementPageState extends State<TimeManagementPage> {
  int _remainingTime = 25 * 60; // 剩余时间（秒）
  bool _isRunning = false; // 计时器是否运行
  Timer? _timer; // 计时器
  List<Task> _tasks = []; // 任务列表
  final _taskController = TextEditingController(); // 任务输入控制器
  int _currentTaskIndex = -1; // 当前任务索引
  bool _isCountUp = false; // 是否为正向计时
  int _customDuration = 25 * 60; // 自定义时长（秒）

  @override
  void initState() {
    super.initState();
    _loadTasks(); // 加载保存的任务
  }

  // 从本地存储加载任务
  Future<void> _loadTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = prefs.getString('tasks');
    if (tasksJson != null) {
      final tasksList = jsonDecode(tasksJson) as List;
      setState(() {
        _tasks = tasksList.map((taskJson) => Task.fromJson(taskJson)).toList();
      });
    }
  }

  // 保存任务到本地存储
  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString('tasks', tasksJson);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor; // 获取主题主色
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black; // 获取文本颜色
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white; // 获取卡片颜色
    final warmColor = _getWarmColor(Theme.of(context).primaryColor, textColor); // 获取暖色
    final coldColor = _getColdColor(Theme.of(context).primaryColor, textColor); // 获取冷色

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // 设置背景颜色
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: cardColor,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      children: [
                        Text(
                          _isCountUp ? _formatTime(_remainingTime) : _formatTime(_remainingTime),
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                            fontSize: 60,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          _currentTaskIndex != -1 ? '当前任务: ${_tasks[_currentTaskIndex].name}' : '没有正在进行的任务',
                          style: TextStyle(fontSize: 16),
                        ),
                        SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton(
                              onPressed: _isRunning ? _pauseTimer : _startTimer, // 根据状态显示暂停或开始按钮
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: textColor,
                              ),
                              child: Text(_isRunning ? '暂停' : '开始'),
                            ),
                            ElevatedButton(
                              onPressed: _resetTimer, // 重置计时器
                              style: ElevatedButton.styleFrom(
                                backgroundColor: themeColor,
                                foregroundColor: textColor,
                              ),
                              child: Text('重置'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton(
                      icon: Icon(Icons.settings),
                      onPressed: _showSettingsDialog,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Row(
              children: [
                SizedBox(width:8),
                Expanded(
                  child: TextField(
                    controller: _taskController, // 任务输入控制器
                    decoration: InputDecoration(
                      labelText: '添加任务',
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
                      border: UnderlineInputBorder(), // 文字＋底部横线
                    ),
                    cursorColor:  const Color.fromARGB(255, 214, 214, 214),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addTask, // 添加任务
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: textColor,
                  ),
                  child: Text('添加'),
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ReorderableListView(
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (oldIndex < newIndex) {
                      newIndex -= 1;
                    }
                    final Task item = _tasks.removeAt(oldIndex);
                    _tasks.insert(newIndex, item);
                    _saveTasks();
                  });
                },
                children: _tasks.asMap().entries.map((entry) {
                  return _buildTaskCard(entry.key, entry.value);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 添加任务
  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(Task(_taskController.text));
        _taskController.clear();
        _saveTasks();
      });
    }
  }

  // 删除任务
  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
      if (_currentTaskIndex == index) {
        _timer?.cancel();
        _isRunning = false;
        _currentTaskIndex = -1;
        _remainingTime = 25 * 60;
      } else if (_currentTaskIndex > index) {
        _currentTaskIndex--;
      }
      _saveTasks();
    });
  }

  // 开始计时器
  void _startTimer() {
    if (_tasks.isEmpty || _tasks.every((task) => task.isCompleted)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('没有可执行的任务')),
      );
      return;
    }

    setState(() {
      _isRunning = true;
      if (_currentTaskIndex == -1) {
        _currentTaskIndex = _tasks.indexWhere((task) => !task.isCompleted);
      }
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_isCountUp) {
            // 正向计时逻辑
            _remainingTime++;
            _tasks[_currentTaskIndex].timeSpent++;
          } else {
            // 倒计时逻辑
            if (_remainingTime > 0) {
              _remainingTime--;
              _tasks[_currentTaskIndex].timeSpent++;
              if (_tasks[_currentTaskIndex].timeSpent >= _customDuration) {
                _completeTask(_currentTaskIndex);
              }
            } else {
              _timer?.cancel();
              _isRunning = false;
              _currentTaskIndex = -1;
              _remainingTime = _customDuration;
            }
          }
          _saveTasks();
        });
      });
    });
  }

  // 暂停计时器
  void _pauseTimer() {
    setState(() {
      _isRunning = false;
      _timer?.cancel();
    });
  }

  // 重置计时器
  void _resetTimer() {
    setState(() {
      _timer?.cancel();
      _remainingTime = _isCountUp ? 0 : _customDuration;
      _isRunning = false;
    });
  }

  // 完成任务
  void _completeTask(int index) {
    setState(() {
      _tasks[index].isCompleted = true;
      _timer?.cancel();
      _isRunning = false;
      _currentTaskIndex = -1;
      _remainingTime = 25 * 60;
      _saveTasks();
    });
  }

  // 格式化时间
  String _formatTime(int time) {
    int minutes = time ~/ 60;
    int seconds = time % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  // 获取暖色
  Color _getWarmColor(Color color1, Color color2) {
    return _isWarmer(color1, color2) ? color1 : color2;
  }

  // 获取冷色
  Color _getColdColor(Color color1, Color color2) {
    return _isWarmer(color1, color2) ? color2 : color1;
  }

  // 判断哪个颜色更暖
  bool _isWarmer(Color color1, Color color2) {
    // 简单地比较红色和蓝色分量
    return (color1.red - color1.blue) > (color2.red - color2.blue);
  }

  // 添加设置对话框方法
  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        String? minutes;
        return AlertDialog(
          title: Text('计时器设置'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<bool>(
                title: Text('倒计时模式'),
                value: false,
                groupValue: _isCountUp,
                onChanged: (value) {
                  setState(() => _isCountUp = value!);
                  Navigator.pop(context);
                },
              ),
              RadioListTile<bool>(
                title: Text('正向计时'),
                value: true,
                groupValue: _isCountUp,
                onChanged: (value) {
                  setState(() => _isCountUp = value!);
                  Navigator.pop(context);
                },
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: '自定义时长（分钟）',
                    hintText: '请输入1-60之间的数字',
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) => minutes = value,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('取消'),
            ),
            TextButton(
              onPressed: () {
                if (minutes != null) {
                  int? mins = int.tryParse(minutes!);
                  if (mins != null && mins > 0 && mins <= 60) {
                    setState(() {
                      _customDuration = mins * 60;
                      _remainingTime = _customDuration;
                    });
                  }
                }
                Navigator.pop(context);
              },
              child: Text('确定'),
            ),
          ],
        );
      },
    );
  }

  // 构建任务卡片
  Widget _buildTaskCard(int index, Task task) {
    final int totalBars = (task.timeSpent / (25 * 60)).ceil();
    final bool hasMultipleBars = totalBars > 1;

    return Card(
      key: ValueKey(task),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    task.name,
                    style: TextStyle(
                      decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                    ),
                  ),
                ),
                if (hasMultipleBars)
                  IconButton(
                    icon: Icon(
                      task.isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        task.isExpanded = !task.isExpanded;
                        _saveTasks();
                      });
                    },
                  ),
              ],
            ),
            subtitle: Column(
              children: [
                // 第一个进度条（始终显示）
                LinearProgressIndicator(
                  value: min(1.0, (task.timeSpent % (25 * 60)) / (25 * 60)),
                  backgroundColor: const Color.fromARGB(255, 214, 214, 214),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    task.isCompleted ? _getWarmColor(Theme.of(context).primaryColor, Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black) 
                                  : _getColdColor(Theme.of(context).primaryColor, Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black),
                  ),
                ),
                // 额外的进度条（可折叠）
                if (hasMultipleBars && task.isExpanded)
                  ...List.generate(totalBars - 1, (barIndex) {
                    return Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: LinearProgressIndicator(
                        value: barIndex < totalBars - 2 ? 1.0 
                            : (task.timeSpent - (25 * 60 * (totalBars - 1))) / (25 * 60),
                        backgroundColor: const Color.fromARGB(255, 214, 214, 214),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          task.isCompleted ? _getWarmColor(Theme.of(context).primaryColor, Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black) 
                                        : _getColdColor(Theme.of(context).primaryColor, Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black),
                        ),
                      ),
                    );
                  }),
              ],
            ),
            trailing: IconButton(
              icon: Icon(
                Icons.delete,
                color: const Color.fromARGB(255, 214, 214, 214),
              ),
              onPressed: () => _deleteTask(index),
            ),
          ),
        ],
      ),
    );
  }
}