import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter/rendering.dart';

class GestureTest extends StatefulWidget {
  @override
  _GestureTestState createState() => _GestureTestState();
}

class _GestureTestState extends State<GestureTest> {
  int index = 0;
  
  final colors = const [Colors.yellow, Colors.green];
  @override
  void initState() {
    super.initState();
    // if (kDebugMode) {
    //   debugPaintPointersEnabled = true;
    // }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Container(
          color: colors[index],
          width: 200,
          height: 200,
          child: GestureDetector(
            onTap: () {
              setState(() {
                index = index * -1 + 1;
              });
            },
            onScaleStart: (details) {
              print('onScaleStart: $details');
            },
            onScaleEnd: (details) {
              print('onScaleEnd: $details');
            },
            onScaleUpdate: (details) {
              // print('onScaleUpdate: $details');
            },
          ),
        ),
      ),
    );
  }
}
