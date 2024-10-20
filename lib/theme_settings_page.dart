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
  late Color themeTextColor;

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
      cardColor = theme.cardTheme.color ?? theme.cardColor;
      themeTextColor = theme.appBarTheme.foregroundColor ?? theme.primaryColor;
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
          _buildColorPicker('主题字体色', themeTextColor, (color) => setState(() => themeTextColor = color)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _saveTheme,
        child: Icon(Icons.save, color: themeTextColor),
        backgroundColor: primaryColor,
      ),
    );
  }

  Widget _buildColorPicker(String label, Color color, ValueChanged<Color> onColorChanged) {
    return ListTile(
      title: Text(label),
      trailing: GestureDetector(
        onTap: () => _showColorPicker(label, color, onColorChanged),
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

  // ignore: unused_element
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

  void _showColorPicker(String label, Color initialColor, ValueChanged<Color> onColorChanged) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        Color selectedColor = initialColor;
        return AlertDialog(
          title: Text('选择颜色'),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                selectedColor = color;
              },
              labelTypes: const [],
              pickerAreaHeightPercent: 0.8,
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('确定'),
              onPressed: () {
                onColorChanged(selectedColor);
                print('$label 颜色已更改为: ${selectedColor.value.toRadixString(16)}');
                Navigator.of(context).pop();
              },
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
        color: cardColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: themeTextColor,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: primaryColor,
        selectedItemColor: themeTextColor,
        unselectedItemColor: themeTextColor.withOpacity(0.6),
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: themeTextColor),
        bodyMedium: TextStyle(color: themeTextColor),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: cardColor,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
      ),
    );
    Provider.of<ThemeProvider>(context, listen: false).setTheme(newTheme);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('主题已保存')));
  }
}
