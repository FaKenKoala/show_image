import 'package:flutter/material.dart';

class RawKeyboardWidget extends StatefulWidget {
  @override
  _RawKeyboardWidgetState createState() => _RawKeyboardWidgetState();
}

class _RawKeyboardWidgetState extends State<RawKeyboardWidget> {
  FocusNode _focusNode = FocusNode();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    FocusScope.of(context).requestFocus(_focusNode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Arrow Key Error'),
      ),
      body: Center(
        child: RawKeyboardListener(
          focusNode: _focusNode,
          onKey: (value) {
            print('keyboard: $value');
          },
          child: Container(
            color: Colors.green,
            width: 200,
            height: 200,
          ),
        ),
      ),
    );
  }
}
