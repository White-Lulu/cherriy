import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

class ColorPickerUtils {
  static Future<Color?> showColorPicker(
    BuildContext context, 
    Color initialColor,
    {Function(Color)? onColorChanged}
  ) async {
    Color selectedColor = initialColor;
    return showDialog<Color>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          titlePadding: EdgeInsets.all(10),
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          title: Text(''),
          content: SingleChildScrollView(
            child: ColorPicker(
              pickerColor: selectedColor,
              onColorChanged: (color) {
                selectedColor = color;
                onColorChanged?.call(color);
              },
              labelTypes: const [],
              pickerAreaHeightPercent: 0.9,
            ),
          ),
        );
      },
    ).then((value) => value ?? selectedColor);
  }
} 