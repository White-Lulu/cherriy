import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ThemeProvider with ChangeNotifier {
  late ThemeData _themeData;
  String? _backgroundImage;
  
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
  
  ThemeProvider(ThemeData initialTheme) {
    _themeData = initialTheme;
    loadTheme();
    loadCategories();
  }

  ThemeData get themeData => _themeData;
  List<Map<String, dynamic>> get categories => _categories;

  Future<void> setTheme(ThemeData theme) async {
    _themeData = theme;
    notifyListeners();
    await _saveTheme();
  }

  Future<void> setCategories(List<Map<String, dynamic>> categories) async {
    _categories = categories;
    notifyListeners();
    await _saveCategories();
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
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(primaryColor),
        foregroundColor: Color(themeTextColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(primaryColor),
        selectedItemColor: Color(themeTextColor),
        unselectedItemColor: Color(themeTextColor).withOpacity(0.6),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: Color(themeTextColor)),
        bodyMedium: TextStyle(color: Color(themeTextColor)),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: Color(cardColor),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Color(cardColor),
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

  void removeTemporaryCategories() {
    _categories = categories.where((category) => !category.containsKey('isTemporary')).toList();
    notifyListeners();
  }

  void addCategory(Map<String, dynamic> category) {
    categories.add(category);
    notifyListeners();
  }
}
