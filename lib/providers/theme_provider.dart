import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  late ThemeData _themeData;
  
  ThemeProvider(ThemeData initialTheme) {
    _themeData = initialTheme;
    loadTheme();
  }

  ThemeData get themeData => _themeData;

  Future<void> setTheme(ThemeData theme) async {
    _themeData = theme;
    notifyListeners();
    await _saveTheme();
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final primaryColor = prefs.getInt('primaryColor') ?? _themeData.primaryColor.value;
    final scaffoldBackgroundColor = prefs.getInt('scaffoldBackgroundColor') ?? _themeData.scaffoldBackgroundColor.value;
    final cardColor = prefs.getInt('cardColor') ?? _themeData.cardTheme.color?.value ?? Colors.white.value;
    final cardOpacity = prefs.getDouble('cardOpacity') ?? 1.0;
    final bottomNavBarColor = prefs.getInt('bottomNavBarColor') ?? _themeData.bottomNavigationBarTheme.backgroundColor?.value ?? primaryColor;
    final bottomNavBarOpacity = prefs.getDouble('bottomNavBarOpacity') ?? 1.0;

    _themeData = ThemeData(
      primaryColor: Color(primaryColor),
      scaffoldBackgroundColor: Color(scaffoldBackgroundColor),
      cardTheme: CardTheme(
        color: Color(cardColor).withOpacity(cardOpacity),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Color(primaryColor),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Color(bottomNavBarColor).withOpacity(bottomNavBarOpacity),
        selectedItemColor: Color(primaryColor),
        unselectedItemColor: Color(primaryColor).withOpacity(0.6),
      ),
      // 其他主题属性...
    );
    notifyListeners();
  }

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', _themeData.primaryColor.value);
    await prefs.setInt('scaffoldBackgroundColor', _themeData.scaffoldBackgroundColor.value);
    await prefs.setInt('cardColor', _themeData.cardTheme.color?.value ?? Colors.white.value);
    await prefs.setDouble('cardOpacity', _themeData.cardTheme.color?.opacity ?? 1.0);
    await prefs.setInt('bottomNavBarColor', _themeData.bottomNavigationBarTheme.backgroundColor?.value ?? _themeData.primaryColor.value);
    await prefs.setDouble('bottomNavBarOpacity', _themeData.bottomNavigationBarTheme.backgroundColor?.opacity ?? 1.0);
  }
}
