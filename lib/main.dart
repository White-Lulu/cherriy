import 'package:flutter/material.dart';  // Flutter框架的核心包，提供了MaterialDesign风格的主题，组件，布局
import 'dart:async'; // 异步编程支持 例如Future,Stream,AsyncCallback
import 'package:provider/provider.dart'; // 提供了一个全局状态管理机制，通过Provider类来向上提供数据以管理状态
import 'providers/theme_provider.dart'; // 自定义的provider，主题管理类
import 'theme_settings_page.dart'; // 导入主题设置页面
import 'accountingpage.dart'; // 导入记账页面
import 'todopage.dart'; // 导入代办页面
import 'diarypage.dart'; // 导入日记页面
import 'time_management_page.dart'; // 导入时间管理页面

// 主函数，应用程序的入口点
void main() {
  runZonedGuarded(() { // 捕获全局异常
    WidgetsFlutterBinding.ensureInitialized(); // 确保Flutter框架正确初始化
    runApp( // 开始运行程序，将一个widget树传递给Flutter引擎挂载到屏幕上，
      ChangeNotifierProvider( // 提供一个可观察的provider，当provider的数据发生变化时，会通知所有依赖它的widget重新构建
        create: (context) => ThemeProvider(ThemeData.light()), // 创建主题提供者 使主题的改变成为响应的，监听的
        child: MyApp(), // 说明主题的改变会导致整个myapp的重构。提供一个widget树，作为应用程序的根widget
      ),
    );
  }, (error, stackTrace) { // 如果出现未处理的异常
    print('错误: $error'); // 打印错误信息
    print('堆栈跟踪: $stackTrace'); // 打印堆栈跟踪信息
  });
}

// MyApp 类，定义应用程序的整体结构和主题
class MyApp extends StatefulWidget {
  @override
  MyAppState createState() => MyAppState(); // 创建MyAppState实例
}

// 响应上面定义的实例，创建MyAppState类，定义应用程序的状态
class MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context); // 获取主题提供者
    return MaterialApp(
      title: 'Cherriy (o^^o)♪', // 设置应用程序的标题
      debugShowCheckedModeBanner: false, // 隐藏调试标志
      theme: themeProvider.themeData, // 设置应用程序的主题
      home: MyHomePage(), // 设置应用程序的主页面
    );
  }
}

// HomePage 类，定义应用序的主页面
class MyHomePage extends StatefulWidget {
  @override
  MyHomePageState createState() => MyHomePageState(); // 创建MyHomePageState实例
}

class MyHomePageState extends State<MyHomePage> {
  // 当前选中的底部导航栏索引
  int _currentIndex = 0;
  // 定义页面列表
  final List<Widget> _pages = [
    AccountingPage(), // 记账页面
    TodoPage(), // 代办页面
    TimeManagementPage(), // 时间管理页面
    DiaryPage(), // 日记页面
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Cherriy (o^^o)♪'), // 设置应用程序的标题
        actions: [
          IconButton(
            icon: Icon(Icons.palette),
            onPressed: () {
              // 导航到主题设置页面
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ThemeSettingsPage()), // 导航到主题设置页面
              );
            },
          ),
        ],
      ),
      body: _pages[_currentIndex], // 显示当前选中的页面
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex, // 当前选中的底部导航栏索引
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed, // 固定底部导航栏
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: '记账'), // 记账页面   
          BottomNavigationBarItem(icon: Icon(Icons.check_box), label: '代办'), // 代办页面
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: '计时'), // 计时页面
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '日记'), // 日记页面
        ],
      ),
    );
  }
}






