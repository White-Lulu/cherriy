import 'package:flutter/material.dart';
import '../utils/color_picker_utils.dart';

class CategoryDialog extends StatefulWidget {
  final String title;
  final String? initialEmoji;
  final String? initialLabel;
  final Color? initialColor;
  final bool isEditing;

  const CategoryDialog({
    super.key,
    required this.title,
    this.initialEmoji,
    this.initialLabel,
    this.initialColor,
    this.isEditing = false,
  });

  @override
  State<CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends State<CategoryDialog> {
  late String emoji;
  late String label;
  late Color color;

  @override
  void initState() {
    super.initState();
    emoji = widget.initialEmoji ?? '';
    label = widget.initialLabel ?? '';
    color = widget.initialColor ?? Colors.blue;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.initialColor == null) {
      color = Theme.of(context).primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title,style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black),),
      titlePadding: EdgeInsets.only(left: 24, top: 24, right: 24, bottom: 0),
      contentPadding: EdgeInsets.only(left: 24, top: 6, right: 24, bottom: 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            decoration: InputDecoration(
              labelText: 'Emoji',
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
                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black,
                  width: 2.0,
                ),
              ),
            ),
            controller: TextEditingController(text: emoji),
            cursorColor: const Color.fromARGB(255, 214, 214, 214),
            onChanged: (value) => emoji = value,
          ),
          SizedBox(height: 7),
          TextField(
            decoration: InputDecoration(
              labelText: '标签',
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
                  color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black,
                  width: 2.0,
                ),
              ),
            ),
            controller: TextEditingController(text: label),
            cursorColor: const Color.fromARGB(255, 214, 214, 214),
            onChanged: (value) => label = value,
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              GestureDetector(
                onTap: () async {
                  final Color? newColor = await ColorPickerUtils.showColorPicker(
                    context,
                    color,
                    onColorChanged: (Color newColor) {
                      setState(() => color = newColor);
                    },
                  );
                  if (newColor != null) {
                    setState(() => color = newColor);
                  }
                },
                child: Container(
                  width: 80,
                  height: 35,
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Center(
                    child: Text(
                      '选择颜色',
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black, fontSize: 15),
                    ),
                  ),
                ),
              ),
              SizedBox(width: 10),
              TextButton(
                child: Text('取消', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black)),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(
                  widget.isEditing ? '保存' : '添加',
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black),
                ),
                onPressed: () {
                  Navigator.of(context).pop({
                    'emoji': emoji,
                    'label': label,
                    'color': color,
                    if (!widget.isEditing) 'id': DateTime.now().toString(),
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
} 