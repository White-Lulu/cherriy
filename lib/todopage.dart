import 'package:flutter/material.dart'; // 导入Flutter材料设计库
import 'package:shared_preferences/shared_preferences.dart'; // 导入本地存储库
import 'dart:convert'; // 导入JSON编解码支持

// 添加新的枚举和状态
enum TodoCategory { none, study, work }
enum ViewMode { horizontal, vertical }

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

  TodoCategory _selectedCategory = TodoCategory.none;
  Map<TodoCategory, bool> _expandedStates = {
    TodoCategory.none: true,
    TodoCategory.study: true,
    TodoCategory.work: true,
  };
  Map<TodoCategory, ViewMode> _viewModes = {
    TodoCategory.none: ViewMode.horizontal,
    TodoCategory.study: ViewMode.horizontal,
    TodoCategory.work: ViewMode.horizontal,
  };

  // 添加保存视图模式的方法
  void _saveViewModes() async {
    final prefs = await SharedPreferences.getInstance();
    final viewModesMap = _viewModes.map(
      (key, value) => MapEntry(key.toString(), value.toString())
    );
    await prefs.setString('todoViewModes', jsonEncode(viewModesMap));
  }

  // 添加加载视图模式的方法
  void _loadViewModes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedViewModes = prefs.getString('todoViewModes');
    if (savedViewModes != null) {
      final Map<String, dynamic> viewModesMap = jsonDecode(savedViewModes);
      setState(() {
        _viewModes = viewModesMap.map((key, value) => MapEntry(
          TodoCategory.values.firstWhere((e) => e.toString() == key),
          ViewMode.values.firstWhere((e) => e.toString() == value),
        ));
      });
    }
  }

  // 添加保存折叠状态的方法
  Future<void> _saveExpandedStates() async {
    final prefs = await SharedPreferences.getInstance();
    final expandedStatesMap = _expandedStates.map(
      (key, value) => MapEntry(key.toString(), value)
    );
    await prefs.setString('todoExpandedStates', jsonEncode(expandedStatesMap));
  }

  // 添加加载折叠状态的方法
  Future<void> _loadExpandedStates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedStates = prefs.getString('todoExpandedStates');
    if (savedStates != null) {
      final Map<String, dynamic> statesMap = jsonDecode(savedStates);
      setState(() {
        _expandedStates = statesMap.map((key, value) => MapEntry(
          TodoCategory.values.firstWhere((e) => e.toString() == key),
          value as bool,
        ));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _loadViewModes();  // 加载保存的视图模式
    _loadExpandedStates();  // 加载折叠状态
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
        todos.add({
          'task': _todoController.text,
          'completed': false,
          'category': _selectedCategory.toString(),
        });
        _saveTodos();
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
              child: Row(
                children: [
                  PopupMenuButton<TodoCategory>(
                    icon: Icon(Icons.category),
                    onSelected: (TodoCategory category) {
                      setState(() => _selectedCategory = category);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: TodoCategory.none,
                        child: Text('无分类'),
                      ),
                      PopupMenuItem(
                        value: TodoCategory.study,
                        child: Text('学习'),
                      ),
                      PopupMenuItem(
                        value: TodoCategory.work,
                        child: Text('工作'),
                      ),
                    ],
                  ),
                  Expanded(
                    child: TextField(
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
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          // 显示待办事项列表
          Expanded(
            child: ListView(
              children: TodoCategory.values.map((category) {
                final categoryTodos = todos.where(
                  (todo) => todo['category'] == category.toString()
                ).toList();

                if (categoryTodos.isEmpty) return SizedBox.shrink();

                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Text(
                          category == TodoCategory.none ? '无分类' :
                          category == TodoCategory.study ? '学习' : '工作',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(_viewModes[category] == ViewMode.horizontal
                                  ? Icons.view_module
                                  : Icons.view_list),
                              onPressed: () {
                                setState(() {
                                  _viewModes[category] = _viewModes[category] == ViewMode.horizontal
                                      ? ViewMode.vertical
                                      : ViewMode.horizontal;
                                  _saveViewModes();  // 保存视图模式的更改
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(_expandedStates[category]!
                                  ? Icons.expand_less
                                  : Icons.expand_more),
                              onPressed: () {
                                setState(() {
                                  _expandedStates[category] = !_expandedStates[category]!;
                                  _saveExpandedStates();  // 保存折叠状态
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      if (_expandedStates[category]!)
                        _viewModes[category] == ViewMode.horizontal
                            ? Container(
                                height: 120,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: categoryTodos.length,
                                  itemBuilder: (context, index) {
                                    return Container(
                                      width: 200,
                                      child: _buildTodoCard(categoryTodos[index], 
                                        todos.indexOf(categoryTodos[index])),
                                    );
                                  },
                                ),
                              )
                            : Column(
                                children: categoryTodos.map((todo) =>
                                  _buildTodoCard(todo, todos.indexOf(todo))).toList(),
                              ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // 添加待办事项卡片构建方法
  Widget _buildTodoCard(Map<String, dynamic> todo, int index) {
    return Card(
      child: ListTile(
        title: Text(
          todo['task'],
          style: TextStyle(
            decoration: todo['completed']
                ? TextDecoration.lineThrough
                : TextDecoration.none,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Checkbox(
              value: todo['completed'],
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
  }
}
