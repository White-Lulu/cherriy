import 'package:flutter/material.dart'; // 导入Flutter材料设计库
import 'package:shared_preferences/shared_preferences.dart'; // 导入本地存储库
import 'dart:convert'; // 导入JSON编解码支持

// 待办事项页面
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
    setState(() {
      todos = savedTodos != null
          ? List<Map<String, dynamic>>.from(jsonDecode(savedTodos))
          : [];
    });
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
