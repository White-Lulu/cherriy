import 'package:flutter/material.dart';

class EmojiDialog extends StatefulWidget {
  final String initialEmoji;
  final String title;
  
  const EmojiDialog({
    super.key,
    this.initialEmoji = '',
    this.title = '添加新表情',
  });

  @override
  State<EmojiDialog> createState() => _EmojiDialogState();
}

class _EmojiDialogState extends State<EmojiDialog> {
  late String emoji;

  @override
  void initState() {
    super.initState();
    emoji = widget.initialEmoji;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      titlePadding: EdgeInsets.only(
        left: 24, 
        top: 24, 
        right: 24, 
        bottom: 0,
      ),
      contentPadding: EdgeInsets.only(
        left: 24, 
        top: 6, 
        right: 24, 
        bottom: 12,
      ),
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
                  color: Theme.of(context).textTheme.bodyMedium?.color ??
                      Colors.black,
                  width: 2.0,
                ),
              ),
            ),
            controller: TextEditingController(text: emoji),
            cursorColor: const Color.fromARGB(255, 214, 214, 214),
            onChanged: (value) => emoji = value,
          ),
          SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                child: Text(
                  '取消',
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: Text(
                  '添加',
                  style: TextStyle(color: Colors.black, fontSize: 15),
                ),
                onPressed: () {
                  Navigator.of(context).pop({
                    'emoji': emoji,
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