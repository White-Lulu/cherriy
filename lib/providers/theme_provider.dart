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
    final primaryColor = prefs.getInt('primaryColor') ?? 0xFFC6DCFE;
    final scaffoldBackgroundColor = prefs.getInt('scaffoldBackgroundColor') ?? 0xFFFAFFF4; // 新的默认背景色
    final cardColor = prefs.getInt('cardColor') ?? 0xFFFFFBEF; // 新的默认卡片颜色
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

  Future<void> _saveTheme() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('primaryColor', _themeData.primaryColor.value);
    await prefs.setInt('scaffoldBackgroundColor', _themeData.scaffoldBackgroundColor.value);
    await prefs.setInt('cardColor', _themeData.cardTheme.color?.value ?? Colors.white.value);
    await prefs.setInt('themeTextColor', _themeData.textTheme.bodyMedium?.color?.value ?? Colors.black.value);
  }
}
