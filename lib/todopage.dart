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

  String? _deleteMode; // 添加这一行，用于跟踪当前哪个分类处于删除模式

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
          SizedBox(height: 10),
          // 显示待办事项列表
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left:10.0, right: 10.0, top: 0.0, bottom: 5.0),
              child: ListView(
                children: themeProvider.todoCategories.map((category) {
                final categoryTodos = todos.where(
                  (todo) => todo['category'] == category['id']
                ).toList();

                if (categoryTodos.isEmpty) return SizedBox.shrink();

                return Padding(
                  padding: EdgeInsets.only(bottom: 5), // 增加分类之间的间距
                  child: Column(
                    children: [
                      SizedBox(
                        height:48,
                        child: ListTile(
                          contentPadding: EdgeInsets.only(left: 15, right: 5, bottom: 0), // 减小底部padding
                          leading: SizedBox(
                            height: 20,
                            child: Row(
                              //调整列的高度
                              
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  category['emoji'],
                                  style: TextStyle(
                                    fontSize: 15,
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
                                icon: Icon(Icons.delete_outline),
                                onPressed: () {
                                  setState(() {
                                    _deleteMode = _deleteMode == category['id'] ? null : category['id'];
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
                        color: category['color'].withOpacity(0.5),
                        height: 0, // 减小高度
                        thickness: 2.0,
                        indent: 10,
                        endIndent: 10,
                      ),
                      SizedBox(height: 6),
                      if (_expandedStates[category['id']] ?? true)
                        _viewModes[category['id']] == ViewMode.horizontal
                            ? SizedBox(
                                height: 120,
                                child: Container(
                                  padding: EdgeInsets.only(left: 0, right: 15),
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
                  ),
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
    final themeColor = Theme.of(context).primaryColor;
    final textColor = Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black;
    final warmColor = ColorScorer.getWarmColor(themeColor, textColor);
    final coldColor = ColorScorer.getColdColor(themeColor, textColor);
    
    // 获取当前分类的视图模式
    final isHorizontal = _viewModes[todo['category']] == ViewMode.horizontal;
    
    return Padding(
      // 根据视图模式调整内边距
      padding: isHorizontal 
          ? EdgeInsets.only(left: 10, right: 10, bottom: 5)
          : EdgeInsets.only(left: 10, right: 10, bottom: 5),
      child: Card(
        // 水平视图时设置固定高度和更小的内边距
        child: Container(
          height: isHorizontal ? 110 : null,
          padding: isHorizontal ? EdgeInsets.all(5) : null,
          child: Stack(
            children: [
              ListTile(
                // 水平视图时调整标题样式
                title: Text(
                  todo['task'],
                  style: TextStyle(
                    fontSize: isHorizontal ? 16 : 16,
                    decoration: todo['completed']
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                    decorationColor: warmColor,
                    decorationThickness: 2.0,
                  ),
                  maxLines: isHorizontal ? 4 : null, // 水平视图限制行数
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Transform.scale(
                      // 水平视图时缩小复选框
                      scale: isHorizontal ? 0.9 : 1.0,
                      child: Checkbox(
                        value: todo['completed'],
                        onChanged: (value) => _toggleComplete(index),
                      ),
                    ),
                  ],
                ),
              ),
              if (_deleteMode == todo['category'])
                Positioned(
                  // 根据视图模式调整删除按钮位置
                  right: isHorizontal ? 2 : 0,
                  bottom: isHorizontal ? 2 : 4,
                  child: IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: coldColor,
                      size: isHorizontal ? 16 : 20,
                    ),
                    padding: isHorizontal ? EdgeInsets.all(4) : EdgeInsets.all(8),
                    constraints: isHorizontal 
                        ? BoxConstraints(minHeight: 32, minWidth: 32)
                        : BoxConstraints(),
                    onPressed: () => _deleteTodo(index),
                  ),
                ),
            ],
          ),
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

  // 添加保存视模式的方法
  void _saveViewModes() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('todoViewModes', jsonEncode(_viewModes.map(
      (key, value) => MapEntry(key, value.toString())
    )));
  }

  // 添加加载视图模式的方法
  void _loadViewModes() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    
    final prefs = await SharedPreferences.getInstance();
    final String? savedViewModes = prefs.getString('todoViewModes');
    if (savedViewModes != null) {
      if (!mounted) return;
      setState(() {
        final Map<String, dynamic> savedMap = jsonDecode(savedViewModes);
        _viewModes = savedMap.map((key, value) => MapEntry(
          key,
          ViewMode.values.firstWhere((e) => e.toString() == value)
        ));
      });
    }
    
    // 为所有类别设置默认视图模式
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
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final String? savedStates = prefs.getString('todoExpandedStates');
    
    if (!mounted) return;
    
    setState(() {
      if (savedStates != null) {
        _expandedStates = Map<String, bool>.from(jsonDecode(savedStates));
      }
      
      // 为所有类别设置默认折叠状态
      for (var category in themeProvider.todoCategories) {
        if (!_expandedStates.containsKey(category['id'])) {
          _expandedStates[category['id']] = true;
        }
      }
    });
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
