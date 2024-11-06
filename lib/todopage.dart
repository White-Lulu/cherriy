import 'package:flutter/material.dart'; // 导入Flutter材料设计库
import 'package:shared_preferences/shared_preferences.dart'; // 导入本地存储库
import 'dart:convert'; // 导入JSON编解码支持
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
//import 'package:fl_chart/fl_chart.dart';

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
   // 存储代办记录的列表
  List<Map<String, dynamic>> todos = []; // 存储记账记录的列表
  
  String _selectedCategoryId = 'none';

  Map<String, bool> _expandedStates = {};

  Map<String, ViewMode> _viewModes = {};

  // 添加一个监听器变量
  late VoidCallback _listener;

  // 添加一个成员变量来存储 Provider 的引用
  late final ThemeProvider _themeProvider;

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left:6, right: 8.0, top: 12.0, bottom: 8.0),
            child: Row(
              children: [ 
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.category,
                      color: _selectedCategoryId != 'none'
                        ? themeProvider.todoCategories.firstWhere(
                            (category) => category['id'] == _selectedCategoryId
                          )['color']
                        : null,
                    ),
                    onSelected: (String categoryId) {
                      setState(() => _selectedCategoryId = categoryId);
                    },
                    itemBuilder: (context) => themeProvider.todoCategories
                        .map((category) => PopupMenuItem<String>(
                              value: category['id'],
                              child: Row(
                                children: [
                                  Text(category['emoji']),
                                  SizedBox(width: 8),
                                  Text(category['label']),
                                ],
                              ),
                            ))
                        .toList(),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _todoController,
                      decoration: InputDecoration(
                      labelText: '添加待办',
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
                          color: Theme.of(context).primaryColor,
                          width: 2.0,
                        ),
                      ),
                      border: UnderlineInputBorder(), // 文字＋底部横线
                    ),
                    cursorColor:  const Color.fromARGB(255, 214, 214, 214),
                  ),
                  ),
                  IconButton(
                  icon: Icon(Icons.add),
                  onPressed: _addTodo,
                  tooltip: '添加待办',
                ),
            ],
          ),
          ),
          SizedBox(height: 16),
          // 显示待办事项列表
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 2.0, bottom: 5.0),
              child: ListView(
                children: themeProvider.todoCategories.map((category) {
                final categoryTodos = todos.where(
                  (todo) => todo['category'] == category['id']
                ).toList();

                if (categoryTodos.isEmpty) return SizedBox.shrink();

                return Column(
                  children: [
                    SizedBox(
                      height:48,
                      child: ListTile(
                        contentPadding: EdgeInsets.only(left: 5, right: 5, bottom: 0), // 减小底部padding
                        leading: SizedBox(
                          height: 20,
                          child: Row(
                            //调整列的高度
                            
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                category['emoji'],
                                style: TextStyle(
                                  fontSize: 17,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                category['label'],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: category['color'],
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(_viewModes[category['id']] == ViewMode.horizontal
                                  ? Icons.view_module
                                  : Icons.view_list),
                              onPressed: () {
                                setState(() {
                                  _viewModes[category['id']] = _viewModes[category['id']] == ViewMode.horizontal
                                      ? ViewMode.vertical
                                      : ViewMode.horizontal;
                                  _saveViewModes();
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(_expandedStates[category['id']] ?? true
                                  ? Icons.expand_less
                                  : Icons.expand_more),
                              onPressed: () {
                                setState(() {
                                  _expandedStates[category['id']] = !(_expandedStates[category['id']] ?? true);
                                  _saveExpandedStates();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    Divider(
                      color: category['color'].withOpacity(0.9),
                      height: 0, // 减小高度
                      thickness: 1.5,
                      indent: 2,
                      endIndent: 10,
                    ),
                    SizedBox(height: 5),
                    if (_expandedStates[category['id']] ?? true)
                      _viewModes[category['id']] == ViewMode.horizontal
                          ? SizedBox(
                              height: 120,
                              child: Container(
                                padding: EdgeInsets.only(left: 0, right: 12),
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: categoryTodos.length,
                                  itemBuilder: (context, index) {
                                    return SizedBox(
                                      width: 200,
                                      height: 120,
                                      child: _buildTodoCard(categoryTodos[index], 
                                        todos.indexOf(categoryTodos[index])),
                                    );
                                  },
                                ),
                              ),
                            )
                          : Column(
                              children: categoryTodos.map((todo) =>
                                _buildTodoCard(todo, todos.indexOf(todo))).toList(),
                            ),
                  ],
                );
              }).toList(),
            ),
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

  // 添加新的待办事项
  void _addTodo() {
    if (_todoController.text.isNotEmpty) {
      setState(() {
        todos.add({
          'task': _todoController.text,
          'completed': false,
          'category': _selectedCategoryId,
          'timestamp': DateTime.now().millisecondsSinceEpoch, // 添加时间戳
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

  // 添加保存视图模式的方法
  void _saveViewModes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('todoViewModes', jsonEncode(_viewModes.map(
      (key, value) => MapEntry(key, value.toString())
    )));
  }

  // 添加加载视图模式的方法
  void _loadViewModes() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedViewModes = prefs.getString('todoViewModes');
    if (savedViewModes != null) {
      final Map<String, dynamic> viewModesMap = jsonDecode(savedViewModes);
      setState(() {
        _viewModes = viewModesMap.map((key, value) => MapEntry(
          key,
          ViewMode.values.firstWhere((e) => e.toString() == value)
        ));
      });
    }
    // 为所有类别设置默认视图模式
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    for (var category in themeProvider.todoCategories) {
      if (!_viewModes.containsKey(category['id'])) {
        _viewModes[category['id']] = ViewMode.vertical;
      }
    }
  }

  // 修改保存折叠状态的方法
  Future<void> _saveExpandedStates() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('todoExpandedStates', jsonEncode(_expandedStates));
  }

  // 修改加载折叠状态的方法
  Future<void> _loadExpandedStates() async {
    final prefs = await SharedPreferences.getInstance();
    final String? savedStates = prefs.getString('todoExpandedStates');
    if (savedStates != null) {
      setState(() {
        _expandedStates = Map<String, bool>.from(jsonDecode(savedStates));
      });
    }
    // 为所有类别设置默认折叠状态
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    for (var category in themeProvider.todoCategories) {
      if (!_expandedStates.containsKey(category['id'])) {
        _expandedStates[category['id']] = true;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTodos();
    _loadViewModes();
    _loadExpandedStates();
    
    // 在 initState 中获取并保存 Provider 的引用
    _themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    // 定义监听器函数
    _listener = () {
      if (mounted) {
        setState(() {});
      }
    };

    // 添加监听器
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _themeProvider.addListener(_listener);
      }
    });
  }

  @override
  void dispose() {
    _themeProvider.removeListener(_listener);
    _todoController.dispose();
    super.dispose();
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
}
