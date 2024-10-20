import 'package:flutter/material.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class TimeManagementPage extends StatefulWidget {
  @override
  TimeManagementPageState createState() => TimeManagementPageState();
}

class Task {
  String name;
  int timeSpent; // 以秒为单位
  bool isCompleted;

  Task(this.name, {this.timeSpent = 0, this.isCompleted = false});

  Map<String, dynamic> toJson() => {
    'name': name,
    'timeSpent': timeSpent,
    'isCompleted': isCompleted,
  };

  Task.fromJson(Map<String, dynamic> json)
      : name = json['name'],
        timeSpent = json['timeSpent'],
        isCompleted = json['isCompleted'];
}

class TimeManagementPageState extends State<TimeManagementPage> {
  int _remainingTime = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  List<Task> _tasks = [];
  final _taskController = TextEditingController();
  int _currentTaskIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

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

  Future<void> _saveTasks() async {
    final prefs = await SharedPreferences.getInstance();
    final tasksJson = jsonEncode(_tasks.map((task) => task.toJson()).toList());
    await prefs.setString('tasks', tasksJson);
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              color: cardColor,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(
                      _formatTime(_remainingTime),
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
                          onPressed: _isRunning ? null : _startTimer,
                          child: Text('开始'),
                        ),
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
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      labelText: '添加任务',
                      border: UnderlineInputBorder(), // 文字＋底部横线
                    ),
                  ),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _addTask,
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
                  final index = entry.key;
                  final task = entry.value;
                  return Card(
                    key: ValueKey(task),
                    child: ListTile(
                      title: Text(
                        task.name,
                        style: TextStyle(
                          decoration: task.isCompleted ? TextDecoration.lineThrough : null,
                        ),
                      ),
                      subtitle: LinearProgressIndicator(
                        value: task.timeSpent / (25 * 60),
                        backgroundColor: Colors.grey[200],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          task.isCompleted ? Colors.green : themeColor,
                        ),
                      ),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteTask(index),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addTask() {
    if (_taskController.text.isNotEmpty) {
      setState(() {
        _tasks.add(Task(_taskController.text));
        _taskController.clear();
        _saveTasks();
      });
    }
  }

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
        _remainingTime = 25 * 60;
      }
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          if (_remainingTime > 0) {
            _remainingTime--;
            _tasks[_currentTaskIndex].timeSpent++;
            if (_tasks[_currentTaskIndex].timeSpent >= 25 * 60) {
              _completeTask(_currentTaskIndex);
            }
          } else {
            _timer?.cancel();
            _isRunning = false;
            _currentTaskIndex = -1;
          }
          _saveTasks();
        });
      });
    });
  }

  void _resetTimer() {
    setState(() {
      _timer?.cancel();
      _remainingTime = 25 * 60;
      _isRunning = false;
      _currentTaskIndex = -1;
      for (var task in _tasks) {
        if (!task.isCompleted) {
          task.timeSpent = 0;
        }
      }
      _saveTasks();
    });
  }

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

  String _formatTime(int time) {
    int minutes = time ~/ 60;
    int seconds = time % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
