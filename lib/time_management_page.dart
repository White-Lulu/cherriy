import 'package:flutter/material.dart';
import 'dart:async';

class TimeManagementPage extends StatefulWidget {
  @override
  TimeManagementPageState createState() => TimeManagementPageState();
}

class TimeManagementPageState extends State<TimeManagementPage> {
  int _remainingTime = 25 * 60;
  bool _isRunning = false;
  Timer? _timer;
  // String _currentTask = '';
  List<String> _tasks = [];
  final _taskController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    // 获取主题颜色
    final themeColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final cardColor = Theme.of(context).cardTheme.color ?? Colors.white;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 计时器显示和当前任务卡片
            Card(
              color: cardColor, // 使用主题的卡片颜色
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
                    // ... 其他卡片内容保持不变
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _isRunning ? null : _startTimer,
                      child: Text(_isRunning ? '计时中' : '开始计时'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            // 任务输入区域
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _taskController,
                    decoration: InputDecoration(
                      labelText: '添加任务',
                      border: OutlineInputBorder(),
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
            // 任务列表
            Expanded(
              child: ListView.builder(
                itemCount: _tasks.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: ListTile(
                      title: Text(_tasks[index]),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () => _deleteTask(index),
                      ),
                    ),
                  );
                },
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
        _tasks.add(_taskController.text);
        _taskController.clear();
      });
    }
  }

  void _deleteTask(int index) {
    setState(() {
      _tasks.removeAt(index);
    });
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
      _timer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _remainingTime--;
          if (_remainingTime <= 0) {
            _timer?.cancel();
            _isRunning = false;
          }
        });
      });
    });
  }

  String _formatTime(int time) {
    int minutes = time ~/ 60;
    int seconds = time % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
