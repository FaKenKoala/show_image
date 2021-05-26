import 'package:flutter/material.dart';

class GestureTest3 extends StatefulWidget {
  @override
  _GestureTest3State createState() => _GestureTest3State();
}

class _GestureTest3State extends State<GestureTest3> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: GestureDetector(
          onScaleStart: (details) {
            print('onScaleStart: $details');
          },
          onScaleEnd: (details) {
            print('onScaleEnd: $details');
          },
          child: Container(
            width: 300,
            height: 300,
            color: Colors.green,
          ),
        ),
      ),
    );
  }
}
