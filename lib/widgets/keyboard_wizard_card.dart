// ignore_for_file: deprecated_member_use

import 'package:flutter/cupertino.dart';

class KeyboardWizardCard extends StatefulWidget {
  final void Function(String)? onTextChanged;
  final String? initialText;

  const KeyboardWizardCard({super.key, this.onTextChanged, this.initialText});

  @override
  State<KeyboardWizardCard> createState() => _KeyboardWizardCardState();
}

class _KeyboardWizardCardState extends State<KeyboardWizardCard> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12.0),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.06,
        vertical: 15.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0), // 更濃郁的灰色
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(0.10), // 陰影加深
            spreadRadius: 2,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'keyboard wizard',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.normal,
              color: CupertinoColors.black,
            ),
          ),
          const SizedBox(height: 15),
          CupertinoTextField(
            controller: _controller,
            placeholder: 'keyboard input after scan',
            onChanged: widget.onTextChanged,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: CupertinoColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CupertinoColors.systemGrey4, width: 1),
            ),
            style: const TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}
