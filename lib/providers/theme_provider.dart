import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ThemeProvider with ChangeNotifier {
  late ThemeData _themeData;
  String? _backgroundImage;
  Color? lastBackgroundColor;
  
  String? get backgroundImage => _backgroundImage;
  
  void setBackgroundImage(String? imagePath) {
    _backgroundImage = imagePath;
    notifyListeners();
  }
  
  List<Map<String, dynamic>> _categories = [
    {'emoji': '🥗', 'label': '吃饭', 'color': Colors.green},
    {'emoji': '🏠', 'label': '住宿', 'color': Colors.blue},
    {'emoji': '🚗', 'label': '交通', 'color': Colors.red},
    {'emoji': '🛒', 'label': '购物', 'color': Colors.orange},
    {'emoji': '🎉', 'label': '娱乐', 'color': Colors.purple},
  ];
  
  List<Map<String, dynamic>> _todoCategories = [
    {'emoji': '📝', 'label': '无分类', 'color': Colors.grey, 'id': 'none'},
    {'emoji': '📚', 'label': '学习', 'color': Colors.blue, 'id': 'study'},
    {'emoji': '💼', 'label': '工作', 'color': Colors.orange, 'id': 'work'},
  ];
  
  List<Map<String, dynamic>> _diaryEmojis = [
    {'emoji': '😊'},
    {'emoji': '😢'},
    {'emoji': '😡'},
    {'emoji': '😴'},
  ];
  
  ThemeProvider(ThemeData initialTheme) {
    _themeData = initialTheme;
    loadTheme();
    loadCategories();
    loadTodoCategories();
    loadDiaryEmojis();
  }

  ThemeData get themeData => _themeData;
  List<Map<String, dynamic>> get categories => _categories;
  List<Map<String, dynamic>> get todoCategories => _todoCategories;
  List<Map<String, dynamic>> get diaryEmojis => _diaryEmojis;

  Future<void> setTheme(ThemeData theme) async {
    if (theme.scaffoldBackgroundColor != Colors.transparent) {
      lastBackgroundColor = theme.scaffoldBackgroundColor;
    }
    _themeData = theme;
    notifyListeners();
    await _saveTheme();
  }

  Future<void> setCategories(List<Map<String, dynamic>> categories) async {
    _categories = categories;
    notifyListeners();
    await _saveCategories();
  }

  Future<void> setTodoCategories(List<Map<String, dynamic>> categories) async {
    _todoCategories = categories;
    notifyListeners();
    await _saveTodoCategories();
  }

  Future<void> setDiaryEmojis(List<Map<String, dynamic>> emojis) async {
    _diaryEmojis = emojis;
    notifyListeners();
    await _saveDiaryEmojis();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final primaryColor = prefs.getInt('primaryColor') ?? 0xFFC6DCFE;
    final scaffoldBackgroundColor = prefs.getInt('scaffoldBackgroundColor') ?? 0xFFFAFFF4;
    final cardColor = prefs.getInt('cardColor') ?? 0xFFFFFBEF;
    final themeTextColor = prefs.getInt('themeTextColor') ?? 0xFFAD1D1F;

    _themeData = ThemeData(
      primaryColor: Color(primaryColor),
      scaffoldBackgroundColor: Color(scaffoldBackgroundColor),
      cardTheme: CardTheme(
        color: Color(cardColor),
        //圆角
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(primaryColor),
        foregroundColor: Color(themeTextColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(primaryColor),
        selectedItemColor: Color(themeTextColor),
        unselectedItemColor: Color(themeTextColor).withOpacity(0.7),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: Color(themeTextColor)),
        bodyMedium: TextStyle(color: Color(themeTextColor)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Color(primaryColor).withOpacity(0.8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Color(primaryColor).withOpacity(0.8),
        //圆角
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
    notifyListeners();
  }

  

  Future<void> loadCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString('categories');
    if (categoriesJson != null) {
      final List<dynamic> decodedCategories = json.decode(categoriesJson);
      _categories = decodedCategories.map((c) => {
        'emoji': c['emoji'],
        'label': c['label'],
        'color': Color(c['color']),
      }).toList();
      notifyListeners();
    }
  }

  Future<void> loadTodoCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = prefs.getString('todoCategories');
    if (categoriesJson != null) {
      final List<dynamic> decodedCategories = json.decode(categoriesJson);
      _todoCategories = decodedCategories.map((c) => {
        'emoji': c['emoji'],
        'label': c['label'],
        'color': Color(c['color']),
        'id': c['id'],
      }).toList();
      notifyListeners();
    }
  }

  Future<void> loadDiaryEmojis() async {
    final prefs = await SharedPreferences.getInstance();
    final emojisJson = prefs.getString('diaryEmojis');
    if (emojisJson != null) {
      final List<dynamic> decodedEmojis = json.decode(emojisJson);
      _diaryEmojis = decodedEmojis.map((e) => {
        'emoji': e['emoji'],
      }).toList();
      notifyListeners();
    }
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', _themeData.primaryColor.value);
    await prefs.setInt('scaffoldBackgroundColor', _themeData.scaffoldBackgroundColor.value);
    await prefs.setInt('cardColor', _themeData.cardTheme.color?.value ?? Colors.white.value);
    await prefs.setInt('themeTextColor', _themeData.textTheme.bodyMedium?.color?.value ?? Colors.black.value);
  }

  Future<void> _saveCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = json.encode(_categories.map((c) => {
      'emoji': c['emoji'],
      'label': c['label'],
      'color': (c['color'] as Color).value,
    }).toList());
    await prefs.setString('categories', categoriesJson);
  }

  Future<void> _saveTodoCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final categoriesJson = json.encode(_todoCategories.map((c) => {
      'emoji': c['emoji'],
      'label': c['label'],
      'color': (c['color'] as Color).value,
      'id': c['id'],
    }).toList());
    await prefs.setString('todoCategories', categoriesJson);
  }

  Future<void> _saveDiaryEmojis() async {
    final prefs = await SharedPreferences.getInstance();
    final emojisJson = json.encode(_diaryEmojis.map((e) => {
      'emoji': e['emoji'],
    }).toList());
    await prefs.setString('diaryEmojis', emojisJson);
  }

  void removeTemporaryCategories() {
    _categories = categories.where((category) => !category.containsKey('isTemporary')).toList();
    notifyListeners();
  }

  void addCategory(Map<String, dynamic> category) {
    categories.add(category);
    notifyListeners();
  }
}

class WarmColorScorer {
  // 获取颜色的冷暖分数 (0.0最冷 到 1.0最暖)
  static double getWarmScore(Color color) {
    // 使用HSV色彩空间来判断冷暖
    HSVColor hsv = HSVColor.fromColor(color);
    
    // 色相角度：0/360=红，120=绿，240=蓝
    double hue = hsv.hue;
    
    // 暖色区域：红色到黄色 (0-60°)
    // 冷色区域：蓝色到绿色 (180-300°)
    if (hue <= 60 || hue >= 300) {
      return 1.0 - (hue > 300 ? (360 - hue) : hue) / 60.0;
    } else if (hue >= 180 && hue < 300) {
      return 0.0 + (hue - 180) / 120.0;
    } else {
      return 0.5;  // ���渡色
    }
  }

  // 获取颜色的深浅分数 (0.0最深 到 1.0最浅)
  static double getBrightnessScore(Color color) {
    HSVColor hsv = HSVColor.fromColor(color);
    return hsv.value;  // HSV的V值直接表示亮度
  }

  // 获取颜色的总评分
  static double getTotalScore(Color color) {
    double warmScore = getWarmScore(color);
    double brightnessScore = getBrightnessScore(color);
    return warmScore * 0.5 + 1-brightnessScore * 0.5;
  }
}
