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
  String _currentTask = '';
  List<String> _tasks = [];
  final _taskController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // 计时器显示
            Text(
              _formatTime(_remainingTime),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            SizedBox(height: 20),
            // 计时器卡片
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      _currentTask.isEmpty ? '没有正在进行的任务' : '当前任务: $_currentTask',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 16),
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

  void _resetTimer() {
    setState(() {
      _remainingTime = 25 * 60;
      _isRunning = false;
      _timer?.cancel();
    });
  }

  String _formatTime(int time) {
    int minutes = time ~/ 60;
    int seconds = time % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
