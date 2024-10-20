import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

class ThemeSettingsPage extends StatefulWidget {
  @override
  ThemeSettingsPageState createState() => ThemeSettingsPageState();
}

class ThemeSettingsPageState extends State<ThemeSettingsPage> {
  late Color primaryColor;
  late Color scaffoldBackgroundColor;
  late Color cardColor;
  late Color bottomNavBarColor;
  late double cardOpacity;
  late double bottomNavBarOpacity;
  late double elevation;
  late double borderRadius;
  late bool useCard;

  @override
  void initState() {
    super.initState();
    _loadCurrentTheme();
  }

  void _loadCurrentTheme() {
    final theme = Provider.of<ThemeProvider>(context, listen: false).themeData;
    setState(() {
      primaryColor = theme.primaryColor;
      scaffoldBackgroundColor = theme.scaffoldBackgroundColor;
      cardColor = theme.cardColor;
      bottomNavBarColor = theme.bottomNavigationBarTheme.backgroundColor ?? theme.primaryColor;
      cardOpacity = theme.cardColor.opacity;
      bottomNavBarOpacity = theme.bottomNavigationBarTheme.backgroundColor?.opacity ?? 1.0;
      elevation = 4.0;
      borderRadius = 12.0;
      useCard = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('主题设置')),
      body: ListView(
        children: [
          _buildColorPicker('主色调', primaryColor, (color) => setState(() => primaryColor = color)),
          _buildColorPicker('背景色', scaffoldBackgroundColor, (color) => setState(() => scaffoldBackgroundColor = color)),
          _buildColorPicker('卡片颜色', cardColor, (color) => setState(() => cardColor = color)),
          _buildOpacitySlider('卡片透明度', cardOpacity, (value) => setState(() => cardOpacity = value)),
          _buildColorPicker('底部导航栏颜色', bottomNavBarColor, (color) => setState(() => bottomNavBarColor = color)),
          _buildOpacitySlider('底部导航栏透明度', bottomNavBarOpacity, (value) => setState(() => bottomNavBarOpacity = value)),
          // ... 其他设置项
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveTheme,
        child: Icon(Icons.save),
      ),
    );
  }

  Widget _buildColorPicker(String label, Color color, ValueChanged<Color> onColorChanged) {
    return ListTile(
      title: Text(label),
      trailing: GestureDetector(
        onTap: () => _showColorPicker(color, onColorChanged),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.grey),
          ),
        ),
      ),
    );
  }

  Widget _buildOpacitySlider(String label, double opacity, ValueChanged<double> onChanged) {
    return ListTile(
      title: Text(label),
      subtitle: Slider(
        value: opacity,
        min: 0.0,
        max: 1.0,
        onChanged: onChanged,
      ),
    );
  }

  void _showColorPicker(Color initialColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('选择颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: initialColor,
              onColorChanged: onColorChanged,
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('确定'),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _saveTheme() {
    final newTheme = ThemeData(
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      cardTheme: CardTheme(
        color: cardColor.withOpacity(cardOpacity),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bottomNavBarColor.withOpacity(bottomNavBarOpacity),
        selectedItemColor: primaryColor,
        unselectedItemColor: primaryColor.withOpacity(0.6),
      ),
      // 其他主题属性...
    );
    Provider.of<ThemeProvider>(context, listen: false).setTheme(newTheme);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('主题已保存')));
  }
}
